<?php

namespace Tests\Feature;

use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Notifications\PicTaskCompleted;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use ReflectionClass;
use Tests\TestCase;

class DosDocumentationAndSubformIntegrationTest extends TestCase
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

    private function branchOperationsManager(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'account_status' => 'active',
        ]);
    }

    private function administrator(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
    }

    public function test_branch_operations_manager_has_editor_access_and_buttons(): void
    {
        $bom = $this->branchOperationsManager();

        $response = $this->actingAs($bom)
            ->get('/checklists?checklist=dealer-operations-standards');

        $response->assertOk();
        $response->assertSee('id="editTemplateButton"', false);
        $response->assertSee('id="templateEditor"', false);
        $response->assertSee('id="createTemplateButton"', false);
        $response->assertSee('editor-scope-tabs');
        $response->assertSee('DOS Subform Standards');
        $response->assertSee('DOS Documentation Standards');
        $response->assertSee('documentationTemplate');
        $response->assertSee('id="editorFilterCard"', false);
        $response->assertSee('id="editorCheckerPills"', false);
        $response->assertSee('id="editorItemSearch"', false);
        $response->assertSee('Filter by User / Auditor');
    }

    public function test_editor_renders_user_filter_card_and_badges(): void
    {
        $bom = $this->branchOperationsManager();

        $response = $this->actingAs($bom)
            ->get('/checklists?checklist=dealer-operations-standards');

        $response->assertOk();
        $response->assertSee('id="editorFilterCard"', false);
        $response->assertSee('id="editorCheckerPills"', false);
        $response->assertSee('id="editorItemSearch"', false);
        $response->assertSee('Filter by User / Auditor');
        $response->assertSee('editor-item-user-badge');
        $response->assertSee('renderEditorUserFilterPills');
        $response->assertSee('filterEditorItems');
    }

    public function test_administrator_has_editor_access_and_buttons(): void
    {
        $admin = $this->administrator();

        $response = $this->actingAs($admin)
            ->get('/checklists?checklist=dealer-operations-standards');

        $response->assertOk();
        $response->assertSee('id="editTemplateButton"', false);
        $response->assertSee('id="templateEditor"', false);
        $response->assertSee('id="createTemplateButton"', false);
    }

    public function test_dos_documentation_and_subform_templates_exist_with_proper_counts(): void
    {
        $subform = ChecklistTemplate::where('slug', 'dealer-operations-standards-subform')->first();
        $this->assertNotNull($subform);
        $this->assertSame(39, $subform->sections->flatMap->items->count());
        $this->assertSame(5, $subform->sections->count());

        $doc = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->first();
        $this->assertNotNull($doc);
        $this->assertSame(17, $doc->sections->flatMap->items->count());
        $this->assertSame(3, $doc->sections->count());
    }

    public function test_documentation_samples_can_be_saved_in_draft_and_retrieved(): void
    {
        $bom = $this->branchOperationsManager();
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $item61 = $template->sections->flatMap->items->firstWhere('code', '61')
            ?? $template->sections->flatMap->items->first();

        $payload = [
            'date' => now()->toDateString(),
            'branch' => 'Pasong Tamo',
            'status' => 'draft',
            'context' => [
                'template_slug' => $template->slug,
                'variant' => 'dos',
            ],
            'responses' => [
                [
                    'item_id' => $item61->id,
                    'item_key' => $item61->key,
                    'status' => 'yes',
                    'remark' => 'Documentation audit complete',
                    'remarks' => 'Documentation audit complete',
                    'finding' => null,
                    'action_plan' => null,
                    'commitment_date' => null,
                    'attachment_path' => null,
                    'details' => [
                        'documentation_samples' => [
                            [
                                'ro_number' => 'RO-1001',
                                'job_type' => '10,000 km PMS',
                                'answers' => [
                                    'doc-rc-1' => 'yes',
                                    'doc-rc-2' => 'yes',
                                ],
                            ],
                            [
                                'ro_number' => 'RO-1002',
                                'job_type' => '20,000 km PMS',
                                'answers' => [
                                    'doc-rc-1' => 'yes',
                                    'doc-rc-2' => 'no',
                                ],
                            ],
                            [
                                'ro_number' => 'RO-1003',
                                'job_type' => 'General Repair',
                                'answers' => [
                                    'doc-rc-1' => 'yes',
                                    'doc-rc-2' => 'yes',
                                ],
                            ],
                        ],
                        'documentation_answers' => [
                            'doc-rc-1' => 'yes',
                            'doc-rc-2' => 'yes',
                        ],
                    ],
                ],
            ],
        ];

        $saveResponse = $this->actingAs($bom)
            ->postJson("/checklists/{$template->slug}/draft", $payload);

        $saveResponse->assertSuccessful();

        $loadResponse = $this->actingAs($bom)
            ->getJson("/checklists/{$template->slug}/record?date=".now()->toDateString()."&branch=Pasong+Tamo");

        $loadResponse->assertOk();
        $loadResponse->assertJsonPath("submission.responses.{$item61->key}.details.documentation_samples.0.ro_number", 'RO-1001');
        $loadResponse->assertJsonPath("submission.responses.{$item61->key}.details.documentation_samples.1.ro_number", 'RO-1002');
        $loadResponse->assertJsonPath("submission.responses.{$item61->key}.details.documentation_samples.1.answers.doc-rc-2", 'no');
    }

    public function test_branch_operations_manager_can_update_subform_template(): void
    {
        $bom = $this->branchOperationsManager();
        $subform = ChecklistTemplate::where('slug', 'dealer-operations-standards-subform')->firstOrFail();
        $firstSection = $subform->sections->first();
        $firstItem = $firstSection->items->first();

        $payload = [
            'name' => 'Dealer Operations Standards - Subform Updated',
            'short_name' => 'DOS Subform',
            'description' => 'Updated subform description',
            'instructions' => 'Updated instructions',
            'sections' => [
                [
                    'id' => $firstSection->id,
                    'key' => $firstSection->key,
                    'title' => 'Updated Service Reception',
                    'sort_order' => 0,
                    'items' => [
                        [
                            'id' => $firstItem->id,
                            'key' => $firstItem->key,
                            'prompt' => 'Updated subform standard question prompt',
                            'sort_order' => 0,
                            'metadata' => [
                                'checker' => 'CE SERVICE',
                                'number' => 1,
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $response = $this->actingAs($bom)
            ->putJson(route('checklists.template.update', $subform), $payload);

        $response->assertOk();
        $response->assertJsonPath('template.name', 'Dealer Operations Standards - Subform Updated');
        $this->assertDatabaseHas('checklist_items', [
            'id' => $firstItem->id,
            'prompt' => 'Updated subform standard question prompt',
        ]);
    }

    public function test_branch_operations_manager_can_update_documentation_template(): void
    {
        $bom = $this->branchOperationsManager();
        $doc = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->firstOrFail();
        $firstSection = $doc->sections->first();
        $firstItem = $firstSection->items->first();

        $payload = [
            'name' => 'Dealer Operations Standards - Documentation Updated',
            'short_name' => 'DOS Documentation',
            'description' => 'Updated documentation description',
            'instructions' => 'Updated instructions',
            'sections' => [
                [
                    'id' => $firstSection->id,
                    'key' => $firstSection->key,
                    'title' => 'Updated Rationalized Checksheet',
                    'sort_order' => 0,
                    'items' => [
                        [
                            'id' => $firstItem->id,
                            'key' => $firstItem->key,
                            'prompt' => 'Updated documentation standard prompt',
                            'sort_order' => 0,
                            'metadata' => [
                                'checker' => 'CE SERVICE',
                                'number' => 1,
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $response = $this->actingAs($bom)
            ->putJson(route('checklists.template.update', $doc), $payload);

        $response->assertOk();
        $response->assertJsonPath('template.name', 'Dealer Operations Standards - Documentation Updated');
        $this->assertDatabaseHas('checklist_items', [
            'id' => $firstItem->id,
            'prompt' => 'Updated documentation standard prompt',
        ]);
    }

    public function test_documentation_cascades_no_answers_and_notifies_bom_and_gm_on_submission_and_update(): void
    {
        Notification::fake();

        $bom = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'account_status' => 'active',
        ]);

        $gm = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $auditor = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_CE_SERVICE,
            'account_status' => 'active',
        ]);

        $doc = ChecklistTemplate::where('slug', 'dealer-operations-standards-documentation')->firstOrFail();
        $items = $doc->sections->flatMap->items;
        $firstItem = $items->first();
        $secondItem = $items->get(1);

        // Submitting with Customer 1 having an initial NO on secondItem
        // Under prerequisite cascade, Customer 1 answers should all cascade to NO
        $customer1 = [
            'customer_index' => 1,
            'ro_number' => 'RO-001',
            'mileage' => '10,000 km',
            'answers' => [
                $firstItem->key => 'yes',
                $secondItem->key => 'no',
            ],
        ];

        $payload = [
            'date' => now()->toDateString(),
            'branch' => 'Pasong Tamo',
            'status' => 'submitted',
            'responses' => $items->map(function ($item) use ($customer1) {
                return [
                    'item_id' => $item->id,
                    'item_key' => $item->key,
                    'status' => 'yes',
                    'details' => [
                        'customers' => [$customer1],
                    ],
                ];
            })->all(),
        ];

        $response = $this->actingAs($auditor)
            ->postJson("/checklists/{$doc->slug}/submit", $payload);

        $response->assertSuccessful();

        // Check that Customer 1's firstItem cascaded to 'no' because secondItem was 'no'
        $submission = ChecklistSubmission::latest('id')->firstOrFail();
        $storedCust1 = data_get($submission->responses->first()->details, 'customers.0');
        $this->assertSame('no', data_get($storedCust1, "answers.{$firstItem->key}"));
        $this->assertSame('no', data_get($storedCust1, "answers.{$secondItem->key}"));
        // Overall item status should also be 'no'
        $this->assertSame('no', $submission->responses->firstWhere('item_key', $firstItem->key)->status);

        // Verify notification sent to both BOM and GM
        Notification::assertSentTo(
            [$bom, $gm],
            PicTaskCompleted::class,
            function (PicTaskCompleted $notification) {
                $payload = $notification->toArray(new User);
                return $payload['event'] === 'dos_audit_submitted'
                    && ($payload['customer_sample_count'] ?? null) === 1;
            }
        );

        // Now user adds Customer 2 even though documentation was already submitted earlier!
        $customer2 = [
            'customer_index' => 2,
            'ro_number' => 'RO-002',
            'mileage' => '20,000 km',
            'answers' => [
                $firstItem->key => 'yes',
                $secondItem->key => 'yes',
            ],
        ];

        Notification::fake(); // reset notification fake

        $updatedPayload = [
            'date' => now()->toDateString(),
            'branch' => 'Pasong Tamo',
            'status' => 'submitted',
            'responses' => $items->map(function ($item) use ($customer1, $customer2) {
                return [
                    'item_id' => $item->id,
                    'item_key' => $item->key,
                    'status' => 'yes',
                    'details' => [
                        'customers' => [$customer1, $customer2],
                    ],
                ];
            })->all(),
        ];

        $updateResponse = $this->actingAs($auditor)
            ->postJson("/checklists/{$doc->slug}/submit", $updatedPayload);

        $updateResponse->assertSuccessful();

        $submission->refresh();
        $this->assertCount(2, data_get($submission->responses->first()->details, 'customers'));

        // Verify notification sent to BOM and GM again with 2 customer samples
        Notification::assertSentTo(
            [$bom, $gm],
            PicTaskCompleted::class,
            function (PicTaskCompleted $notification) {
                $payload = $notification->toArray(new User);
                return $payload['event'] === 'dos_audit_submitted'
                    && ($payload['customer_sample_count'] ?? null) === 2;
            }
        );
    }
}
