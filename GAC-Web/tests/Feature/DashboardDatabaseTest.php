<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardDatabaseTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-08-29 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_dashboard_metrics_are_calculated_from_visible_database_submissions(): void
    {
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $ownAuditor = User::factory()->create(['branch' => 'Pasong Tamo', 'user_type' => 'PIC']);
        $otherAuditor = User::factory()->create(['branch' => 'Cebu', 'user_type' => 'PIC']);
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $pic = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'account_status' => 'active',
        ]);

        $this->createSubmission($template, $ownAuditor, 'Pasong Tamo', 'submitted', 9, 1, 'no');
        $this->createSubmission($template, $otherAuditor, 'Cebu', 'submitted', 8, 2, 'yes');
        $this->createSubmission($template, $ownAuditor, 'Pasong Tamo', 'draft', 1, 0, 'yes');

        $adminPage = $this->actingAs($administrator)->get(route('dashboard'));

        $adminPage
            ->assertOk()
            ->assertViewIs('dashboard')
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['overall_compliance'] === 85.0
                && $summary['dos_completed'] === 2
                && $summary['pending_audits'] === 1
                && $summary['critical_findings'] === 1)
            ->assertViewHas('monthlyTrend', fn ($trend): bool => $trend->last()['score'] === 85.0
                && $trend->last()['count'] === 2)
            ->assertViewHas('branchRankings', fn ($rankings): bool => $rankings->pluck('branch')->all() === ['Pasong Tamo', 'Cebu'])
            ->assertViewHas('notifications', fn ($notifications): bool => $notifications->count() === 2)
            ->assertDontSee('id="notificationsBadge"', false)
            ->assertDontSee('Juan Dela Cruz')
            ->assertDontSee('Sucat');

        $branchPage = $this->actingAs($pic)->get(route('dashboard'));

        $branchPage
            ->assertOk()
            ->assertViewHas('dashboardScope', 'Pasong Tamo')
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['overall_compliance'] === 90.0
                && $summary['dos_completed'] === 1
                && $summary['pending_audits'] === 1
                && $summary['critical_findings'] === 1)
            ->assertViewHas('branchRankings', fn ($rankings): bool => $rankings->count() === 1
                && $rankings->first()['branch'] === 'Pasong Tamo')
            ->assertDontSee('Cebu');
    }

    public function test_empty_database_displays_real_empty_dashboard_state(): void
    {
        $administrator = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $this->actingAs($administrator)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['overall_compliance'] === null
                && $summary['dos_completed'] === 0
                && $summary['pending_audits'] === 0
                && $summary['critical_findings'] === 0)
            ->assertViewHas('dosCategories', fn ($categories): bool => $categories->isEmpty())
            ->assertViewHas('recentActivities', fn ($activities): bool => $activities->isEmpty())
            ->assertViewHas('branchRankings', fn ($rankings): bool => $rankings->isEmpty())
            ->assertViewHas('notifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertSee('NO RECORDED AUDIT')
            ->assertSee('No notifications currently');
    }

    public function test_five_s_summary_tab_switches_between_the_sales_service_and_restroom_workbook_sheets(): void
    {
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $this->actingAs($administrator)
            ->get(route('dashboard', [
                'form' => 'five_s',
                'five_s_area' => 'sales',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['activeForm'] === 'five_s'
                && $summary['activeSlug'] === 'sales'
                && $summary['fiveSArea'] === 'sales'
                && $summary['cards']['total_questions'] === 44
                && count($summary['coverageRows']) === 8)
            ->assertSee('class="summary-pill-btn active"', false)
            ->assertSee('5S Checklist')
            ->assertSee('Sales 5S Checklist Score')
            ->assertSee('Compliance per 5S Area')
            ->assertSee('data-print-template="five_s"', false);

        $this->actingAs($administrator)
            ->get(route('dashboard', [
                'form' => 'five_s',
                'five_s_area' => 'service',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['activeForm'] === 'five_s'
                && $summary['activeSlug'] === 'service'
                && $summary['fiveSArea'] === 'service'
                && $summary['cards']['total_questions'] === 33
                && count($summary['coverageRows']) === 6)
            ->assertSee('SERVICE 5S CHECKLIST')
            ->assertSee('Service 5S Checklist Score')
            ->assertSee('name="five_s_area" value="service"', false);

        $utility = User::factory()->create([
            'name' => 'Restroom Utility',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_5S_UTILITIES,
            'account_status' => 'active',
        ]);
        $restroom = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $slotKeys = collect($restroom->settings['time_slots'])->pluck('key');
        $restroomItems = $restroom->items()->with('section')->get();
        $restroomSubmission = ChecklistSubmission::create([
            'checklist_template_id' => $restroom->id,
            'user_id' => $utility->id,
            'submitted_by_user_id' => $utility->id,
            'submitted_by_name' => $utility->name,
            'submitted_by_email' => $utility->email,
            'submitted_by_user_type' => $utility->roleCode(),
            'status' => 'submitted',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'audit_date' => '2026-08-29',
            'template_version' => $restroom->version,
            'context' => ['auditor' => $utility->name, 'branch' => 'Pasong Tamo'],
            'template_snapshot' => [
                'slug' => $restroom->slug,
                'name' => $restroom->name,
                'settings' => $restroom->settings,
            ],
            'scores' => [
                'total' => 270,
                'answered' => 270,
                'yes' => 269,
                'no' => 1,
                'na' => 0,
                'applicable' => 270,
                'percentage' => 99.63,
                'item_total' => 30,
                'items_answered' => 30,
                'slot_total' => 270,
                'slots_answered' => 270,
                'good' => 269,
                'bad' => 1,
                'completion_percentage' => 100,
            ],
            'submitted_at' => now(),
        ]);

        foreach ($restroomItems as $index => $item) {
            $slots = $slotKeys->mapWithKeys(fn (string $slot): array => [$slot => 'good'])->all();
            if ($index === 0) {
                $slots['08:00'] = 'not_good';
            }

            ChecklistResponse::create([
                'checklist_submission_id' => $restroomSubmission->id,
                'checklist_item_id' => $item->id,
                'item_key' => $item->key,
                'status' => $index === 0 ? 'no' : 'yes',
                'remark' => $index === 0 ? 'Lighting needs attention.' : null,
                'details' => ['slots' => $slots],
                'item_snapshot' => [
                    'key' => $item->key,
                    'prompt' => $item->prompt,
                    'metadata' => $item->metadata,
                    'section' => [
                        'title' => $item->section->title,
                        'sort_order' => $item->section->sort_order,
                    ],
                ],
            ]);
        }

        $this->actingAs($administrator)
            ->get(route('dashboard', [
                'form' => 'five_s',
                'five_s_area' => 'restroom',
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                $lighting = collect($summary['coverageRows'])->firstWhere('coverage', 'Lighting');

                return $summary['activeForm'] === 'five_s'
                    && $summary['activeSlug'] === 'restroom'
                    && $summary['fiveSArea'] === 'restroom'
                    && $summary['isTimeSlotChecklist'] === true
                    && $summary['timeSlotCount'] === 9
                    && $summary['cards']['total_questions'] === 270
                    && $summary['cards']['answered'] === 270
                    && $summary['cards']['count_yes'] === 269
                    && $summary['cards']['count_no'] === 1
                    && $summary['cards']['item_total'] === 30
                    && count($summary['coverageRows']) === 10
                    && $lighting['total'] === 18
                    && $lighting['score'] === 17
                    && $lighting['percent'] === 94.4
                    && $summary['overallSummaryRow']['total'] === 270
                    && $summary['overallSummaryRow']['score'] === 269
                    && $summary['overallSummaryRow']['percent'] === 99.6;
            })
            ->assertSee('RESTROOM - UTILITY 5S CHECKLIST')
            ->assertSee('Restroom / Utility 5S Checklist Score')
            ->assertSee('9 scheduled checks per item')
            ->assertSee('name="five_s_area" value="restroom"', false)
            ->assertSee('Month and Year:')
            ->assertSee('name="utility_time"', false)
            ->assertDontSee('name="submission_id"', false);

        $this->actingAs($administrator)
            ->get(route('dashboard', [
                'form' => 'five_s',
                'five_s_area' => 'restroom',
                'branch' => 'Pasong Tamo',
                'utility_time' => '08:00',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                $lighting = collect($summary['coverageRows'])->firstWhere('coverage', 'Lighting');

                return $summary['selectedUtilityTime'] === '08:00'
                    && $summary['selectedUtilityTimeLabel'] === '8 AM'
                    && $summary['activeTimeSlotCount'] === 1
                    && $summary['cards']['total_questions'] === 30
                    && $summary['cards']['answered'] === 30
                    && $summary['cards']['count_yes'] === 29
                    && $summary['cards']['count_no'] === 1
                    && $lighting['total'] === 2
                    && $lighting['score'] === 1
                    && $lighting['percent'] === 50.0
                    && $summary['overallSummaryRow']['total'] === 30
                    && $summary['overallSummaryRow']['score'] === 29
                    && $summary['overallSummaryRow']['percent'] === 96.7;
            })
            ->assertSee('8 AM check per item')
            ->assertSee('Showing the 8 AM inspection for each restroom item.');
    }

    public function test_utility_summary_can_select_a_month_and_day_without_an_audit_selector(): void
    {
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $utility = User::factory()->create([
            'name' => 'Restroom Utility',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_5S_UTILITIES,
            'account_status' => 'active',
        ]);
        $restroom = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $latestAugust = $this->createDatedRestroomSubmission($restroom, $utility, '2026-08-29');
        $earlyAugust = $this->createDatedRestroomSubmission($restroom, $utility, '2026-08-05');
        $july = $this->createDatedRestroomSubmission($restroom, $utility, '2026-07-31');

        $defaultPage = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'five_s',
            'five_s_area' => 'restroom',
            'branch' => 'Pasong Tamo',
        ]));

        $defaultPage
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['isUtilityChecklist'] === true
                && $summary['selectedSubmissionId'] === $latestAugust->id
                && $summary['selectedUtilityMonth'] === '2026-08'
                && $summary['selectedUtilityDay'] === '2026-08-29'
                && $summary['utilityAuditMonths']->pluck('value')->all() === ['2026-08', '2026-07']
                && $summary['utilityAuditDays']->pluck('value')->all() === ['2026-08-29', '2026-08-05'])
            ->assertSee('name="utility_month"', false)
            ->assertSee('name="utility_day"', false)
            ->assertSee('name="utility_time"', false)
            ->assertSee('Month and Year:')
            ->assertDontSee('name="submission_id"', false);

        $this->actingAs($administrator)
            ->get(route('dashboard', [
                'form' => 'five_s',
                'five_s_area' => 'restroom',
                'branch' => 'Pasong Tamo',
                'utility_month' => '2026-07',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['selectedSubmissionId'] === $july->id
                && $summary['selectedUtilityMonth'] === '2026-07'
                && $summary['selectedUtilityDay'] === '2026-07-31'
                && $summary['utilityAuditDays']->pluck('value')->all() === ['2026-07-31']);

        $this->actingAs($administrator)
            ->get(route('dashboard', [
                'form' => 'five_s',
                'five_s_area' => 'restroom',
                'branch' => 'Pasong Tamo',
                'utility_month' => '2026-08',
                'utility_day' => '2026-08-05',
            ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['selectedSubmissionId'] === $earlyAugust->id
                && $summary['selectedUtilityMonth'] === '2026-08'
                && $summary['selectedUtilityDay'] === '2026-08-05');
    }

    private function createDatedRestroomSubmission(
        ChecklistTemplate $template,
        User $utility,
        string $auditDate
    ): ChecklistSubmission {
        return ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $utility->id,
            'submitted_by_user_id' => $utility->id,
            'submitted_by_name' => $utility->name,
            'submitted_by_email' => $utility->email,
            'submitted_by_user_type' => $utility->roleCode(),
            'status' => 'submitted',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'audit_date' => $auditDate,
            'template_version' => $template->version,
            'context' => ['auditor' => $utility->name, 'branch' => 'Pasong Tamo'],
            'template_snapshot' => [
                'slug' => $template->slug,
                'name' => $template->name,
                'settings' => $template->settings,
            ],
            'scores' => [
                'total' => 270,
                'answered' => 0,
                'yes' => 0,
                'no' => 0,
                'na' => 0,
                'applicable' => 270,
                'percentage' => 0,
            ],
            'submitted_at' => now(),
        ]);
    }

    private function createSubmission(
        ChecklistTemplate $template,
        User $user,
        string $branch,
        string $status,
        int $yes,
        int $no,
        string $responseStatus
    ): ChecklistSubmission {
        $answered = $yes + $no;
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'submitted_by_user_id' => $status === 'submitted' ? $user->id : null,
            'status' => $status,
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => '2026-08-15',
            'template_version' => $template->version,
            'context' => ['auditor' => $user->name, 'branch' => $branch],
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
            'scores' => [
                'total' => $answered,
                'answered' => $answered,
                'yes' => $yes,
                'no' => $no,
                'na' => 0,
                'applicable' => $answered,
                'percentage' => round(($yes / $answered) * 100, 2),
            ],
            'submitted_at' => $status === 'submitted' ? now() : null,
        ]);
        $item = $template->items()->with('section')->firstOrFail();

        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => $responseStatus,
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => [
                    'title' => $item->section->title,
                    'sort_order' => $item->section->sort_order,
                ],
            ],
        ]);

        return $submission;
    }
}
