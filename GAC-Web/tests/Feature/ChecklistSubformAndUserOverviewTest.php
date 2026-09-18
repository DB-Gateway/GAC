<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChecklistSubformAndUserOverviewTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    private function administrator(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
    }

    public function test_user_overview_and_subform_templates_rendered_on_dos_checklist_page(): void
    {
        $admin = $this->administrator();

        $response = $this->actingAs($admin)
            ->get('/checklists?checklist=dealer-operations-standards');

        $response->assertOk();
        $response->assertSee('checklist-summary-banner');
        $response->assertSee('Checklist Specification');
        $response->assertSee('Summary');
        $response->assertDontSee('user-overview-grid');
        $response->assertDontSee('user-card');
        $response->assertSee('CE SERVICE');
        $response->assertSee('WORKSHOP SUP');
        $response->assertSee('ASM');
        $response->assertSee('PARTS');
        $response->assertSee('JC');
        $response->assertSee('Subforms');
        $response->assertSee('Documentation Qs');
        $response->assertSee('Subform Eligibility Audit');
    }

    public function test_checklist_summary_is_specific_to_5s_sales(): void
    {
        $admin = $this->administrator();

        $response = $this->actingAs($admin)
            ->get('/checklists?checklist=sales');

        $response->assertOk();
        $response->assertSee('checklist-summary-banner');
        $response->assertSee('5S Sales');
        $response->assertSee('44 Checklist Items');
        $response->assertSee('No Subforms');
        $response->assertSee('5S Sales PIC');
        $response->assertDontSee('data-checker-filter');
        $response->assertDontSee('5 Subforms');
    }

    public function test_checklist_summary_is_specific_to_5s_service(): void
    {
        $admin = $this->administrator();

        $response = $this->actingAs($admin)
            ->get('/checklists?checklist=service');

        $response->assertOk();
        $response->assertSee('checklist-summary-banner');
        $response->assertSee('5S Service');
        $response->assertSee('33 Checklist Items');
        $response->assertSee('No Subforms');
        $response->assertSee('5S Service PIC');
        $response->assertDontSee('data-checker-filter');
        $response->assertDontSee('5 Subforms');
    }

    public function test_checklist_summary_is_specific_to_5s_utilities_restroom(): void
    {
        $admin = $this->administrator();

        $response = $this->actingAs($admin)
            ->get('/checklists?checklist=restroom');

        $response->assertOk();
        $response->assertSee('checklist-summary-banner');
        $response->assertSee('Restroom');
        $response->assertSee('Checklist Items');
        $response->assertSee('10 Hourly Slots');
        $response->assertSee('No Subforms');
        $response->assertSee('5S Utilities PIC');
        $response->assertDontSee('data-checker-filter');
        $response->assertDontSee('5 Subforms');
    }

    public function test_subform_answers_and_eligibility_can_be_saved_in_draft_and_retrieved(): void
    {
        $admin = $this->administrator();

        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $item23 = $template->sections->flatMap->items->firstWhere('code', '23')
            ?? $template->sections->flatMap->items->first();

        $payload = [
            'date' => now()->toDateString(),
            'branch' => 'Cebu South',
            'status' => 'draft',
            'context' => [
                'template_slug' => $template->slug,
                'variant' => 'dos',
            ],
            'responses' => [
                [
                    'item_id' => $item23->id,
                    'item_key' => $item23->key,
                    'status' => 'yes',
                    'remark' => null,
                    'remarks' => null,
                    'finding' => null,
                    'action_plan' => null,
                    'commitment_date' => null,
                    'attachment_path' => null,
                    'details' => [
                        'eligibility' => 'show_subform',
                        'subform_answers' => [
                            'subform-sr-1' => 'yes',
                            'subform-sr-2' => 'yes',
                            'subform-sr-3' => 'yes',
                        ],
                    ],
                ],
            ],
        ];

        $saveResponse = $this->actingAs($admin)
            ->postJson("/checklists/{$template->slug}/draft", $payload);

        $saveResponse->assertSuccessful();

        $loadResponse = $this->actingAs($admin)
            ->getJson("/checklists/{$template->slug}/record?date=".now()->toDateString()."&branch=Cebu+South");

        $loadResponse->assertOk();
        $loadResponse->assertJsonPath("submission.responses.{$item23->key}.details.eligibility", 'show_subform');
        $loadResponse->assertJsonPath("submission.responses.{$item23->key}.details.subform_answers.subform-sr-1", 'yes');
    }

    public function test_administrator_can_create_new_master_checklist_template(): void
    {
        $admin = $this->administrator();

        $payload = [
            'name' => 'FY26 Aftersales Standards Compliance Audit',
            'slug' => 'fy26-aftersales-audit',
            'description' => 'Comprehensive FY26 Aftersales Standards Compliance Audit',
            'instructions' => 'Follow the compliance checklist standards.',
            'variant' => 'dos',
            'clone_from' => 'dealer-operations-standards',
        ];

        $response = $this->actingAs($admin)
            ->postJson('/checklists/templates', $payload);

        $response->assertCreated();
        $response->assertJsonPath('template.slug', 'fy26-aftersales-audit');
        $this->assertDatabaseHas('checklist_templates', [
            'slug' => 'fy26-aftersales-audit',
            'name' => 'FY26 Aftersales Standards Compliance Audit',
        ]);
    }
}
