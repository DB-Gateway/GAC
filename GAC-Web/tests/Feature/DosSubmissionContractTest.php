<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DosSubmissionContractTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-09-07 09:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_dos_follow_up_fields_are_normalized_persisted_and_idempotent_across_mobile_and_web_shapes(): void
    {
        $manager = $this->user(User::ROLE_SALES_MANAGER, 'Sales Manager');
        $gm = $this->user(User::ROLE_ADMINISTRATOR, 'General Manager');
        $purchasing = $this->user(User::ROLE_PURCHASING, 'Purchasing Team');
        $propertyManagement = $this->user('PURCHASING_MANAGER', 'Property Management');
        $inventory = $this->user('Inventory Team', 'Inventory Team');
        $bom = $this->user(User::ROLE_BRANCH_OPERATIONS_MANAGER, 'Branch Manager');
        $otherBranchBom = User::factory()->create([
            'name' => 'Cebu Branch Manager',
            'branch' => 'Cebu',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'account_status' => 'active',
        ]);
        $otherBranchGm = $this->user(User::ROLE_GENERAL_MANAGER, 'Cebu GM');
        $otherBranchGm->update(['branch' => 'Cebu']);
        $otherBranchPurchasing = $this->user(User::ROLE_PURCHASING, 'Cebu Purchasing');
        $otherBranchPurchasing->update(['branch' => 'Cebu']);
        $otherBranchAdmin = $this->user(User::ROLE_ADMINISTRATOR, 'Cebu Administrator');
        $otherBranchAdmin->update(['branch' => 'Cebu']);
        $inactivePurchasing = $this->user(User::ROLE_PURCHASING, 'Inactive Purchasing', 'inactive');
        $template = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards-sales')
            ->firstOrFail();
        $items = $template->items()->orderBy('id')->get();

        $payload = $this->yesPayload($items);
        $payload['responses'][0] = [
            ...$payload['responses'][0],
            'status' => 'no',
            'finding' => 'Display lighting is not operational.',
            'action_plan' => 'Replace the failed light and verify illumination.',
            'commitment_date' => '2026-09-30T15:45',
            'escalation' => 'Purchasing',
        ];
        $payload['responses'][1] = [
            ...$payload['responses'][1],
            'status' => 'no',
            'finding' => 'Required fixture is unavailable.',
            'action_plan' => 'Property Management will source the fixture.',
            'commitment_date' => '2026-09-30 16:30',
            'escalation_target' => 'Property Management (PM)',
        ];
        $payload['responses'][2] = [
            ...$payload['responses'][2],
            'status' => 'no',
            'finding' => 'Display stock is incomplete.',
            'action_plan' => 'Inventory will replenish the display stock.',
            // A legacy date-only value remains valid and is stored at midnight.
            'commitmentDate' => '2026-10-01',
            'details' => ['escalation' => 'Inventory Team'],
        ];

        Sanctum::actingAs($manager);

        $first = $this->postJson(route('api.checklists.submit', $template), $payload)
            ->assertCreated()
            ->assertJsonPath("submission.responses.{$items[0]->key}.commitment_date", '2026-09-30T15:45:00')
            ->assertJsonPath("submission.responses.{$items[0]->key}.escalation_target", 'purchasing')
            ->assertJsonPath("submission.responses.{$items[0]->key}.details.escalation", 'purchasing')
            ->assertJsonPath("submission.responses.{$items[1]->key}.escalation", 'property_management')
            ->assertJsonPath("submission.responses.{$items[2]->key}.commitment_date", '2026-10-01T00:00:00')
            ->assertJsonPath("submission.responses.{$items[2]->key}.details.escalation", 'inventory');

        $stored = ChecklistResponse::query()
            ->where('checklist_submission_id', $first->json('submission.id'))
            ->where('item_key', $items[0]->key)
            ->firstOrFail();
        $this->assertSame('2026-09-30 15:45:00', $stored->commitment_date?->format('Y-m-d H:i:s'));
        $this->assertSame('purchasing', $stored->escalation_target);
        $this->assertSame('purchasing', data_get($stored->details, 'escalation'));
        $this->assertSame('datetime', Schema::getColumnType('checklist_responses', 'commitment_date'));

        $storedPropertyManagement = ChecklistResponse::query()
            ->where('checklist_submission_id', $first->json('submission.id'))
            ->where('item_key', $items[1]->key)
            ->firstOrFail();
        $this->assertSame('property_management', $storedPropertyManagement->escalation_target);
        $this->assertSame('Property Management (PM)', $storedPropertyManagement->escalationTargetLabel());

        $this->assertCount(1, $gm->notifications()->get());
        $this->assertCount(1, $purchasing->notifications()->get());
        $this->assertSame(User::ROLE_PROPERTY_MANAGEMENT, $propertyManagement->roleCode());
        $this->assertSame('Property Management', $propertyManagement->roleLabel());
        $this->assertContains('Purchasing Manager', User::acceptedRoleValues());
        $this->assertCount(1, $propertyManagement->notifications()->get());
        $this->assertCount(1, $inventory->notifications()->get());
        $this->assertCount(1, $bom->notifications()->get());
        $this->assertCount(0, $otherBranchBom->notifications()->get());
        $this->assertCount(0, $otherBranchGm->notifications()->get());
        $this->assertCount(0, $otherBranchPurchasing->notifications()->get());
        $this->assertCount(0, $otherBranchAdmin->notifications()->get());
        $this->assertCount(0, $inactivePurchasing->notifications()->get());
        $this->assertSame([], $purchasing->allowedChecklistSlugs());

        $notificationData = $gm->notifications()->sole()->data;
        $this->assertSame('dos_audit_submitted', $notificationData['event']);
        $this->assertSame('sales', $notificationData['standards_type']);
        $this->assertSame($manager->id, $notificationData['completed_by_user_id']);
        $this->assertSame(User::ROLE_SALES_MANAGER, $notificationData['completed_by_role']);
        $this->assertSame('Pasong Tamo', $notificationData['completed_by_branch']);
        $this->assertSame(3, $notificationData['finding_count']);
        $this->assertEqualsCanonicalizing(
            ['purchasing', 'property_management', 'inventory'],
            $notificationData['escalation_targets']
        );
        $this->assertSame('2026-09-30T15:45:00', $notificationData['findings'][0]['commitment_date']);

        $this->actingAs($gm)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('unreadTaskNotificationCount', 1)
            ->assertSee('DOS audit submitted');

        $gmNotification = $gm->notifications()->sole();
        $taskDashboardUrl = route('dashboard', [
            'tab' => 'overview',
            'form' => 'sales',
            'branch' => 'Pasong Tamo',
            'user_id' => $manager->id,
            'user_type' => User::ROLE_SALES_MANAGER,
            'submission_id' => $first->json('submission.id'),
        ]);

        $this->actingAs($gm)
            ->get(route('notifications.view-task', $gmNotification->id))
            ->assertRedirect($taskDashboardUrl);

        $this->assertNotNull($gmNotification->fresh()->read_at);

        $this->actingAs($gm)
            ->get($taskDashboardUrl)
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['canSelectUser'] === true
                && (int) $summary['selectedUserId'] === (int) $manager->id
                && $summary['selectedUserType'] === User::ROLE_SALES_MANAGER
                && count($summary['printCoverageOrder']) === 13
                && (int) $summary['selectedSubmissionId'] === (int) $first->json('submission.id'))
            ->assertSee('id="summaryUserSelect"', false)
            ->assertSee('Sales Manager', false)
            ->assertDontSee('Sales Manager &mdash; Sales Manager &mdash; Pasong Tamo', false)
            ->assertSee('data-print-template="sales"', false)
            ->assertSee('data-print-scope="user"', false)
            ->assertSee('data-print-user-id="'.$manager->id.'"', false)
            ->assertSee('SALES STANDARDS COMPLIANCE AUDIT FORM FY2025')
            ->assertSee('Sales Manager:');

        // Equivalent aliases/envelopes and datetime separators identify the same submission.
        $payload['responses'][0]['commitment_date'] = '2026-09-30 15:45';
        unset($payload['responses'][0]['escalation']);
        $payload['responses'][0]['details'] = ['escalation' => 'purchasing'];
        $payload['responses'][1]['commitment_date'] = '2026-09-30T16:30';
        unset($payload['responses'][1]['escalation_target']);
        // The obsolete canonical value remains a read alias and is rewritten.
        $payload['responses'][1]['details'] = ['escalation_target' => 'purchasing_manager'];
        unset($payload['responses'][2]['commitmentDate']);
        $payload['responses'][2]['commitment_date'] = '2026-10-01 00:00';
        $payload['responses'][2]['escalation_target'] = 'inventory';
        unset($payload['responses'][2]['details']);

        Sanctum::actingAs($manager);
        $this->postJson(route('api.checklists.submit', $template), $payload)
            ->assertOk()
            ->assertJsonPath('message', 'This checklist was already submitted.')
            ->assertJsonPath('submission.id', $first->json('submission.id'));

        $this->assertDatabaseCount('checklist_submissions', 1);
        $this->assertDatabaseCount('reports', 1);
        $this->assertDatabaseCount('notifications', 5);
    }

    public function test_invalid_escalation_choice_is_rejected_even_when_nested_in_details(): void
    {
        $manager = $this->user(User::ROLE_SALES_MANAGER, 'Sales Manager');
        $template = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards-sales')
            ->firstOrFail();
        $item = $template->items()->firstOrFail();
        Sanctum::actingAs($manager);

        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-09-07',
            'responses' => [[
                'item_id' => $item->id,
                'status' => 'no',
                'commitment_date' => '2026-09-30T15:45',
                'details' => ['escalation' => 'Unknown Department'],
            ]],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['responses.0.escalation_target']);
    }

    public function test_each_aftersales_operational_checker_notifies_active_gm_and_same_branch_bom(): void
    {
        $this->assertFileExists(public_path('images/mitsubishi-motors-logo.png'));

        $gm = $this->user(User::ROLE_ADMINISTRATOR, 'General Manager');
        $bom = $this->user(User::ROLE_BRANCH_OPERATIONS_MANAGER, 'Branch Manager');
        $template = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards')
            ->firstOrFail();
        $roles = [
            User::ROLE_AFTERSALES_MANAGER,
            User::ROLE_CE_SERVICE,
            User::ROLE_JOB_CONTROLLER,
            User::ROLE_PARTS_SUPERVISOR,
            User::ROLE_WORKSHOP_SUPERVISOR,
        ];
        $checkers = collect();
        $answeredItemKeys = collect();

        foreach ($roles as $index => $role) {
            $checker = $this->user($role, "DOS checker {$index}");
            $items = $template->items()
                ->get()
                ->filter(fn (ChecklistItem $item): bool => User::roleCodeFor(
                    data_get($item->metadata, 'checker')
                ) === $role)
                ->values();
            $this->assertNotEmpty($items, "The seeded aftersales checklist needs items for {$role}.");
            $checkers->push([
                'user' => $checker,
                'item_count' => $items->count(),
            ]);
            $answeredItemKeys = $answeredItemKeys->concat($items->pluck('key'));

            Sanctum::actingAs($checker);
            $this->postJson(route('api.checklists.submit', $template), $this->yesPayload($items))
                ->assertCreated()
                ->assertJsonPath('submission.submitted_by.user_type', $role);
        }

        $this->assertCount(count($roles), $gm->notifications()->get());
        $this->assertCount(count($roles), $bom->notifications()->get());
        $this->assertDatabaseCount('notifications', count($roles) * 2);

        $selectedChecker = $checkers->first();
        $this->actingAs($gm)
            ->get(route('dashboard', [
                'form' => 'aftersales',
                'score_view' => 'user',
                'branch' => 'Pasong Tamo',
                'user_id' => $selectedChecker['user']->id,
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary) use ($selectedChecker): bool {
                return $summary['summaryMode'] === 'user'
                    && (int) $summary['selectedUserId'] === (int) $selectedChecker['user']->id
                    && $summary['cards']['total_questions'] === $selectedChecker['item_count']
                    && $summary['cards']['answered'] === $selectedChecker['item_count']
                    && $summary['cards']['count_yes'] === $selectedChecker['item_count']
                    && count($summary['printCoverageOrder']) === 15
                    && $summary['overallSummaryRow']['total'] === $selectedChecker['item_count']
                    && $summary['overallSummaryRow']['score'] === $selectedChecker['item_count']
                    && $summary['coverageSummaryRow']['total'] === $selectedChecker['item_count'];
            })
            ->assertSee('User Audit Score per Criteria')
            ->assertSee('User Audit Score per Category')
            ->assertSee('data-print-template="aftersales"', false)
            ->assertSee('data-print-scope="user"', false)
            ->assertSee('data-print-user-id="'.$selectedChecker['user']->id.'"', false)
            ->assertSee('AFTERSALES STANDARDS COMPLIANCE AUDIT FORM FY2025')
            ->assertSee('data-print-coverage="Advance Info to Parts Store"', false)
            ->assertSee('data-print-assigned="false"', false)
            ->assertSee('Service Manager:');

        $overallAnswered = $answeredItemKeys->unique()->count();
        $this->actingAs($gm)
            ->get(route('dashboard', [
                'form' => 'aftersales',
                'score_view' => 'overall',
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary) use ($roles, $overallAnswered): bool {
                $beyondRow = collect($summary['overallScores'])->firstWhere('category', 'Beyond');

                return $summary['summaryMode'] === 'overall'
                    && $summary['aggregateUserCount'] === count($roles)
                    && $summary['selectedUserId'] === null
                    && $summary['selectedSubmissionId'] === null
                    && $summary['cards']['total_questions'] === 75
                    && $summary['cards']['answered'] === $overallAnswered
                    && $summary['cards']['count_yes'] === $overallAnswered
                    && $summary['overallSummaryRow']['total'] === 71
                    && $summary['overallSummaryRow']['score'] === 71
                    && $summary['overallSummaryRow']['uses_beyond_bonus'] === true
                    && $summary['overallSummaryRow']['beyond_total'] === 4
                    && $summary['overallSummaryRow']['beyond_score'] === 4
                    && $summary['overallSummaryRow']['beyond_bonus_applied'] === 0
                    && $beyondRow['target'] === null
                    && ! in_array($beyondRow['rating'], ['PASS', 'FAIL'], true);
            })
            ->assertSee('Overall Aftersales Score per Criteria')
            ->assertSee('Overall Aftersales Score per Category')
            ->assertSee('No rating &middot; Bonus credit', false)
            ->assertSee('Overall Aftersales')
            ->assertSee('data-print-scope="overall"', false)
            ->assertSee('data-print-overall-percent="100.0"', false)
            ->assertSee('workbook-rating-cell is-neutral', false)
            ->assertSee('workbook-column-chart', false)
            ->assertSee('workbook-radar-chart', false);

        $baseItemKeys = $template->items()
            ->get()
            ->filter(fn (ChecklistItem $item): bool => strcasecmp(
                trim((string) data_get($item->metadata, 'level', data_get($item->metadata, 'category', ''))),
                'Beyond'
            ) !== 0)
            ->pluck('key')
            ->take(16);

        $this->assertSame(16, ChecklistResponse::query()
            ->whereIn('item_key', $baseItemKeys)
            ->update(['status' => 'no']));

        $this->actingAs($gm)
            ->get(route('dashboard', [
                'form' => 'aftersales',
                'score_view' => 'overall',
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['overallSummaryRow']['base_score'] === 55
                    && $summary['overallSummaryRow']['base_percent'] === 77.5
                    && $summary['overallSummaryRow']['beyond_score'] === 4
                    && $summary['overallSummaryRow']['beyond_bonus_applied'] === 4
                    && $summary['overallSummaryRow']['beyond_bonus_percentage_points'] === 5.6
                    && $summary['overallSummaryRow']['score'] === 59
                    && $summary['overallSummaryRow']['percent'] === 83.1
                    && $summary['overallSummaryRow']['rating'] === 'PASS';
            })
            ->assertSee('data-print-scope="overall"', false)
            ->assertSee('data-print-overall-percent="83.1"', false);
    }

    /**
     * @param  iterable<int, ChecklistItem>  $items
     * @return array{date: string, responses: list<array{item_id: int, status: string}>}
     */
    private function yesPayload(iterable $items): array
    {
        return [
            'date' => '2026-09-07',
            'responses' => collect($items)
                ->map(fn (ChecklistItem $item): array => [
                    'item_id' => $item->id,
                    'status' => 'yes',
                ])
                ->values()
                ->all(),
        ];
    }

    private function user(string $role, string $name, string $status = 'active'): User
    {
        return User::factory()->create([
            'name' => $name,
            'branch' => 'Pasong Tamo',
            'user_type' => $role,
            'account_status' => $status,
        ]);
    }
}
