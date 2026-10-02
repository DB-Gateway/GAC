<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-08-29 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_non_manager_report_page_and_csv_are_limited_to_the_assigned_branch(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $ownSubmission = $this->createSubmission($template, 'Pasong Tamo');
        $otherSubmission = $this->createSubmission($template, 'Cebu');
        $user = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => 'PIC',
            'account_status' => 'active',
        ]);

        $page = $this->actingAs($user)->get(route('reports.index'));

        $page
            ->assertOk()
            ->assertViewHas('history', function ($history) use ($ownSubmission, $otherSubmission): bool {
                return $history->pluck('id')->all() === [$ownSubmission->id]
                    && ! $history->pluck('id')->contains($otherSubmission->id);
            })
            ->assertViewHas('branchOptions', fn ($branches): bool => $branches->values()->all() === ['Pasong Tamo'])
            ->assertViewHas('reportScope', fn (array $scope): bool => $scope === [
                'type' => 'assigned_branch',
                'branch' => 'Pasong Tamo',
            ]);

        $export = $this->get(route('reports.export'));
        $export->assertOk();
        $csv = $export->streamedContent();

        $this->assertStringContainsString('Pasong Tamo', $csv);
        $this->assertStringNotContainsString('Cebu', $csv);

        $metadata = Report::where('type', 'csv_export')->latest('id')->firstOrFail()->data_snapshot;
        $this->assertSame([$ownSubmission->id], $metadata['submission_ids']);
        $this->assertSame('assigned_branch', $metadata['access_scope']['type']);
        $this->assertSame('Pasong Tamo', $metadata['access_scope']['branch']);
    }

    public function test_administrator_role_variants_can_report_across_all_branches(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $first = $this->createSubmission($template, 'Pasong Tamo');
        $second = $this->createSubmission($template, 'Cebu');

        foreach (['ADMIN', 'Compliance Administrator'] as $role) {
            $manager = User::factory()->create([
                'branch' => 'Pasong Tamo',
                'user_type' => $role,
                'account_status' => 'active',
            ]);

            $response = $this->actingAs($manager)->get(route('reports.index'));

            $response
                ->assertOk()
                ->assertViewHas('history', function ($history) use ($first, $second): bool {
                    return $history->pluck('id')->sort()->values()->all() === [$first->id, $second->id];
                })
                ->assertViewHas('branchOptions', function ($branches): bool {
                    return $branches->values()->all() === ['Cebu', 'Pasong Tamo'];
                })
                ->assertViewHas('reportScope', fn (array $scope): bool => $scope === [
                    'type' => 'all_branches',
                    'branch' => null,
                ]);
        }
    }

    public function test_general_manager_role_variants_are_limited_to_their_assigned_branch(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $ownSubmission = $this->createSubmission($template, 'Pasong Tamo');
        $otherSubmission = $this->createSubmission($template, 'Cebu');

        foreach (['GM', 'General Manager'] as $role) {
            $manager = User::factory()->create([
                'branch' => 'Pasong Tamo',
                'user_type' => $role,
                'account_status' => 'active',
            ]);

            $this->actingAs($manager)
                ->get(route('reports.index'))
                ->assertOk()
                ->assertViewHas('history', function ($history) use ($ownSubmission, $otherSubmission): bool {
                    return $history->pluck('id')->all() === [$ownSubmission->id]
                        && ! $history->pluck('id')->contains($otherSubmission->id);
                })
                ->assertViewHas('branchOptions', fn ($branches): bool => $branches->values()->all() === ['Pasong Tamo'])
                ->assertViewHas('reportScope', fn (array $scope): bool => $scope === [
                    'type' => 'assigned_branch',
                    'branch' => 'Pasong Tamo',
                ]);
        }
    }

    public function test_archived_template_snapshot_can_be_selected_filtered_and_exported(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $submission = $this->createSubmission($template, 'Pasong Tamo');
        $administrator = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $template->delete();
        $this->assertNull($submission->fresh()->checklist_template_id);

        $page = $this->actingAs($administrator)->get(route('reports.index', [
            'template' => 'gateway-5s',
        ]));

        $page
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->pluck('id')->all() === [$submission->id])
            ->assertViewHas('templateOptions', function ($options): bool {
                return $options->contains(fn (array $option): bool => $option === [
                    'slug' => 'gateway-5s',
                    'name' => 'Gateway Sales and Service 5S Checklist',
                    'is_archived' => true,
                ]);
            })
            ->assertSee('Gateway Sales and Service 5S Checklist (Archived)');

        $export = $this->get(route('reports.export', [
            'template' => 'gateway-5s',
        ]));
        $export->assertOk();
        $this->assertStringContainsString('Gateway Sales and Service 5S Checklist', $export->streamedContent());

        $exportReport = Report::where('type', 'csv_export')->latest('id')->firstOrFail();
        $this->assertNull($exportReport->checklist_template_id);
        $this->assertSame([$submission->id], $exportReport->data_snapshot['submission_ids']);
        $this->assertSame('gateway-5s', $exportReport->filters['template']);
    }

    public function test_empty_drafts_are_excluded_but_saved_drafts_remain_reportable(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $emptyDraft = $this->createSubmission($template, 'Empty Draft Branch', 'draft', false);
        $blankDraft = $this->createSubmission($template, 'Blank Response Branch', 'draft', false);
        $item = $template->items()->firstOrFail();
        ChecklistResponse::create([
            'checklist_submission_id' => $blankDraft->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => null,
            'details' => [],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);
        $savedDraft = $this->createSubmission($template, 'Saved Draft Branch', 'draft');
        $administrator = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $page = $this->actingAs($administrator)->get(route('reports.index', ['status' => 'draft']));

        $page
            ->assertOk()
            ->assertViewHas('history', function ($history) use ($blankDraft, $emptyDraft, $savedDraft): bool {
                return $history->pluck('id')->all() === [$savedDraft->id]
                    && ! $history->pluck('id')->contains($emptyDraft->id)
                    && ! $history->pluck('id')->contains($blankDraft->id);
            })
            ->assertViewHas('summary', fn (array $summary): bool => $summary['audit_count'] === 1
                && $summary['draft_count'] === 1)
            ->assertViewHas('branchOptions', fn ($branches): bool => $branches->values()->all() === ['Saved Draft Branch']);
    }

    public function test_employee_activity_can_be_filtered_by_user_type_and_submission_recency(): void
    {
        $this->travelTo('2026-08-29 12:00:00');

        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $administrator = User::factory()->create([
            'name' => 'Report Manager',
            'user_type' => User::ROLE_ADMINISTRATOR,
        ]);
        $pic = User::factory()->create([
            'name' => 'Paolo PIC',
            'email' => 'paolo.pic@example.com',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
        ]);
        $bom = User::factory()->create([
            'name' => 'Bianca BOM',
            'email' => 'bianca.bom@example.com',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
        ]);

        $oldPicSubmission = $this->createSubmission(
            $template,
            'Pasong Tamo',
            submitter: $pic,
            submittedAt: now()->subDays(40),
            auditDate: '2026-08-29'
        );
        $recentBomSubmission = $this->createSubmission(
            $template,
            'Pasong Tamo',
            submitter: $bom,
            submittedAt: now()->subHours(6),
            auditDate: '2026-08-20'
        );
        $newestPicSubmission = $this->createSubmission(
            $template,
            'Pasong Tamo',
            submitter: $pic,
            submittedAt: now()->subHour(),
            auditDate: '2026-08-01'
        );

        $page = $this->actingAs($administrator)->get(route('reports.index'));

        $page
            ->assertOk()
            ->assertViewHas('history', function ($history) use ($newestPicSubmission, $recentBomSubmission, $oldPicSubmission): bool {
                $newest = $history->first();

                return $history->pluck('id')->all() === [
                    $newestPicSubmission->id,
                    $recentBomSubmission->id,
                    $oldPicSubmission->id,
                ]
                    && $newest['submitter_name'] === 'Paolo PIC'
                    && $newest['submitter_email'] === 'paolo.pic@example.com'
                    && $newest['submitter_role_code'] === User::ROLE_PERSON_IN_CHARGE
                    && $newest['submitter_role_label'] === 'Person In Charge';
            })
            ->assertSee('Employee Checklist Activity')
            ->assertSee('Paolo PIC')
            ->assertSee('paolo.pic@example.com')
            ->assertSee('29 Aug 2026')
            ->assertSee('07:00 PM');

        $picOnly = $this->get(route('reports.index', ['user_type' => User::ROLE_PERSON_IN_CHARGE]));
        $picOnly
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->pluck('id')->all() === [
                $newestPicSubmission->id,
                $oldPicSubmission->id,
            ]);

        $recentOnly = $this->get(route('reports.index', ['recency' => '7d']));
        $recentOnly
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->pluck('id')->all() === [
                $newestPicSubmission->id,
                $recentBomSubmission->id,
            ]);

        $export = $this->get(route('reports.export', [
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'recency' => '7d',
        ]));
        $export->assertOk();
        $csv = $export->streamedContent();

        $this->assertStringContainsString('"Submitted By","Submitter Email","User Type"', $csv);
        $this->assertStringContainsString('Paolo PIC', $csv);
        $this->assertStringContainsString('Person In Charge', $csv);
        $this->assertStringContainsString('2026-08-29 19:00:00 +08:00', $csv);
        $this->assertStringNotContainsString('Bianca BOM', $csv);

        $metadata = Report::where('type', 'csv_export')->latest('id')->firstOrFail();
        $this->assertSame(User::ROLE_PERSON_IN_CHARGE, $metadata->filters['user_type']);
        $this->assertSame('7d', $metadata->filters['recency']);
    }

    public function test_submitter_snapshot_keeps_employee_identity_after_the_account_is_deleted(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $submitter = User::factory()->create([
            'name' => 'Former Employee',
            'email' => 'former.employee@example.com',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
        ]);
        $submission = $this->createSubmission($template, 'Pasong Tamo', submitter: $submitter);
        $administrator = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);

        $submitter->delete();

        $this->actingAs($administrator)
            ->get(route('reports.index', ['user_type' => User::ROLE_PERSON_IN_CHARGE]))
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->pluck('id')->all() === [$submission->id]
                && $history->first()['submitter_name'] === 'Former Employee'
                && $history->first()['submitter_email'] === 'former.employee@example.com')
            ->assertSee('Former Employee')
            ->assertSee('former.employee@example.com');
    }

    public function test_reports_page_defaults_to_current_month_and_filters_strictly_by_month(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'branch' => 'Pasong Tamo',
        ]);

        // setUp travels to 2026-08-29, so current month is 2026-08
        $augustSubmission = $this->createSubmission($template, 'Pasong Tamo', auditDate: '2026-08-15');
        $julySubmission = $this->createSubmission($template, 'Pasong Tamo', auditDate: '2026-07-20');

        // Default view (no month parameter) defaults to current month (2026-08)
        $response = $this->actingAs($admin)->get(route('reports.index'));
        $response
            ->assertOk()
            ->assertViewHas('selectedMonth', '2026-08')
            ->assertViewHas('currentMonth', '2026-08')
            ->assertViewHas('history', function ($history) use ($augustSubmission, $julySubmission): bool {
                return $history->pluck('id')->contains($augustSubmission->id)
                    && ! $history->pluck('id')->contains($julySubmission->id);
            });

        // Filter for July 2026 explicitly
        $julyResponse = $this->actingAs($admin)->get(route('reports.index', ['month' => '2026-07']));
        $julyResponse
            ->assertOk()
            ->assertViewHas('selectedMonth', '2026-07')
            ->assertViewHas('history', function ($history) use ($augustSubmission, $julySubmission): bool {
                return $history->pluck('id')->contains($julySubmission->id)
                    && ! $history->pluck('id')->contains($augustSubmission->id);
            });
    }

    public function test_checklist_no_answers_show_bom_escalation_target_and_commitment_date_time(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $bomUser = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $submission = $this->createSubmission($template, 'Pasong Tamo', withResponse: false, auditDate: '2026-08-10');
        $item = $template->items()->firstOrFail();

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'details' => [
                'finding' => 'Defective pressure gauge on water pump',
                'action_plan' => 'Contact authorized service center for calibration',
                'escalation_target' => 'Purchasing Manager',
                'commitment_date' => '2026-08-25 14:30:00',
            ],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        $page = $this->actingAs($bomUser)->get(route('reports.index'));

        $page
            ->assertOk()
            ->assertViewHas('findings', function ($findings) use ($response): bool {
                $finding = $findings->firstWhere('response_id', $response->id);

                return $finding !== null
                    && $finding['status'] === 'no'
                    && str_contains($finding['escalation_target_label'], 'Property Management')
                    && str_contains($finding['commitment_date_formatted'], '25 Aug 2026, 02:30 PM')
                    && $finding['can_override'] === true;
            })
            ->assertSee('Defective pressure gauge on water pump')
            ->assertSee('Property Management')
            ->assertSee('25 Aug 2026, 02:30 PM')
            ->assertSee('Override / Edit');
    }

    public function test_general_manager_cannot_override_no_answers_outside_their_branch(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $gmUser = User::factory()->create([
            'name' => 'George GM',
            'user_type' => 'GM',
            'branch' => 'Pasong Tamo',
        ]);

        $submission = $this->createSubmission($template, 'Cebu', withResponse: false, auditDate: '2026-08-12');
        $item = $template->items()->firstOrFail();

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'details' => [
                'finding' => 'Dirty technician uniforms',
                'action_plan' => 'Launder uniforms',
                'escalation_target' => 'General Manager',
                'commitment_date' => '2026-08-20 09:00:00',
            ],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        $submission->update([
            'scores' => [
                'total' => 1,
                'answered' => 1,
                'yes' => 0,
                'no' => 1,
                'na' => 0,
                'applicable' => 1,
                'percentage' => 0,
            ],
        ]);

        $overridePayload = [
            'status' => 'yes',
            'escalation_target' => 'General Manager',
            'commitment_date' => '2026-08-22 11:00:00',
            'finding' => 'New uniforms provided and verified',
            'action_plan' => 'Uniform replacement completed',
            'override_reason' => 'Approved replacement during GM inspection walk',
        ];

        $patchResponse = $this->actingAs($gmUser)->patchJson(
            route('reports.responses.override', $response),
            $overridePayload
        );

        $patchResponse->assertForbidden();

        $response->refresh();
        $this->assertSame('no', $response->status);
        $this->assertFalse($response->isOverridden());

        $submission->refresh();
        $this->assertSame(0, $submission->scores['yes']);
        $this->assertSame(1, $submission->scores['no']);
        $this->assertEquals(0.0, (float) $submission->scores['percentage']);

        $this->assertDatabaseMissing('reports', [
            'type' => 'checklist_response_override',
            'generated_by_user_id' => $gmUser->id,
            'checklist_submission_id' => $submission->id,
        ]);
    }

    public function test_bom_can_override_no_answers_in_their_own_branch(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $bomUser = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $submission = $this->createSubmission($template, 'Pasong Tamo', withResponse: false, auditDate: '2026-08-14');
        $item = $template->items()->firstOrFail();

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'details' => [
                'finding' => 'Signage bulb burned out',
                'action_plan' => 'Replace bulb',
                'escalation_target' => 'Purchasing',
                'commitment_date' => '2026-08-18 17:00:00',
            ],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        $submission->update([
            'scores' => [
                'total' => 1,
                'answered' => 1,
                'yes' => 0,
                'no' => 1,
                'na' => 0,
                'applicable' => 1,
                'percentage' => 0,
            ],
        ]);

        $patchResponse = $this->actingAs($bomUser)->patchJson(
            route('reports.responses.override', $response),
            [
                'status' => 'yes',
                'escalation_target' => 'Purchasing',
                'commitment_date' => '2026-08-18 18:00:00',
                'finding' => 'Signage bulb replaced by maintenance staff',
                'action_plan' => 'Done and working',
                'override_reason' => 'Maintenance verified bulb fixed this afternoon',
            ]
        );

        $patchResponse->assertOk();
        $response->refresh();
        $this->assertSame('yes', $response->status);
        $this->assertTrue($response->isOverridden());
        $this->assertSame('Brenda BOM', $response->overrideDetails()['overridden_by_name']);
    }

    public function test_bom_cannot_override_no_answers_in_other_branches(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $bomUser = User::factory()->create([
            'name' => 'Brenda BOM',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        // Submission belongs to Cebu, BOM is Pasong Tamo
        $submission = $this->createSubmission($template, 'Cebu', withResponse: false, auditDate: '2026-08-14');
        $item = $template->items()->firstOrFail();

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'details' => [
                'finding' => 'Oil stain in bay 3',
                'action_plan' => 'Clean bay 3',
                'escalation_target' => 'Inventory',
                'commitment_date' => '2026-08-18 17:00:00',
            ],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        $patchResponse = $this->actingAs($bomUser)->patchJson(
            route('reports.responses.override', $response),
            [
                'status' => 'yes',
                'override_reason' => 'Unauthorized attempt by other branch BOM',
            ]
        );

        $patchResponse->assertForbidden();
        $response->refresh();
        $this->assertSame('no', $response->status);
        $this->assertFalse($response->isOverridden());
    }

    public function test_non_bom_and_non_gm_users_cannot_override_checklist_responses(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $picUser = User::factory()->create([
            'name' => 'Peter PIC',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'branch' => 'Pasong Tamo',
        ]);

        $submission = $this->createSubmission($template, 'Pasong Tamo', withResponse: false, auditDate: '2026-08-14');
        $item = $template->items()->firstOrFail();

        $response = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'details' => [
                'finding' => 'Trash bin overflow',
                'action_plan' => 'Empty bin',
            ],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        $patchResponse = $this->actingAs($picUser)->patchJson(
            route('reports.responses.override', $response),
            [
                'status' => 'yes',
                'override_reason' => 'PIC trying to override own response',
            ]
        );

        $patchResponse->assertForbidden();
        $response->refresh();
        $this->assertSame('no', $response->status);
        $this->assertFalse($response->isOverridden());
    }

    public function test_checklist_findings_can_be_exported_to_csv_with_escalation_and_commitment_date_time(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'branch' => 'Pasong Tamo',
        ]);

        $submission = $this->createSubmission($template, 'Pasong Tamo', withResponse: false, auditDate: '2026-08-15');
        $item = $template->items()->firstOrFail();

        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'no',
            'details' => [
                'finding' => 'Emergency exit light disconnected',
                'action_plan' => 'Electrician will wire it back up',
                'escalation_target' => 'Purchasing Manager',
                'commitment_date' => '2026-08-20 16:30:00',
            ],
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        $exportResponse = $this->actingAs($admin)->get(route('reports.export.findings', ['month' => '2026-08']));

        $exportResponse->assertOk();
        $csvContent = $exportResponse->streamedContent();

        $this->assertStringContainsString('BOM Suggested Escalation', $csvContent);
        $this->assertStringContainsString('Commitment Date & Time', $csvContent);
        $this->assertStringContainsString('Emergency exit light disconnected', $csvContent);
        $this->assertStringContainsString('Property Management', $csvContent);
        $this->assertStringContainsString('20 Aug 2026, 04:30 PM', $csvContent);
    }

    private function createSubmission(
        ChecklistTemplate $template,
        string $branch,
        string $status = 'submitted',
        bool $withResponse = true,
        ?User $submitter = null,
        \DateTimeInterface|string|null $submittedAt = null,
        string $auditDate = '2026-08-22'
    ): ChecklistSubmission {
        $submittedAt ??= now();
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $submitter?->id,
            'submitted_by_user_id' => $status === 'submitted' ? $submitter?->id : null,
            'submitted_by_name' => $status === 'submitted' ? $submitter?->name : null,
            'submitted_by_email' => $status === 'submitted' ? $submitter?->email : null,
            'submitted_by_user_type' => $status === 'submitted' ? $submitter?->roleCode() : null,
            'status' => $status,
            'branch' => $branch,
            'scope_key' => hash('sha256', strtolower($branch)),
            'audit_date' => $auditDate,
            'template_version' => $template->version,
            'template_snapshot' => [
                'slug' => $template->slug,
                'name' => $template->name,
            ],
            'scores' => [
                'total' => 1,
                'answered' => $withResponse ? 1 : 0,
                'yes' => $withResponse ? 1 : 0,
                'no' => 0,
                'na' => 0,
                'applicable' => $withResponse ? 1 : 0,
                'percentage' => $withResponse ? 100 : 0,
            ],
            'submitted_at' => $status === 'submitted' ? $submittedAt : null,
        ]);

        if (! $withResponse) {
            return $submission;
        }

        $item = $template->items()->firstOrFail();
        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => ['title' => $item->section->title],
            ],
        ]);

        return $submission;
    }
}
