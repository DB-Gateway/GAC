<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
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
            ->get(route('dashboard', ['tab' => 'overview']))
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
                'total' => 120,
                'answered' => 120,
                'yes' => 119,
                'no' => 1,
                'na' => 0,
                'applicable' => 120,
                'percentage' => 99.17,
                'item_total' => 30,
                'items_answered' => 30,
                'slot_total' => 120,
                'slots_answered' => 120,
                'good' => 119,
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
                    && $summary['timeSlotCount'] === 4
                    && $summary['cards']['total_questions'] === 120
                    && $summary['cards']['answered'] === 120
                    && $summary['cards']['count_yes'] === 119
                    && $summary['cards']['count_no'] === 1
                    && $summary['cards']['item_total'] === 30
                    && count($summary['coverageRows']) === 10
                    && $lighting['total'] === 8
                    && $lighting['score'] === 7
                    && $lighting['percent'] === 87.5
                    && $summary['overallSummaryRow']['total'] === 120
                    && $summary['overallSummaryRow']['score'] === 119
                    && $summary['overallSummaryRow']['percent'] === 99.2;
            })
            ->assertSee('RESTROOM - UTILITY 5S CHECKLIST')
            ->assertSee('Restroom / Utility 5S Checklist Score')
            ->assertSee('4 scheduled checks per item')
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
            ->assertSee('Audit Completion Month')
            ->assertDontSee('Completion Date and Time')
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
                'total' => 120,
                'answered' => 0,
                'yes' => 0,
                'no' => 0,
                'na' => 0,
                'applicable' => 120,
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

    public function test_standards_checklists_display_audit_month_label_and_single_month_in_select_box(): void
    {
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $salesUser = User::factory()->create([
            'name' => 'Sales Lead',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_SALES_MANAGER,
            'account_status' => 'active',
        ]);
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards-sales')->firstOrFail();

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $salesUser->id,
            'submitted_by_user_id' => $salesUser->id,
            'submitted_by_name' => $salesUser->name,
            'submitted_by_email' => $salesUser->email,
            'submitted_by_user_type' => $salesUser->roleCode(),
            'status' => 'submitted',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'audit_date' => '2026-09-15',
            'template_version' => $template->version,
            'context' => ['auditor' => $salesUser->name, 'branch' => 'Pasong Tamo'],
            'template_snapshot' => [
                'slug' => $template->slug,
                'name' => $template->name,
                'settings' => $template->settings,
            ],
            'scores' => [
                'total' => 22,
                'answered' => 22,
                'yes' => 22,
                'no' => 0,
                'na' => 0,
                'applicable' => 22,
                'percentage' => 100,
            ],
            'submitted_at' => \Illuminate\Support\Carbon::parse('2026-09-15 14:00:00'),
        ]);

        $response = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'sales',
            'branch' => 'Pasong Tamo',
            'user_id' => $salesUser->id,
            'submission_id' => $submission->id,
        ]));

        $response->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['isStandardsChecklist'] === true
                    && $summary['date'] === 'September'
                    && $summary['availableSubmissions']->first()->audit_month === 'September'
                    && $summary['completion_date_time'] === 'September 15, 2026, 10:00 PM';
            })
            ->assertSee('Audit Month:')
            ->assertSee('Completion Date and Time')
            ->assertSee('September 15, 2026, 10:00 PM')
            ->assertSee('id="summarySubSelect"', false)
            ->assertSee('name="submission_id"', false)
            ->assertSee('September')
            ->assertDontSee('September to October')
            ->assertDontSee('id="summaryAuditDatePicker"', false);

        $aftersalesUser = User::factory()->create([
            'name' => 'Service Lead',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_AFTERSALES_MANAGER,
            'account_status' => 'active',
        ]);
        $aftersalesTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $aftersalesSub = ChecklistSubmission::create([
            'checklist_template_id' => $aftersalesTemplate->id,
            'user_id' => $aftersalesUser->id,
            'submitted_by_user_id' => $aftersalesUser->id,
            'submitted_by_name' => $aftersalesUser->name,
            'submitted_by_email' => $aftersalesUser->email,
            'submitted_by_user_type' => $aftersalesUser->roleCode(),
            'status' => 'submitted',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'audit_date' => '2026-08-10',
            'template_version' => $aftersalesTemplate->version,
            'context' => ['auditor' => $aftersalesUser->name, 'branch' => 'Pasong Tamo'],
            'template_snapshot' => [
                'slug' => $aftersalesTemplate->slug,
                'name' => $aftersalesTemplate->name,
                'settings' => $aftersalesTemplate->settings,
            ],
            'scores' => [
                'total' => 20,
                'answered' => 20,
                'yes' => 20,
                'no' => 0,
                'na' => 0,
                'applicable' => 20,
                'percentage' => 100,
            ],
            'submitted_at' => Carbon::parse('2026-08-15 14:00:00'),
        ]);

        $aftersalesRes = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'aftersales',
            'score_view' => 'user',
            'branch' => 'Pasong Tamo',
            'user_id' => $aftersalesUser->id,
            'submission_id' => $aftersalesSub->id,
        ]));

        $aftersalesRes->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['isStandardsChecklist'] === true
                    && $summary['date'] === 'August'
                    && $summary['availableSubmissions']->first()->audit_month === 'August'
                    && $summary['completion_date_time'] === 'August 15, 2026, 10:00 PM';
            })
            ->assertSee('Audit Month:')
            ->assertSee('Completion Date and Time')
            ->assertSee('August 15, 2026, 10:00 PM')
            ->assertSee('id="summarySubSelect"', false)
            ->assertSee('August')
            ->assertDontSee('August to September')
            ->assertDontSee('id="summaryAuditDatePicker"', false);

        // Overall Aftersales (Every user aggregate view)
        $overallRes = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'aftersales',
            'score_view' => 'overall',
            'branch' => 'Pasong Tamo',
        ]));

        $overallRes->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['isStandardsChecklist'] === true
                    && $summary['summaryMode'] === 'overall'
                    && $summary['date'] === 'Latest audit per user'
                    && $summary['completion_date_time'] === 'August 15, 2026, 10:00 PM';
            })
            ->assertSee('Audit Month:')
            ->assertSee('Completion Date and Time')
            ->assertSee('id="summaryOverallAuditDate"', false)
            ->assertSee('name="audit_date"', false)
            ->assertDontSee('Audit Scope');

        // Draft submission displays In Progress for completion month
        ChecklistResponse::create([
            'checklist_submission_id' => $aftersalesSub->id,
            'item_key' => 'dos_test_item',
            'status' => 'yes',
            'item_snapshot' => [
                'key' => 'dos_test_item',
                'prompt' => 'Test Item',
                'section' => ['title' => 'General', 'sort_order' => 1],
            ],
        ]);
        $aftersalesSub->update(['status' => 'draft', 'submitted_at' => null]);
        $draftRes = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'aftersales',
            'score_view' => 'user',
            'branch' => 'Pasong Tamo',
            'user_id' => $aftersalesUser->id,
            'submission_id' => $aftersalesSub->id,
        ]));

        $draftRes->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['completion_date_time'] === 'In Progress';
            })
            ->assertSee('Completion Date and Time')
            ->assertSee('In Progress');
    }

    public function test_five_s_checklists_sales_and_service_use_month_and_day_selectors_and_display_completion_time(): void
    {
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $fiveSUser = User::factory()->create([
            'name' => '5S Checker',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_5S_SALES,
            'account_status' => 'active',
        ]);
        $sales5STemplate = ChecklistTemplate::where('slug', 'sales')->firstOrFail();

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $sales5STemplate->id,
            'user_id' => $fiveSUser->id,
            'submitted_by_user_id' => $fiveSUser->id,
            'submitted_by_name' => $fiveSUser->name,
            'submitted_by_email' => $fiveSUser->email,
            'submitted_by_user_type' => $fiveSUser->roleCode(),
            'status' => 'submitted',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'audit_date' => '2026-08-20',
            'template_version' => $sales5STemplate->version,
            'context' => ['auditor' => $fiveSUser->name, 'branch' => 'Pasong Tamo'],
            'template_snapshot' => [
                'slug' => $sales5STemplate->slug,
                'name' => $sales5STemplate->name,
                'settings' => $sales5STemplate->settings,
            ],
            'scores' => [
                'total' => 44,
                'answered' => 44,
                'yes' => 44,
                'no' => 0,
                'na' => 0,
                'applicable' => 44,
                'percentage' => 100,
            ],
            'submitted_at' => now(),
        ]);
        $julySubmission = $submission->replicate();
        $julySubmission->audit_date = '2026-07-18';
        $julySubmission->submitted_at = Carbon::parse('2026-07-18 09:30:00');
        $julySubmission->save();

        $response = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'five_s',
            'five_s_area' => 'sales',
            'branch' => 'Pasong Tamo',
            'audit_date' => '2026-08-20',
        ]));

        $response->assertOk()
            ->assertViewHas('summarySheet', function (array $summary): bool {
                return $summary['isFiveSDailyChecklist'] === true
                    && $summary['selectedFiveSMonth'] === '2026-08'
                    && $summary['selectedFiveSDate'] === '2026-08-20'
                    && $summary['fiveSAuditMonths']->pluck('value')->all() === ['2026-08', '2026-07']
                    && $summary['fiveSAuditDays']->pluck('value')->all() === ['2026-08-20']
                    && $summary['date'] === 'August 20, 2026'
                    && $summary['isFiveSSunday'] === false
                    && $summary['completion_date_time'] !== '—';
            })
            ->assertSee('Month and Year:')
            ->assertSee('Day:')
            ->assertSee('id="summaryFiveSMonth"', false)
            ->assertSee('name="five_s_month"', false)
            ->assertSee('id="summaryFiveSDay"', false)
            ->assertSee('value="2026-08-20"', false)
            ->assertSee('Completion Date and Time')
            ->assertDontSee('id="summaryUtilityTime"', false)
            ->assertDontSee('id="summarySubSelect"', false)
            ->assertDontSee('name="submission_id"', false);

        $julyResponse = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'five_s',
            'five_s_area' => 'sales',
            'branch' => 'Pasong Tamo',
            'five_s_month' => '2026-07',
        ]));

        $julyResponse
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['selectedSubmissionId'] === $julySubmission->id
                && $summary['selectedFiveSMonth'] === '2026-07'
                && $summary['selectedFiveSDate'] === '2026-07-18'
                && $summary['fiveSAuditDays']->pluck('value')->all() === ['2026-07-18']);

        // Service 5S also uses the month-and-day selectors.
        $serviceRes = $this->actingAs($administrator)->get(route('dashboard', [
            'form' => 'five_s',
            'five_s_area' => 'service',
            'branch' => 'Pasong Tamo',
            'audit_date' => '2026-08-20',
        ]));

        $serviceRes->assertOk()
            ->assertViewHas('summarySheet', fn (array $summary): bool => $summary['isFiveSDailyChecklist'] === true
                && $summary['selectedFiveSDate'] === null)
            ->assertSee('Month and Year:')
            ->assertSee('Day:')
            ->assertSee('id="summaryFiveSMonth"', false)
            ->assertSee('id="summaryFiveSDay"', false)
            ->assertDontSee('id="summarySubSelect"', false);
    }
}
