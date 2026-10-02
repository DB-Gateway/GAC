<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Notifications\FindingEscalated;
use App\Notifications\FindingFollowUpRequested;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class DashboardFindingEscalationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-08-29 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_gm_sees_findings_while_branch_bom_only_sees_the_escalation_action(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);

        $parameters = [
            'form' => 'sales',
            'branch' => 'Pasong Tamo',
            'submission_id' => $submission->id,
        ];

        $this->actingAs($gm)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['canViewFindings'] === true
                && $summary['canManageEscalations'] === false)
            ->assertSee('data-summary-modal-target="summaryFindingsModal"', false)
            ->assertDontSee('data-summary-modal-target="summaryEscalationModal"', false)
            ->assertSee('data-request-finding-follow-up', false)
            ->assertSee('Showroom directional sign is damaged.')
            ->assertSee('Sally Checker')
            ->assertSee('View full photo')
            ->assertSee('summary-card-badge-row', false)
            ->assertSee('<strong>1</strong> of 22 answered', false);

        $this->actingAs($bom)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary) use ($finding): bool {
                $row = $summary['nonCompliantFindings']->first();

                return $summary['canManageFindings'] === true
                    && $summary['canViewFindings'] === false
                    && $summary['canManageEscalations'] === true
                    && $summary['cards']['count_no'] === 1
                    && $summary['nonCompliantFindings']->count() === 1
                    && $row['response_id'] === $finding->id
                    && $row['checked_by_name'] === 'Sally Checker'
                    && $row['checker_role'] === 'SALES MANAGER'
                    && $row['finding'] === 'Showroom directional sign is damaged.'
                    && $row['attachment_url'] === Storage::disk('public')->url('checklist-attachments/sign.jpg');
            })
            ->assertDontSee('data-summary-modal-target="summaryFindingsModal"', false)
            ->assertSee('data-summary-modal-target="summaryEscalationModal"', false)
            ->assertSee('data-open-summary-escalation-editor', false)
            ->assertSee('id="summaryEscalationEditorModal"', false)
            ->assertDontSee('data-request-finding-follow-up', false)
            ->assertSee('data-summary-escalation-field="action_plan"', false)
            ->assertSee('data-summary-escalation-field="commitment_date"', false)
            ->assertSee('Commitment Date Planned')
            ->assertSee('Photo Attached')
            ->assertSee('View full photo')
            ->assertDontSee('Workbook Escalation')
            ->assertSee('value="bom"', false)
            ->assertSee('value="ce_central"', false)
            ->assertDontSee('value="marketing_purchasing"', false)
            ->assertDontSee('value="mmpc_training_team"', false)
            ->assertDontSee('value="as_brand_head"', false)
            ->assertSee('summary-card-badge-row', false)
            ->assertSee('<strong>1</strong> of 22 answered', false);
    }

    public function test_follow_up_tab_groups_the_role_specific_gm_and_bom_workflows(): void
    {
        [, $finding] = $this->createNoFinding();
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $parameters = [
            'tab' => 'follow-up',
            'branch' => 'Pasong Tamo',
            'month' => '2026-08',
        ];

        $this->actingAs($gm)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('activeTab', 'follow-up')
            ->assertSee('GM workspace')
            ->assertSee('View Findings')
            ->assertSee('id="findingsRegisterCard"', false)
            ->assertSee('data-request-finding-follow-up', false)
            ->assertSee(route('reports.responses.follow-up', $finding), false)
            ->assertDontSee('data-action="open-escalate"', false)
            ->assertDontSee('id="overrideModal"', false);

        $this->actingAs($bom)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('activeTab', 'follow-up')
            ->assertSee('BOM workspace')
            ->assertSee('Open Escalation Queue')
            ->assertSee('data-action="open-escalate"', false)
            ->assertSee('data-response-id="'.$finding->id.'"', false)
            ->assertSee('id="escalateModal"', false)
            ->assertDontSee('data-request-finding-follow-up', false)
            ->assertDontSee('id="overrideModal"', false);
    }

    public function test_overall_aftersales_audit_date_scope_has_role_specific_finding_actions(): void
    {
        $firstChecker = User::factory()->create([
            'name' => 'Alice Aftersales',
            'user_type' => User::ROLE_AFTERSALES_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $secondChecker = User::factory()->create([
            'name' => 'Carlos CE Service',
            'user_type' => User::ROLE_CE_SERVICE,
            'branch' => 'Pasong Tamo',
        ]);

        [, $firstOlderFinding] = $this->createNoFinding(
            templateSlug: 'dealer-operations-standards',
            auditDate: '2026-08-20',
            checker: $firstChecker,
            findingText: 'Older Aftersales finding.'
        );
        [, $firstNewerFinding] = $this->createNoFinding(
            templateSlug: 'dealer-operations-standards',
            auditDate: '2026-08-21',
            checker: $firstChecker,
            findingText: 'Newer Aftersales finding.'
        );
        [, $secondOlderFinding] = $this->createNoFinding(
            templateSlug: 'dealer-operations-standards',
            auditDate: '2026-08-20',
            checker: $secondChecker,
            findingText: 'CE Service finding.'
        );
        [, $otherBranchFinding] = $this->createNoFinding(
            branch: 'Cebu',
            templateSlug: 'dealer-operations-standards',
            auditDate: '2026-08-22',
            findingText: 'Other branch finding.'
        );

        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $parameters = [
            'form' => 'aftersales',
            'score_view' => 'overall',
            'branch' => 'Pasong Tamo',
        ];

        $this->actingAs($gm)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary) use (
                $firstOlderFinding,
                $firstNewerFinding,
                $secondOlderFinding,
                $otherBranchFinding
            ): bool {
                $findingIds = $summary['nonCompliantFindings']->pluck('response_id');

                return $summary['summaryMode'] === 'overall'
                    && $summary['selectedOverallAuditDate'] === null
                    && $summary['availableOverallAuditDates']->pluck('value')->all() === ['2026-08-21', '2026-08-20']
                    && $summary['aggregateUserCount'] === 2
                    && $summary['cards']['count_no'] === 2
                    && $summary['canManageFindings'] === true
                    && $summary['canViewFindings'] === true
                    && $summary['canManageEscalations'] === false
                    && ! $findingIds->contains($firstOlderFinding->id)
                    && $findingIds->contains($firstNewerFinding->id)
                    && $findingIds->contains($secondOlderFinding->id)
                    && ! $findingIds->contains($otherBranchFinding->id);
            })
            ->assertSee('id="summaryOverallAuditDate"', false)
            ->assertSee('name="audit_date"', false)
            ->assertSee('Latest audit per user')
            ->assertSee('value="2026-08-21"', false)
            ->assertSee('value="2026-08-20"', false)
            ->assertDontSee('value="2026-08-22"', false)
            ->assertDontSee('id="summarySubSelect"', false)
            ->assertSee('data-summary-modal-target="summaryFindingsModal"', false)
            ->assertSee('id="summaryFindingsModal"', false)
            ->assertDontSee('id="summaryEscalationModal"', false);

        $this->actingAs($gm)->get(route('dashboard', array_merge($parameters, [
            'audit_date' => '2026-08-20',
        ])))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary) use (
                $firstOlderFinding,
                $firstNewerFinding,
                $secondOlderFinding
            ): bool {
                $findingIds = $summary['nonCompliantFindings']->pluck('response_id');

                return $summary['selectedOverallAuditDate'] === '2026-08-20'
                    && $summary['date'] === 'August 20, 2026'
                    && $summary['aggregateUserCount'] === 2
                    && $summary['cards']['count_no'] === 2
                    && $findingIds->contains($firstOlderFinding->id)
                    && ! $findingIds->contains($firstNewerFinding->id)
                    && $findingIds->contains($secondOlderFinding->id);
            })
            ->assertSee('user audits on August 20, 2026');

        $this->actingAs($bom)->get(route('dashboard', array_merge($parameters, [
            'audit_date' => '2026-08-21',
        ])))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary) use ($firstNewerFinding): bool {
                return $summary['selectedOverallAuditDate'] === '2026-08-21'
                    && $summary['aggregateUserCount'] === 1
                    && $summary['cards']['count_no'] === 1
                    && $summary['canManageFindings'] === true
                    && $summary['canViewFindings'] === false
                    && $summary['canManageEscalations'] === true
                    && $summary['nonCompliantFindings']->pluck('response_id')->all() === [$firstNewerFinding->id];
            })
            ->assertSee('data-summary-modal-target="summaryEscalationModal"', false)
            ->assertSee('id="summaryEscalationModal"', false)
            ->assertSee('data-summary-escalation-field="action_plan"', false)
            ->assertSee('data-summary-escalation-field="commitment_date"', false)
            ->assertDontSee('id="summaryFindingsModal"', false)
            ->assertDontSee('data-request-finding-follow-up', false);

        $this->actingAs($gm)->get(route('dashboard', array_merge($parameters, [
            'audit_date' => '2026-08-22',
        ])))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['selectedOverallAuditDate'] === null
                && $summary['aggregateUserCount'] === 2);
    }

    public function test_gm_follow_up_notifies_same_branch_bom_and_opens_the_exact_highlighted_finding(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $otherBranchBom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Cebu',
        ]);
        $inactiveBom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
            'account_status' => 'inactive',
        ]);

        $this->actingAs($bom)
            ->postJson(route('reports.responses.follow-up', $finding))
            ->assertForbidden();

        $this->actingAs($gm)
            ->postJson(route('reports.responses.follow-up', $finding))
            ->assertOk()
            ->assertJsonPath('notified_count', 1)
            ->assertJsonPath('already_pending_count', 0)
            ->assertJsonPath('response_id', $finding->id);

        $this->assertCount(1, $bom->notifications()->get());
        $this->assertCount(0, $otherBranchBom->notifications()->get());
        $this->assertCount(0, $inactiveBom->notifications()->get());

        $notification = $bom->notifications()->sole();
        $this->assertSame(FindingFollowUpRequested::class, $notification->type);
        $this->assertSame('finding_follow_up_requested', data_get($notification->data, 'event'));
        $this->assertSame($finding->id, data_get($notification->data, 'response_id'));
        $this->assertSame($submission->id, data_get($notification->data, 'submission_id'));

        $this->actingAs($gm)
            ->postJson(route('reports.responses.follow-up', $finding))
            ->assertOk()
            ->assertJsonPath('notified_count', 0)
            ->assertJsonPath('already_pending_count', 1);
        $this->assertCount(1, $bom->notifications()->get());

        $this->actingAs($bom)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('unreadTaskNotificationCount', 1)
            ->assertSee('Finding follow-up requested')
            ->assertSee('Escalate');

        $redirect = $this->actingAs($bom)
            ->get(route('notifications.view-task', $notification->id))
            ->assertRedirect();
        $location = $redirect->headers->get('Location');
        parse_str((string) parse_url((string) $location, PHP_URL_QUERY), $query);

        $this->assertSame('follow-up', $query['tab'] ?? null);
        $this->assertSame('dealer-operations-standards-sales', $query['template'] ?? null);
        $this->assertSame('2026-08', $query['month'] ?? null);
        $this->assertSame((string) $finding->id, $query['follow_up_response_id'] ?? null);
        $this->assertSame((string) $submission->id, $query['submission_id'] ?? null);
        $this->assertNotNull(data_get($notification->fresh()->data, 'archived_at'));

        $this->actingAs($bom)
            ->get($location)
            ->assertOk()
            ->assertViewHas('activeTab', 'follow-up')
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['followUpResponseId'] === $finding->id)
            ->assertSee('data-follow-up-highlight', false)
            ->assertSee('is-follow-up-highlight', false)
            ->assertSee('data-action="open-escalate"', false)
            ->assertSee('The GM requested follow-up on the highlighted finding.')
            ->assertSee("findingRow{$finding->id}", false);
    }

    public function test_critical_notification_opens_the_selected_no_findings_table(): void
    {
        [$submission] = $this->createNoFinding();
        $manager = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($manager)
            ->get(route('dashboard', [
                'form' => 'sales',
                'branch' => 'Pasong Tamo',
                'submission_id' => $submission->id,
            ]))
            ->assertOk()
            ->assertSee('data-notification-action-target="summaryFindingsModal"', false)
            ->assertSee('View NO findings')
            ->assertSee('summary-card-action summary-card-action-secondary', false);
    }

    public function test_escalation_choices_match_the_sales_and_aftersales_workbooks(): void
    {
        $sales = ChecklistResponse::escalationTargetOptionsFor('dealer-operations-standards-sales');
        $aftersales = ChecklistResponse::escalationTargetOptionsFor('dealer-operations-standards');

        $this->assertSame([
            'bom',
            'ce_central',
            'central_admin',
            'general_manager',
            'property_management',
        ], array_keys($sales));
        $this->assertSame([
            'as_brand_head',
            'as_head',
            'brand_head',
            'ce_central',
            'general_manager',
        ], array_keys($aftersales));
        $this->assertSame('general_manager_ce_central', ChecklistResponse::normalizeEscalationTarget("GENERAL MANAGER\nCE CENTRAL"));
        $this->assertSame('marketing_property_management', ChecklistResponse::normalizeEscalationTarget('MARKETINGPM'));
        $this->assertSame('marketing_purchasing', ChecklistResponse::normalizeEscalationTarget('MARKETING / PURCHASING'));
        $this->assertSame('as_brand_head', ChecklistResponse::normalizeEscalationTarget('AS BRAND HEAD'));
    }

    public function test_non_manager_cannot_see_manager_finding_details_or_escalation_controls(): void
    {
        [$submission] = $this->createNoFinding();
        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($pic)
            ->get(route('dashboard', [
                'form' => 'sales',
                'submission_id' => $submission->id,
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['canManageFindings'] === false
                && $summary['nonCompliantFindings']->isEmpty())
            ->assertDontSee('data-summary-modal-target="summaryFindingsModal"', false)
            ->assertDontSee('data-summary-modal-target="summaryEscalationModal"', false)
            ->assertDontSee('summary-card-badge-meta', false)
            ->assertDontSee('Showroom directional sign is damaged.');
    }

    public function test_bom_can_update_escalation_action_plan_and_commitment_date_without_changing_the_no_result(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), [
            'responses' => [[
                'id' => $finding->id,
                'escalation_target' => 'AS BRAND HEAD',
            ]],
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'The selected escalation recipient is not available for this checklist finding.');

        $result = $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), [
            'responses' => [[
                'id' => $finding->id,
                'escalation_target' => 'CE CENTRAL',
                'action_plan' => '  Replace the damaged sign and verify the installation.  ',
                'commitment_date' => '2026-09-30',
            ]],
        ]);

        $result
            ->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('updated_count', 1)
            ->assertJsonPath('responses.0.id', $finding->id)
            ->assertJsonPath('responses.0.escalation_target', 'ce_central')
            ->assertJsonPath('responses.0.action_plan', 'Replace the damaged sign and verify the installation.')
            ->assertJsonPath('responses.0.commitment_date', '2026-09-30');

        $finding->refresh();
        $this->assertSame('no', $finding->status);
        $this->assertSame('ce_central', $finding->escalation_target);
        $this->assertSame('Replace the damaged sign and verify the installation.', $finding->action_plan);
        $this->assertSame('2026-09-30', $finding->commitment_date?->format('Y-m-d'));
        $this->assertSame('ce_central', data_get($finding->details, 'escalation'));
        $this->assertSame('Brenda BOM', data_get($finding->details, 'escalation_assignment.assigned_by_name'));
        $this->assertSame('Brenda BOM', data_get($finding->details, 'bom_follow_up.updated_by_name'));
        $this->assertFalse($finding->isOverridden());

        $submission->refresh();
        $this->assertSame(1, $submission->scores['no']);
        $this->assertSame(0, $submission->scores['yes']);

        $this->assertDatabaseHas('reports', [
            'type' => 'checklist_response_escalation',
            'generated_by_user_id' => $bom->id,
            'checklist_submission_id' => $submission->id,
        ]);
    }

    public function test_escalation_endpoint_enforces_manager_branch_scope_and_no_status(): void
    {
        [, $finding] = $this->createNoFinding(branch: 'Cebu');
        $otherBranchBom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'branch' => 'Cebu',
        ]);
        $sameBranchBom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Cebu',
        ]);
        $gm = User::factory()->create([
            'user_type' => 'GM',
            'branch' => 'Cebu',
        ]);
        $payload = [
            'responses' => [[
                'id' => $finding->id,
                'escalation_target' => 'IT',
            ]],
        ];

        $this->actingAs($otherBranchBom)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertForbidden();
        $this->actingAs($pic)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertForbidden();
        $this->actingAs($gm)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertForbidden();

        $finding->update(['status' => 'yes']);

        $this->actingAs($sameBranchBom)
            ->patchJson(route('reports.responses.escalations'), $payload)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Only responses currently marked NO can be updated here.');

        $this->assertNull($finding->fresh()->escalation_target);
    }

    public function test_bom_can_use_an_aftersales_escalation_recipient(): void
    {
        [, $finding] = $this->createNoFinding(templateSlug: 'dealer-operations-standards');
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)
            ->patchJson(route('reports.responses.escalations'), [
                'responses' => [[
                    'id' => $finding->id,
                    'escalation_target' => 'AS BRAND HEAD',
                    'commitment_date' => '2026-09-30',
                ]],
            ])
            ->assertOk()
            ->assertJsonPath('responses.0.escalation_target', 'as_brand_head');

        $this->assertSame('no', $finding->fresh()->status);
        $this->assertSame('as_brand_head', $finding->fresh()->escalation_target);
    }

    public function test_bom_can_assign_an_escalation_for_its_own_branch(): void
    {
        [, $finding] = $this->createNoFinding();
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)
            ->patchJson(route('reports.responses.escalations'), [
                'responses' => [[
                    'id' => $finding->id,
                    'escalation_target' => 'CE CENTRAL',
                    'commitment_date' => '2026-09-30',
                ]],
            ])
            ->assertOk()
            ->assertJsonPath('responses.0.escalation_target', 'ce_central');

        $this->assertSame('no', $finding->fresh()->status);
        $this->assertSame('ce_central', $finding->fresh()->escalation_target);
    }

    public function test_bulk_escalation_is_rejected_atomically_when_one_finding_is_outside_bom_scope(): void
    {
        [, $ownFinding] = $this->createNoFinding();
        [, $otherFinding] = $this->createNoFinding(branch: 'Cebu');
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)
            ->patchJson(route('reports.responses.escalations'), [
                'responses' => [
                    ['id' => $ownFinding->id, 'escalation_target' => 'BOM', 'commitment_date' => '2026-09-30'],
                    ['id' => $otherFinding->id, 'escalation_target' => 'BOM', 'commitment_date' => '2026-09-30'],
                ],
            ])
            ->assertForbidden();

        $this->assertNull($ownFinding->fresh()->escalation_target);
        $this->assertNull($otherFinding->fresh()->escalation_target);
        $this->assertDatabaseMissing('reports', ['type' => 'checklist_response_escalation']);
    }

    public function test_complete_escalation_notifies_all_branch_users_and_unchanged_saves_do_not_repeat(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $bom = User::factory()->create(['user_type' => 'BOM', 'branch' => $submission->branch]);
        $otherAuditor = User::factory()->create(['user_type' => User::ROLE_SALES_MANAGER, 'branch' => $submission->branch]);
        $utilityUser = User::factory()->create(['user_type' => User::ROLE_5S_UTILITIES, 'branch' => $submission->branch]);
        $otherBranchUser = User::factory()->create(['user_type' => User::ROLE_5S_UTILITIES, 'branch' => 'Other Branch']);
        $payload = ['responses' => [[
            'id' => $finding->id,
            'escalation_target' => 'BOM',
            'action_plan' => 'Replace the sign.',
            'commitment_date' => '2026-09-30',
        ]]];

        $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), $payload)->assertOk();
        $notification = $submission->user->notifications()->sole();
        $this->assertSame(FindingEscalated::class, $notification->type);
        $this->assertSame('finding_escalated', $notification->data['event']);
        $this->assertSame($submission->user_id, $notification->data['recipient_user_id']);
        $this->assertSame($finding->id, $notification->data['response_id']);
        $this->assertSame('BOM', $notification->data['escalation_target_label']);
        $this->assertSame('2026-09-30', $notification->data['commitment_date']);
        $this->assertSame('Replace the sign.', $notification->data['action_plan']);
        $this->assertSame('dealer-operations-standards-sales', $notification->data['template_slug']);

        // All active users in the same branch receive the escalation notification
        $this->assertSame(1, $otherAuditor->notifications()->count());
        $this->assertSame(1, $utilityUser->notifications()->count());
        $this->assertSame(FindingEscalated::class, $utilityUser->notifications()->sole()->type);
        // Sender and users from other branches do not receive it
        $this->assertSame(0, $bom->notifications()->count());
        $this->assertSame(0, $otherBranchUser->notifications()->count());

        $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), $payload)
            ->assertOk()->assertJsonPath('updated_count', 0);
        $this->assertSame(1, $submission->user->notifications()->count());
        $payload['responses'][0]['action_plan'] = 'Repair the sign and verify.';
        $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), $payload)->assertOk();
        $this->assertSame(2, $submission->user->notifications()->count());
        $this->assertSame(2, $utilityUser->notifications()->count());
    }

    public function test_incomplete_escalations_are_rejected_without_saving_or_notifying(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $bom = User::factory()->create(['user_type' => 'BOM', 'branch' => $submission->branch]);
        foreach (['escalation_target', 'action_plan', 'commitment_date'] as $missing) {
            $update = ['id' => $finding->id, 'escalation_target' => 'BOM', 'action_plan' => 'Fix sign', 'commitment_date' => '2026-09-30'];
            $update[$missing] = '  ';
            $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), ['responses' => [$update]])
                ->assertUnprocessable();
        }
        $this->assertNull($finding->fresh()->escalation_target);
        $this->assertSame(0, $submission->user->notifications()->count());
        $this->assertDatabaseMissing('reports', ['type' => 'checklist_response_escalation']);
    }

    public function test_inactive_or_reassigned_owners_do_not_receive_escalation_details(): void
    {
        [$submission, $finding] = $this->createNoFinding();
        $bom = User::factory()->create(['user_type' => 'BOM', 'branch' => $submission->branch]);
        $submission->user->update(['account_status' => 'inactive']);
        $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), ['responses' => [[
            'id' => $finding->id, 'escalation_target' => 'BOM', 'action_plan' => 'Fix sign', 'commitment_date' => '2026-09-30',
        ]]])->assertOk();
        $this->assertSame(0, $submission->user->notifications()->count());
    }

    /**
     * @return array{0: ChecklistSubmission, 1: ChecklistResponse}
     */
    private function createNoFinding(
        string $branch = 'Pasong Tamo',
        string $templateSlug = 'dealer-operations-standards-sales',
        string $auditDate = '2026-08-20',
        ?User $checker = null,
        string $findingText = 'Showroom directional sign is damaged.'
    ): array {
        $template = ChecklistTemplate::query()
            ->where('slug', $templateSlug)
            ->firstOrFail();
        $checker ??= User::factory()->create([
            'name' => 'Sally Checker',
            'user_type' => $templateSlug === 'dealer-operations-standards'
                ? User::ROLE_AFTERSALES_MANAGER
                : User::ROLE_SALES_MANAGER,
            'branch' => $branch,
        ]);
        $item = $template->items()
            ->with('section')
            ->get()
            ->first(fn (ChecklistItem $candidate): bool => User::roleCodeFor(
                data_get($candidate->metadata, 'checker')
            ) === $checker->roleCode())
            ?? $template->items()->with('section')->firstOrFail();
        $submission = ChecklistSubmission::query()->create([
            'checklist_template_id' => $template->id,
            'user_id' => $checker->id,
            'submitted_by_user_id' => $checker->id,
            'submitted_by_name' => $checker->name,
            'submitted_by_email' => $checker->email,
            'submitted_by_user_type' => $checker->user_type,
            'status' => 'submitted',
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => $auditDate,
            'template_version' => $template->version,
            'context' => ['auditor' => $checker->name, 'branch' => $branch],
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
            'scores' => [
                'total' => 1,
                'answered' => 1,
                'yes' => 0,
                'no' => 1,
                'na' => 0,
                'applicable' => 1,
                'percentage' => 0,
            ],
            'submitted_at' => now(),
        ]);
        $checkerLabel = match ($checker->user_type) {
            User::ROLE_AFTERSALES_MANAGER => 'ASM',
            User::ROLE_CE_SERVICE => 'CE SERVICE',
            User::ROLE_JOB_CONTROLLER => 'JC',
            User::ROLE_PARTS_SUPERVISOR => 'Parts Supervisor',
            User::ROLE_WORKSHOP_SUPERVISOR => 'WORSHOP SUP',
            default => 'SALES MANAGER',
        };
        $metadata = array_merge($item->metadata ?? [], [
            'number' => 1,
            'coverage' => 'Facilities',
            'checker' => $checkerLabel,
            'pic' => 'GM',
            'escalation' => 'MARKETING / PURCHASING',
        ]);
        $finding = ChecklistResponse::query()->create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'finding' => $findingText,
            'action_plan' => 'Replace the damaged sign.',
            'attachment_path' => 'checklist-attachments/sign.jpg',
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'sort_order' => $item->sort_order,
                'metadata' => $metadata,
                'section' => [
                    'title' => $item->section->title,
                    'sort_order' => $item->section->sort_order,
                ],
            ],
        ]);

        return [$submission, $finding];
    }

    public function test_utilities_missed_slot_accumulates_in_cards_grid_and_compiles_in_overview_modals(): void
    {
        $branch = 'Pasong Tamo';
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $items = $template->items()->orderBy('sort_order')->get();
        $this->assertCount(30, $items);

        $utilityUser = User::factory()->create([
            'name' => 'Uriah Utility',
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $branch,
            'account_status' => 'active',
        ]);
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => $branch,
            'account_status' => 'active',
        ]);
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => $branch,
            'account_status' => 'active',
        ]);

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $utilityUser->id,
            'submitted_by_user_id' => $utilityUser->id,
            'submitted_by_name' => $utilityUser->name,
            'submitted_by_user_type' => $utilityUser->user_type,
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => '2026-08-29',
            'template_version' => $template->version,
            'status' => 'submitted',
            'template_snapshot' => [
                'slug' => 'restroom',
                'name' => $template->name,
                'settings' => $template->settings,
            ],
            'submitted_at' => now(),
        ]);

        foreach ($items as $item) {
            ChecklistResponse::create([
                'checklist_submission_id' => $submission->id,
                'checklist_item_id' => $item->id,
                'item_key' => $item->key,
                'status' => null,
                'details' => [
                    'slots' => [
                        '08:00' => 'not_good',
                        '11:00' => 'good',
                    ],
                    'submitted_slots' => ['08:00', '11:00'],
                    'missed_slots' => ['08:00'],
                ],
                'item_snapshot' => [
                    'key' => $item->key,
                    'prompt' => $item->prompt,
                    'sort_order' => $item->sort_order,
                    'section' => [
                        'title' => $item->section?->title ?? 'General',
                        'sort_order' => $item->section?->sort_order ?? 1,
                    ],
                ],
            ]);
        }

        $parameters = [
            'form' => 'restroom',
            'branch' => $branch,
            'submission_id' => $submission->id,
        ];

        // 1. Verify GM view: Card 3 shows 30 NOs, but modal findings has 1 compiled row
        $this->actingAs($gm)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['cards']['count_no'] === 30
                    && $summary['nonCompliantFindings']->count() === 1
                    && $summary['nonCompliantFindings']->first()['is_compiled'] === true
                    && $summary['nonCompliantFindings']->first()['compiled_count'] === 30
                    && count($summary['nonCompliantFindings']->first()['compiled_questions']) === 30
                    && $summary['nonCompliantFindings']->first()['slot'] === '08:00 AM';
            })
            ->assertSee('data-summary-modal-target="summaryFindingsModal"', false)
            ->assertSee('FAILED (30 ITEMS)')
            ->assertSee('View all 30 checklist questions')
            ->assertSee('data-request-finding-follow-up', false);

        // 2. Verify BOM view: Card 3 shows 30 NOs, but escalation modal has 1 compiled row
        $this->actingAs($bom)->get(route('dashboard', $parameters))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['cards']['count_no'] === 30
                    && $summary['nonCompliantFindings']->count() === 1
                    && $summary['nonCompliantFindings']->first()['is_compiled'] === true
                    && $summary['nonCompliantFindings']->first()['compiled_count'] === 30;
            })
            ->assertSee('data-summary-modal-target="summaryEscalationModal"', false)
            ->assertSee('FAILED (30 ITEMS)')
            ->assertSee('View all 30 checklist questions')
            ->assertSee('data-open-summary-escalation-editor', false);

        // 3. Test BOM saves escalation on the compiled finding
        $compiledFinding = $submission->responses()->first();
        $escalateRes = $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), [
            'responses' => [
                [
                    'id' => $compiledFinding->id,
                    'escalation_target' => 'property_management',
                    'action_plan' => 'Immediate sanitization and maintenance.',
                    'commitment_date' => '2026-08-30',
                ],
            ],
        ]);

        $escalateRes->assertOk();
        $this->assertSame(30, $submission->responses()->where('escalation_target', 'property_management')->count());
    }

    public function test_utilities_multiple_missed_slots_accumulate_count_and_compile_by_slot_and_filter_by_time(): void
    {
        $branch = 'Pasong Tamo';
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $items = $template->items()->orderBy('sort_order')->get();
        $this->assertCount(30, $items);

        $utilityUser = User::factory()->create([
            'name' => 'Uriah Utility',
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $branch,
            'account_status' => 'active',
        ]);
        $gm = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => $branch,
            'account_status' => 'active',
        ]);
        $bom = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => $branch,
            'account_status' => 'active',
        ]);

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $utilityUser->id,
            'submitted_by_user_id' => $utilityUser->id,
            'submitted_by_name' => $utilityUser->name,
            'submitted_by_user_type' => $utilityUser->user_type,
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => '2026-08-29',
            'template_version' => $template->version,
            'status' => 'submitted',
            'template_snapshot' => [
                'slug' => 'restroom',
                'name' => $template->name,
                'settings' => $template->settings,
            ],
            'submitted_at' => now(),
        ]);

        // Both 08:00 and 11:00 slots failed -> total 60 NOs
        foreach ($items as $item) {
            ChecklistResponse::create([
                'checklist_submission_id' => $submission->id,
                'checklist_item_id' => $item->id,
                'item_key' => $item->key,
                'status' => null,
                'details' => [
                    'slots' => [
                        '08:00' => 'not_good',
                        '11:00' => 'not_good',
                        '14:00' => 'good',
                    ],
                    'submitted_slots' => ['08:00', '11:00', '14:00'],
                    'missed_slots' => ['08:00', '11:00'],
                ],
                'item_snapshot' => [
                    'key' => $item->key,
                    'prompt' => $item->prompt,
                    'sort_order' => $item->sort_order,
                    'section' => [
                        'title' => $item->section?->title ?? 'General',
                        'sort_order' => $item->section?->sort_order ?? 1,
                    ],
                ],
            ]);
        }

        // 1. All Times: Card 3 displays accumulated 60 NOs, modals display 2 compiled rows
        $this->actingAs($gm)->get(route('dashboard', [
            'form' => 'restroom',
            'branch' => $branch,
            'submission_id' => $submission->id,
        ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['cards']['count_no'] === 60
                    && $summary['nonCompliantFindings']->count() === 2
                    && $summary['nonCompliantFindings']->first()['slot'] === '08:00 AM'
                    && $summary['nonCompliantFindings']->first()['compiled_count'] === 30
                    && $summary['nonCompliantFindings']->last()['slot'] === '11:00 AM'
                    && $summary['nonCompliantFindings']->last()['compiled_count'] === 30;
            });

        // 2. Filtered by utility_time=08:00: Card 3 displays 30 NOs, modals display 1 compiled row
        $this->actingAs($gm)->get(route('dashboard', [
            'form' => 'restroom',
            'branch' => $branch,
            'submission_id' => $submission->id,
            'utility_time' => '08:00',
        ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['cards']['count_no'] === 30
                    && $summary['nonCompliantFindings']->count() === 1
                    && $summary['nonCompliantFindings']->first()['slot'] === '08:00 AM'
                    && $summary['nonCompliantFindings']->first()['compiled_count'] === 30;
            });

        // 3. GM requests follow-up on the 08:00 AM compiled finding
        $compiled08Finding = $submission->responses()->first();
        $followUpRes = $this->actingAs($gm)->postJson(route('reports.responses.follow-up', $compiled08Finding->id));
        $followUpRes->assertOk();

        // BOM receives 1 compiled notification containing all 30 questions
        $bomNotice = $bom->notifications()
            ->where('data->event', 'finding_follow_up_requested')
            ->first();
        $this->assertNotNull($bomNotice);
        $this->assertTrue($bomNotice->data['is_compiled'] ?? false);
        $this->assertCount(30, $bomNotice->data['questions'] ?? []);
    }
}
