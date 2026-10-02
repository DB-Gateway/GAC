<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistSection;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChecklistPersistenceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_workbook_and_dos_templates_are_seeded_into_normalized_tables(): void
    {
        $this->assertDatabaseCount('checklist_templates', 6);
        $this->assertDatabaseCount('checklist_sections', 51);
        $this->assertDatabaseCount('checklist_items', 260);

        $this->assertSame(56, ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail()->items()->count());
        $this->assertSame(75, ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail()->items()->count());
        $this->assertSame(22, ChecklistTemplate::where('slug', 'dealer-operations-standards-sales')->firstOrFail()->items()->count());
        $this->assertSame(44, ChecklistTemplate::where('slug', 'sales')->firstOrFail()->items()->count());
        $this->assertSame(33, ChecklistTemplate::where('slug', 'service')->firstOrFail()->items()->count());
        $this->assertSame(30, ChecklistTemplate::where('slug', 'restroom')->firstOrFail()->items()->count());

        $aftersales = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $this->assertSame(75, $aftersales->items()->get()->filter(
            fn (ChecklistItem $item): bool => filled(data_get($item->metadata, 'how_to_check'))
        )->count());
        $this->assertStringContainsString(
            'Subform Verification Requirements',
            (string) data_get($aftersales->items()->where('key', 'dos-as-27')->firstOrFail()->metadata, 'how_to_check')
        );
    }

    public function test_a_draft_is_saved_to_the_database_and_loaded_by_branch_and_date(): void
    {
        $user = $this->administrator();
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $this->actingAs($user)
            ->postJson(route('checklists.save-draft', $template), [
                'date' => '2026-08-22',
                'branch' => 'Pasong Tamo',
                'responses' => [[
                    'item_id' => $item->id,
                    'status' => 'yes',
                ]],
            ])
            ->assertCreated()
            ->assertJsonPath('submission.status', 'draft')
            ->assertJsonPath("submission.responses.{$item->key}.status", 'yes');

        $this->assertDatabaseHas('checklist_submissions', [
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'branch' => 'Pasong Tamo',
            'audit_date' => '2026-08-22 00:00:00',
            'status' => 'draft',
        ]);
        $this->assertDatabaseHas('checklist_responses', [
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => 'yes',
        ]);

        $this->getJson(route('checklists.load', [
            'template' => $template,
            'date' => '2026-08-22',
            'branch' => 'Pasong Tamo',
        ]))
            ->assertOk()
            ->assertJsonPath('submission.status', 'draft')
            ->assertJsonPath("submission.responses.{$item->key}.status", 'yes');
    }

    public function test_mitsubishi_sucat_and_honda_fairview_keep_separate_checklist_records(): void
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        $date = '2026-09-25';
        $sucat = User::factory()->create([
            'branch' => 'Mitsubishi Sucat',
            'user_type' => User::ROLE_5S_SALES,
        ]);
        $fairview = User::factory()->create([
            'branch' => 'Honda Fairview',
            'user_type' => User::ROLE_5S_SALES,
        ]);

        $this->actingAs($sucat)->postJson(route('api.checklists.save-draft', $template), [
            'date' => $date,
            'responses' => [['item_id' => $item->id, 'status' => 'yes']],
        ])->assertCreated();

        $this->actingAs($fairview)
            ->getJson(route('api.checklists.show', ['template' => $template, 'date' => $date]))
            ->assertOk()
            ->assertJsonPath('submission', null);
        $this->getJson(route('api.checklists.index', ['date' => $date]))
            ->assertOk()
            ->assertJsonPath('branch', 'Honda Fairview');
        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => $date,
            'branch' => 'Mitsubishi Sucat',
            'responses' => [['item_id' => $item->id, 'status' => 'no']],
        ])->assertForbidden();
        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => $date,
            'responses' => [['item_id' => $item->id, 'status' => 'no']],
        ])->assertCreated();

        $this->assertDatabaseHas('checklist_submissions', [
            'user_id' => $sucat->id, 'branch' => 'Mitsubishi Sucat',
        ]);
        $this->assertDatabaseHas('checklist_submissions', [
            'user_id' => $fairview->id, 'branch' => 'Honda Fairview',
        ]);
        $this->assertDatabaseCount('checklist_submissions', 2);
    }

    public function test_reassigning_an_account_to_another_branch_does_not_carry_its_draft(): void
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        $date = '2026-09-25';
        $inspector = User::factory()->create([
            'branch' => 'Mitsubishi Sucat',
            'user_type' => User::ROLE_5S_SALES,
        ]);

        $this->actingAs($inspector)->postJson(route('api.checklists.save-draft', $template), [
            'date' => $date,
            'responses' => [['item_id' => $item->id, 'status' => 'yes']],
        ])->assertCreated();

        $inspector->update(['branch' => 'Honda Fairview']);
        $this->getJson(route('api.checklists.show', [
            'template' => $template, 'date' => $date,
        ]))->assertOk()->assertJsonPath('submission', null);
        $this->getJson(route('api.checklists.show', [
            'template' => $template, 'date' => $date, 'branch' => 'Mitsubishi Sucat',
        ]))->assertForbidden();

        $inspector->update(['branch' => 'Mitsubishi Sucat']);
        $this->getJson(route('api.checklists.show', [
            'template' => $template, 'date' => $date,
        ]))->assertOk()->assertJsonPath("submission.responses.{$item->key}.status", 'yes');
    }

    public function test_partial_dos_category_drafts_merge_without_deleting_other_category_responses(): void
    {
        $user = $this->administrator();
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $items = $template->items()->get();
        $basic = $items->first(
            fn (ChecklistItem $item): bool => strcasecmp((string) data_get($item->metadata, 'category'), 'Basic') === 0
        );
        $standard = $items->first(
            fn (ChecklistItem $item): bool => strcasecmp((string) data_get($item->metadata, 'category'), 'Standard') === 0
        );

        $this->assertNotNull($basic);
        $this->assertNotNull($standard);

        $this->actingAs($user)
            ->postJson(route('checklists.save-draft', $template), [
                'date' => '2026-09-08',
                'branch' => 'Pasong Tamo',
                'responses' => [[
                    'item_id' => $basic->id,
                    'status' => 'no',
                    'finding' => 'Basic standard finding',
                    'action_plan' => 'Correct the basic standard',
                    'commitment_date' => '2026-09-09 10:30:00',
                    'details' => ['escalation' => 'property_management'],
                    'attachment_path' => 'checklist-attachments/dos/basic.jpg',
                ]],
            ])
            ->assertCreated()
            ->assertJsonCount(1, 'submission.responses');

        $this->postJson(route('checklists.save-draft', $template), [
            'date' => '2026-09-08',
            'branch' => 'Pasong Tamo',
            'responses' => [[
                'item_id' => $standard->id,
                'status' => 'yes',
            ]],
        ])
            ->assertOk()
            ->assertJsonCount(2, 'submission.responses')
            ->assertJsonPath("submission.responses.{$basic->key}.status", 'no')
            ->assertJsonPath(
                "submission.responses.{$basic->key}.finding",
                'Basic standard finding'
            )
            ->assertJsonPath(
                "submission.responses.{$basic->key}.details.escalation",
                'property_management'
            )
            ->assertJsonPath(
                "submission.responses.{$basic->key}.attachment_path",
                'checklist-attachments/dos/basic.jpg'
            )
            ->assertJsonPath("submission.responses.{$standard->key}.status", 'yes');

        $this->assertDatabaseCount('checklist_submissions', 1);
        $this->assertDatabaseCount('checklist_responses', 2);
    }

    public function test_incomplete_5s_submission_is_rejected_without_partial_database_writes(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $this->actingAs($this->administrator())
            ->postJson(route('checklists.submit', $template), [
                'date' => '2026-08-22',
                'branch' => 'Pasong Tamo',
                'responses' => [[
                    'item_id' => $item->id,
                    'status' => 'yes',
                ]],
            ])
            ->assertUnprocessable();

        $this->assertDatabaseCount('checklist_submissions', 0);
        $this->assertDatabaseCount('checklist_responses', 0);
        $this->assertDatabaseCount('reports', 0);
    }

    public function test_hourly_restroom_submission_saves_all_slots_and_creates_a_report_snapshot(): void
    {
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $slotKeys = collect($template->settings['time_slots'])->pluck('key');
        $responses = $template->items()->orderBy('sort_order')->get()->map(function ($item, int $index) use ($slotKeys): array {
            $slots = $slotKeys->mapWithKeys(fn (string $slot): array => [$slot => 'good'])->all();

            if ($index === 0) {
                $slots['08:00'] = 'not_good';
            }

            return [
                'item_id' => $item->id,
                'status' => $index === 0 ? 'no' : 'yes',
                'remark' => $index === 0 ? 'Cleaned immediately.' : null,
                'details' => ['slots' => $slots],
            ];
        })->all();

        $response = $this->actingAs($this->administrator())
            ->postJson(route('checklists.submit', $template), [
                'date' => '2026-08-22',
                'branch' => 'Pasong Tamo',
                'responses' => $responses,
            ]);

        $response
            ->assertCreated()
            ->assertJsonPath('submission.status', 'submitted')
            ->assertJsonPath('submission.scores.slot_total', 120)
            ->assertJsonPath('submission.scores.slots_answered', 120)
            ->assertJsonPath('submission.scores.completed_slots', 4)
            ->assertJsonPath('submission.scores.good', 119)
            ->assertJsonPath('submission.scores.bad', 1);

        $submission = ChecklistSubmission::firstOrFail();
        $this->assertCount(30, $submission->responses);
        $this->assertDatabaseHas('reports', [
            'checklist_submission_id' => $submission->id,
            'checklist_template_id' => $template->id,
            'type' => 'checklist_submission',
            'status' => 'ready',
        ]);

        $snapshot = Report::firstOrFail()->data_snapshot;
        $this->assertSame('Restroom Checklist', data_get($snapshot, 'template.name'));
        $this->assertSame('not_good', data_get($snapshot, 'submission.responses.restroom-item-1.details.slots.08:00'));
    }

    public function test_repeating_an_identical_successful_submission_is_idempotent(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $responses = $this->allYesResponses($template);
        $user = $this->administrator();

        $first = $this->actingAs($user)
            ->postJson(route('checklists.submit', $template), [
                'date' => '2026-08-22',
                'branch' => 'Pasong Tamo',
                'context' => [
                    'dealer' => 'Gateway Motors',
                    'auditor' => 'Test Auditor',
                ],
                'responses' => $responses,
            ])
            ->assertCreated();

        $second = $this->postJson(route('checklists.submit', $template), [
            'date' => '2026-08-22',
            'branch' => 'Pasong Tamo',
            'context' => [
                'auditor' => 'Test Auditor',
                'dealer' => 'Gateway Motors',
            ],
            'responses' => array_reverse($responses),
        ]);

        $second
            ->assertOk()
            ->assertJsonPath('message', 'This checklist was already submitted.')
            ->assertJsonPath('submission.id', $first->json('submission.id'))
            ->assertJsonPath('report_id', $first->json('report_id'));

        $this->assertDatabaseCount('checklist_submissions', 1);
        $this->assertDatabaseCount('checklist_responses', 56);
        $this->assertDatabaseCount('reports', 1);
    }

    public function test_identical_checklists_from_different_employees_keep_separate_attribution(): void
    {
        $this->travelTo('2026-08-29 04:30:00');

        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $responses = $this->allYesResponses($template);
        $firstEmployee = User::factory()->create([
            'name' => 'First Employee',
            'email' => 'first.employee@example.com',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
        ]);
        $secondEmployee = User::factory()->create([
            'name' => 'Second Employee',
            'email' => 'second.employee@example.com',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
        ]);
        $payload = [
            'date' => '2026-08-29',
            'branch' => 'Pasong Tamo',
            'responses' => $responses,
        ];

        $first = $this->actingAs($firstEmployee)
            ->postJson(route('checklists.submit', $template), $payload)
            ->assertCreated();

        $second = $this->actingAs($secondEmployee)
            ->postJson(route('checklists.submit', $template), $payload)
            ->assertCreated();

        $this->assertNotSame($first->json('submission.id'), $second->json('submission.id'));
        $this->assertDatabaseCount('checklist_submissions', 2);
        $this->assertDatabaseHas('checklist_submissions', [
            'id' => $first->json('submission.id'),
            'user_id' => $firstEmployee->id,
            'submitted_by_user_id' => $firstEmployee->id,
            'submitted_by_name' => 'First Employee',
            'submitted_by_email' => 'first.employee@example.com',
            'submitted_by_user_type' => User::ROLE_PERSON_IN_CHARGE,
            'status' => 'submitted',
        ]);
        $this->assertDatabaseHas('checklist_submissions', [
            'id' => $second->json('submission.id'),
            'user_id' => $secondEmployee->id,
            'submitted_by_user_id' => $secondEmployee->id,
            'submitted_by_name' => 'Second Employee',
            'submitted_by_email' => 'second.employee@example.com',
            'submitted_by_user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'status' => 'submitted',
        ]);

        $this->actingAs($firstEmployee)
            ->postJson(route('checklists.submit', $template), $payload)
            ->assertOk()
            ->assertJsonPath('message', 'This checklist was already submitted.')
            ->assertJsonPath('submission.id', $first->json('submission.id'));

        $this->assertDatabaseCount('checklist_submissions', 2);
        $this->assertDatabaseCount('reports', 2);
    }

    public function test_generated_report_title_is_limited_to_the_mariadb_column_length(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $template->update(['name' => str_repeat('T', 255)]);

        $this->actingAs($this->administrator())
            ->postJson(route('checklists.submit', $template), [
                'date' => '2026-08-22',
                'branch' => str_repeat('B', 255),
                'responses' => $this->allYesResponses($template),
            ])
            ->assertCreated();

        $title = Report::firstOrFail()->title;

        $this->assertSame(255, mb_strlen($title));
        $this->assertSame(str_repeat('T', 255), $title);
    }

    public function test_reset_deletes_an_existing_draft_without_creating_an_empty_submission(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $this->actingAs($this->administrator())
            ->postJson(route('checklists.save-draft', $template), [
                'date' => '2026-08-22',
                'branch' => 'Pasong Tamo',
                'responses' => [[
                    'item_id' => $item->id,
                    'status' => 'yes',
                ]],
            ])
            ->assertCreated();

        $this->deleteJson(route('checklists.reset', $template), [
            'date' => '2026-08-22',
            'branch' => 'Pasong Tamo',
        ])
            ->assertOk()
            ->assertJsonPath('submission', null)
            ->assertJsonPath('deleted_drafts', 1);

        $this->assertDatabaseCount('checklist_submissions', 0);
        $this->assertDatabaseCount('checklist_responses', 0);
    }

    public function test_template_update_rejects_section_and_item_keys_that_only_differ_by_case(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $originalVersion = $template->version;
        $this->actingAs($this->administrator());

        $this->putJson(route('checklists.template.update', $template), [
            'sections' => [
                [
                    'key' => 'Customer-Area',
                    'title' => 'Customer Area',
                    'items' => [[
                        'key' => 'customer-area-item',
                        'prompt' => 'First item',
                    ]],
                ],
                [
                    'key' => 'customer-area',
                    'title' => 'Duplicate Customer Area',
                    'items' => [[
                        'key' => 'different-item',
                        'prompt' => 'Second item',
                    ]],
                ],
            ],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('sections.1.key');

        $this->putJson(route('checklists.template.update', $template), [
            'sections' => [[
                'key' => 'Customer-Area',
                'title' => 'Customer Area',
                'items' => [
                    [
                        'key' => 'Hourly-Check',
                        'prompt' => 'First item',
                    ],
                    [
                        'key' => 'hourly-check',
                        'prompt' => 'Duplicate item',
                    ],
                ],
            ]],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('sections.0.items.1.key');

        $this->assertSame($originalVersion, $template->fresh()->version);
    }

    public function test_reseeding_preserves_live_template_edits_and_custom_checklist_rows(): void
    {
        $template = ChecklistTemplate::where('slug', 'gateway-5s')->firstOrFail();
        $template->update([
            'name' => 'Administrator Custom 5S Checklist',
            'version' => 9,
            'settings' => ['validation_mode' => 'yes_no_na', 'custom' => true],
        ]);

        $firstItem = $template->items()->where('key', 'item-1')->firstOrFail();
        $firstItem->update(['prompt' => 'Administrator customized first checklist item.']);

        $section = ChecklistSection::create([
            'checklist_template_id' => $template->id,
            'key' => 'administrator-custom-section',
            'title' => 'Administrator Custom Section',
            'sort_order' => 99,
            'is_active' => true,
        ]);
        ChecklistItem::create([
            'checklist_template_id' => $template->id,
            'checklist_section_id' => $section->id,
            'key' => 'administrator-custom-item',
            'prompt' => 'Administrator custom checklist item.',
            'sort_order' => 0,
            'is_active' => true,
        ]);

        $this->seed(ChecklistTemplateSeeder::class);

        $template->refresh();
        $this->assertSame('Administrator Custom 5S Checklist', $template->name);
        $this->assertSame(9, $template->version);
        $this->assertTrue($template->settings['custom']);
        $this->assertSame(
            'Administrator customized first checklist item.',
            $template->items()->where('key', 'item-1')->firstOrFail()->prompt
        );
        $this->assertTrue($template->sections()->where('key', 'administrator-custom-section')->firstOrFail()->is_active);
        $this->assertTrue($template->items()->where('key', 'administrator-custom-item')->firstOrFail()->is_active);
        $this->assertSame(57, $template->items()->count());
    }

    private function allYesResponses(ChecklistTemplate $template): array
    {
        return $template->items()
            ->orderBy('id')
            ->get()
            ->map(fn (ChecklistItem $item): array => [
                'item_id' => $item->id,
                'status' => 'yes',
            ])
            ->all();
    }

    private function administrator(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
    }
}
