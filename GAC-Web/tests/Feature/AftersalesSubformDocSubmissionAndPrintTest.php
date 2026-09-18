<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Services\AftersalesSubformDocService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use ReflectionClass;
use Tests\TestCase;

class AftersalesSubformDocSubmissionAndPrintTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        $this->seedDosTemplates();
    }

    private function seedDosTemplates(): void
    {
        $migration = require database_path('migrations/2026_09_07_001100_create_dos_subform_and_documentation_templates.php');
        $ref = new ReflectionClass($migration);
        $seedSubform = $ref->getMethod('seedSubformTemplate');
        $seedSubform->setAccessible(true);
        $seedSubform->invoke($migration);

        $seedDoc = $ref->getMethod('seedDocumentationTemplate');
        $seedDoc->setAccessible(true);
        $seedDoc->invoke($migration);
    }

    private function administrator(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
    }

    public function test_aftersales_subform_doc_service_extracts_and_computes_results(): void
    {
        $admin = $this->administrator();
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $subformTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-subform')->firstOrFail();
        $docTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->firstOrFail();

        // Create DOS submission with embedded subform answers and documentation samples
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $admin->id,
            'submitted_by_user_id' => $admin->id,
            'submitted_by_name' => $admin->name,
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'template_version' => 1,
            'template_snapshot' => ['slug' => 'dealer-operations-standards', 'name' => 'Dealer Operations Standards'],
            'audit_date' => now()->toDateString(),
            'status' => 'submitted',
        ]);

        $item23 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-23')
            ?? $dosTemplate->sections->flatMap->items->first();
        $item61 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-61')
            ?? $dosTemplate->sections->flatMap->items->last();

        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item23->id,
            'item_key' => $item23->key,
            'status' => 'yes',
            'item_snapshot' => ['prompt' => $item23->prompt, 'metadata' => $item23->metadata],
            'details' => [
                'subform_answers' => [
                    'subform-sr-1' => 'yes',
                    'subform-sr-2' => 'yes',
                    'subform-sr-3' => 'no',
                ],
            ],
        ]);

        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item61->id,
            'item_key' => $item61->key,
            'status' => 'yes',
            'item_snapshot' => ['prompt' => $item61->prompt, 'metadata' => $item61->metadata],
            'details' => [
                'documentation_samples' => [
                    [
                        'ro_number' => 'RO-1001',
                        'job_type' => '10,000 km PMS',
                        'answers' => ['doc-rc-1' => 'yes', 'doc-rc-2' => 'yes'],
                    ],
                    [
                        'ro_number' => 'RO-1002',
                        'job_type' => '20,000 km PMS',
                        'answers' => ['doc-rc-1' => 'yes', 'doc-rc-2' => 'no'],
                    ],
                    [
                        'ro_number' => 'RO-1003',
                        'job_type' => 'General Repair',
                        'answers' => ['doc-rc-1' => 'yes', 'doc-rc-2' => 'yes'],
                    ],
                ],
            ],
        ]);

        $service = app(AftersalesSubformDocService::class);
        $results = $service->getSubformAndDocumentationResults('Pasong Tamo', now()->toDateString(), $submission->id);

        $this->assertTrue($results['has_submissions']);
        $this->assertTrue($results['has_subform']);
        $this->assertTrue($results['has_documentation']);
        $this->assertSame('Existing Submissions: Subform & Documentation', $results['button_label']);
        $this->assertSame('SUBFORM & DOC SUBMITTED', $results['badge_label']);

        // Check subform section and items
        $this->assertGreaterThan(0, $results['subform']['answered_count']);
        $this->assertCount(5, $results['subform']['sections']);

        // Check documentation samples and matrix
        $this->assertCount(3, $results['documentation']['samples']);
        $this->assertSame('RO-1001', $results['documentation']['samples'][0]['ro_number']);
        $this->assertCount(17, $results['documentation']['items_matrix']);
    }

    public function test_aftersales_dashboard_renders_button_modal_and_print_options(): void
    {
        $admin = $this->administrator();
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();

        // Create DOS submission with subform details
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $admin->id,
            'submitted_by_user_id' => $admin->id,
            'submitted_by_name' => 'John Auditor',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'template_version' => 1,
            'template_snapshot' => ['slug' => 'dealer-operations-standards', 'name' => 'Dealer Operations Standards'],
            'audit_date' => now()->toDateString(),
            'status' => 'submitted',
        ]);

        $item23 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-23')
            ?? $dosTemplate->sections->flatMap->items->first();

        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item23->id,
            'item_key' => $item23->key,
            'status' => 'yes',
            'item_snapshot' => ['prompt' => $item23->prompt, 'metadata' => $item23->metadata],
            'details' => [
                'subform_answers' => [
                    'subform-sr-1' => 'yes',
                ],
            ],
        ]);

        $response = $this->actingAs($admin)
            ->get('/dashboard?form=aftersales&branch=Pasong+Tamo&submission_id='.$submission->id);

        $response->assertOk();

        // 1. Assert Existing Submission Button is displayed
        $response->assertSee('id="btnOpenSubformDocModal"', false);
        $response->assertSee('Existing Submission', false);

        // 2. Assert Modal markup is present
        $response->assertSee('id="subformDocModal"', false);
        $response->assertSee('Aftersales Subform &amp; Documentation Audit Results', false);
        $response->assertSee('id="tabBtnSubform"', false);
        $response->assertSee('id="tabBtnDoc"', false);

        // 3. Assert Print Options Modal is present
        $response->assertSee('id="printOptionsModal"', false);
        $response->assertSee('Select Audit Sheets to Print', false);
        $response->assertSee('Aftersales Results Only', false);
        $response->assertSee('Subform &amp; Documentation Only', false);
        $response->assertSee('Both (Aftersales Results + Subform &amp; Documentation)', false);

        // 4. Assert Print Sheet for Subform & Documentation is present
        $response->assertSee('workbook-print-subform-doc');
        $response->assertSee('AFTERSALES STANDARDS - SUBFORM &amp; DOCUMENTATION COMPLIANCE AUDIT FY2025', false);
    }

    public function test_checklist_page_renders_subform_doc_button_when_submissions_exist(): void
    {
        $admin = $this->administrator();
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();

        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $admin->id,
            'submitted_by_user_id' => $admin->id,
            'submitted_by_name' => $admin->name,
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'template_version' => 1,
            'template_snapshot' => ['slug' => 'dealer-operations-standards', 'name' => 'Dealer Operations Standards'],
            'audit_date' => now()->toDateString(),
            'status' => 'submitted',
        ]);

        $item23 = $dosTemplate->sections->flatMap->items->first();
        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item23->id,
            'item_key' => $item23->key,
            'status' => 'yes',
            'item_snapshot' => ['prompt' => $item23->prompt, 'metadata' => $item23->metadata],
            'details' => [
                'subform_answers' => ['subform-sr-1' => 'yes'],
            ],
        ]);

        $response = $this->actingAs($admin)
            ->get('/checklists?checklist=dealer-operations-standards&branch=Pasong+Tamo&date='.now()->toDateString());

        $response->assertOk();
        $response->assertSee('id="checklistOpenSubformDocModalBtn"', false);
    }

    public function test_going_to_aftersales_shows_overall_aftersales_first_by_default(): void
    {
        $bom = User::factory()->create([
            'name' => 'Test BOM',
            'email' => 'bom_test_default@example.com',
            'user_type' => 'BOM',
            'branch' => 'Pasong Tamo',
        ]);

        // 1. Visit Aftersales without score_view: should default to 'overall'
        $response = $this->actingAs($bom)
            ->get('/dashboard?form=aftersales&branch=Pasong+Tamo');

        $response->assertOk();
        $response->assertViewHas('summarySheet', function (array $summary): bool {
            return $summary['activeForm'] === 'aftersales'
                && $summary['summaryMode'] === 'overall'
                && $summary['canSwitchSummaryMode'] === true;
        });

        // 2. Assert 'Overall Aftersales' score switcher is active
        $response->assertSee('Overall Aftersales', false);
        $response->assertSee('class="summary-score-switch active"', false);

        // 3. Assert #summaryEscalationModal markup is present
        $response->assertSee('id="summaryEscalationModal"', false);

        // 4. When explicitly requesting score_view=user, per-user mode is respected
        $userResponse = $this->actingAs($bom)
            ->get('/dashboard?form=aftersales&branch=Pasong+Tamo&score_view=user');

        $userResponse->assertOk();
        $userResponse->assertViewHas('summarySheet', function (array $summary): bool {
            return $summary['activeForm'] === 'aftersales'
                && $summary['summaryMode'] === 'user';
        });
    }

    public function test_subform_doc_modal_shows_accurate_database_answers_without_static_fallbacks(): void
    {
        $admin = $this->administrator();
        $dosTemplate = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();

        // 1. Create a submission with ONLY subform answers (no documentation samples)
        $subformOnlySubmission = ChecklistSubmission::create([
            'checklist_template_id' => $dosTemplate->id,
            'user_id' => $admin->id,
            'submitted_by_user_id' => $admin->id,
            'submitted_by_name' => 'Alice Auditor',
            'branch' => 'Pasong Tamo',
            'scope_key' => hash('sha256', 'pasong tamo'),
            'template_version' => 1,
            'template_snapshot' => ['slug' => 'dealer-operations-standards', 'name' => 'Dealer Operations Standards'],
            'audit_date' => now()->toDateString(),
            'status' => 'submitted',
        ]);

        $item23 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-23')
            ?? $dosTemplate->sections->flatMap->items->first();
        $item61 = $dosTemplate->sections->flatMap->items->firstWhere('key', 'dos-as-61')
            ?? $dosTemplate->sections->flatMap->items->last();

        ChecklistResponse::create([
            'checklist_submission_id' => $subformOnlySubmission->id,
            'checklist_item_id' => $item23->id,
            'item_key' => $item23->key,
            'status' => 'yes',
            'item_snapshot' => ['prompt' => $item23->prompt, 'metadata' => $item23->metadata],
            'details' => [
                'subform_answers' => [
                    'subform-sr-1' => 'yes',
                    'subform-sr-2' => 'no',
                ],
            ],
        ]);

        // Item 61 has status yes but NO documentation samples in details
        ChecklistResponse::create([
            'checklist_submission_id' => $subformOnlySubmission->id,
            'checklist_item_id' => $item61->id,
            'item_key' => $item61->key,
            'status' => 'yes',
            'item_snapshot' => ['prompt' => $item61->prompt, 'metadata' => $item61->metadata],
            'details' => null,
        ]);

        $service = app(AftersalesSubformDocService::class);
        $results = $service->getSubformAndDocumentationResults('Pasong Tamo', now()->toDateString(), $subformOnlySubmission->id);

        // Subform should be recognized accurately from DB
        $this->assertTrue($results['has_submissions']);
        $this->assertTrue($results['has_subform']);
        $this->assertFalse($results['has_documentation'], 'Documentation should NOT be marked has_data when details has no samples');
        $this->assertSame('Existing Submission: Subform', $results['button_label']);
        $this->assertSame('SUBFORM SUBMITTED', $results['badge_label']);

        // Check documentation results are empty, not fake 51 checks
        $this->assertCount(0, $results['documentation']['samples']);
        $this->assertCount(0, $results['documentation']['items_matrix']);
        $this->assertSame(0, $results['documentation']['total_checks']);

        // Check subform section 1 has 1 yes, 1 no from real DB answers
        $srSection = collect($results['subform']['sections'])->firstWhere('key', 'subform-service-reception');
        $this->assertNotNull($srSection);
        $this->assertSame(1, $srSection['yes']);
        $this->assertSame(1, $srSection['no']);
        $this->assertSame(2, $srSection['answered']);

        // Verify dashboard render shows real button label and empty state for documentation
        $response = $this->actingAs($admin)
            ->get('/dashboard?form=aftersales&branch=Pasong+Tamo&submission_id='.$subformOnlySubmission->id);
        $response->assertOk();
        $response->assertSee('Existing Submission: Subform', false);
        $response->assertSee('No Documentation Audit Samples Recorded', false);
    }
}


