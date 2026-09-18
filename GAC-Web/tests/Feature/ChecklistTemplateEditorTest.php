<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistResponse;
use App\Models\ChecklistSection;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChecklistTemplateEditorTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Replace migration presets with small fixtures in the isolated test DB.
        ChecklistTemplate::query()->delete();
    }

    public function test_reordering_renumbers_questions_and_preserves_ids_metadata_and_response_history(): void
    {
        $template = $this->template();
        [$firstSection, $secondSection] = $template->sections->all();
        [$first, $second] = $firstSection->items->all();
        [$third, $fourth] = $secondSection->items->all();
        $this->actingAs($this->administrator());
        $this->postJson(route('checklists.save-draft', $template), [
            'date' => '2026-09-11',
            'branch' => 'Pasong Tamo',
            'responses' => [
                ['item_id' => $first->id, 'status' => 'yes'],
                ['item_id' => $third->id, 'status' => 'yes'],
            ],
        ])->assertCreated();
        $history = ChecklistResponse::orderBy('id')->get()->toArray();
        $payload = $this->payload($template);
        $payload['sections'] = [
            8 => $payload['sections'][1],
            3 => $payload['sections'][0],
        ];
        $payload['sections'][8]['items'] = [
            9 => ['id' => $second->id, 'key' => $second->key, 'prompt' => $second->prompt, 'metadata' => ['number' => 999, 'code' => '999']],
            4 => ['id' => $fourth->id, 'key' => $fourth->key, 'prompt' => $fourth->prompt],
        ];
        $payload['sections'][3]['items'] = [['id' => $first->id, 'key' => $first->key, 'prompt' => $first->prompt]];

        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertOk()
            ->assertJsonPath('template.sections.0.id', $secondSection->id)
            ->assertJsonPath('template.sections.0.sort_order', 0)
            ->assertJsonPath('template.sections.0.items.0.id', $second->id)
            ->assertJsonPath('template.sections.0.items.0.sort_order', 0)
            ->assertJsonPath('template.sections.0.items.0.metadata.number', 1)
            ->assertJsonPath('template.sections.0.items.0.metadata.code', '1')
            ->assertJsonPath('template.sections.0.items.1.metadata.number', 2)
            ->assertJsonPath('template.sections.1.items.0.metadata.number', 3);

        $this->assertSame($secondSection->id, $second->fresh()->checklist_section_id);
        $this->assertSame('ASM', $second->fresh()->metadata['checker']);
        $this->assertSame('Keep the existing inspection guide.', $second->fresh()->metadata['how_to_check']);
        $this->assertSame('PM', $second->fresh()->metadata['escalation']);
        $this->assertSame($history, ChecklistResponse::orderBy('id')->get()->toArray());
        $this->assertFalse($third->fresh()->is_active);
        $this->assertDatabaseCount('checklist_items', 4);
        $this->assertDatabaseCount('checklist_responses', 2);
    }

    public function test_instructions_and_question_guidance_can_be_created_cleared_and_preserved_when_omitted(): void
    {
        $template = $this->template();
        $item = $template->sections->first()->items->first();
        $item->update(['metadata' => [...$item->metadata, 'howToCheck' => 'Legacy guide.']]);
        $payload = $this->payload($template);
        $payload['instructions'] = 'Start at reception and inspect each area.';
        $payload['sections'][0]['items'][0]['how_to_check'] = 'Photograph the sign and check every light.';
        $this->actingAs($this->administrator());

        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertOk()
            ->assertJsonPath('template.instructions', $payload['instructions'])
            ->assertJsonPath('template.settings.scoring.overall_required_percentage', 80)
            ->assertJsonPath('template.sections.0.items.0.metadata.how_to_check', 'Photograph the sign and check every light.');

        $this->putJson(route('checklists.template.update', $template), $this->payload($template))
            ->assertOk()
            ->assertJsonPath('template.instructions', $payload['instructions'])
            ->assertJsonPath('template.sections.0.items.0.metadata.how_to_check', 'Photograph the sign and check every light.');

        $payload['instructions'] = '';
        $payload['sections'][0]['items'][0]['how_to_check'] = '';
        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertOk()
            ->assertJsonPath('template.instructions', null)
            ->assertJsonPath('template.sections.0.items.0.metadata.how_to_check', null)
            ->assertJsonPath('template.sections.0.items.0.metadata.howToCheck', null)
            ->assertJsonPath('template.settings.validation_mode', 'yes_no_na');
    }

    public function test_options_are_specific_to_each_checklist_and_keep_existing_custom_values(): void
    {
        $this->actingAs($this->administrator());
        foreach ([
            'sales' => '5S_SALES',
            'service' => '5S_SERVICE',
            'restroom' => '5S_UTILITIES',
            'dealer-operations-standards-sales' => 'GM',
            'dealer-operations-standards' => 'GM',
        ] as $slug => $defaultRole) {
            $template = $this->template($slug);
            $response = $this->getJson(route('checklists.load', $template));
            $response->assertOk()
                ->assertJsonPath('template.editor_options.default_responsible_role', $defaultRole)
                ->assertJsonPath('template.editor_options.responsible_required', true);
            $isDos = str_starts_with($slug, 'dealer-operations');
            $this->assertSame($isDos, $response->json('template.editor_options.level_required'));
            $this->assertSame($isDos ? ['Basic', 'Standard', 'Beyond'] : [], array_column($response->json('template.editor_options.levels'), 'value'));
        }

        $item = $template->sections->first()->items->first();
        $item->update(['metadata' => ['responsible_role' => 'Area Lead', 'level' => 'Local Standard']]);
        $response = $this->getJson(route('checklists.load', $template))->assertOk();
        $this->assertContains('Area Lead', array_column($response->json('template.editor_options.responsible_roles'), 'value'));
        $this->assertContains('Local Standard', array_column($response->json('template.editor_options.levels'), 'value'));
    }

    public function test_responsible_and_level_validate_choices_and_omitted_legacy_fields_receive_defaults(): void
    {
        $template = $this->template('dealer-operations-standards-sales');
        $payload = $this->payload($template);
        $this->actingAs($this->administrator());
        $payload['sections'][0]['items'][0]['responsible_role'] = '5S_UTILITIES';
        $payload['sections'][0]['items'][0]['level'] = 'Unsupported';
        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['sections.0.items.0.metadata.responsible_role', 'sections.0.items.0.metadata.level']);

        $payload['sections'][0]['items'][0]['responsible_role'] = '';
        $payload['sections'][0]['items'][0]['level'] = '';
        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['sections.0.items.0.metadata.responsible_role', 'sections.0.items.0.metadata.level']);

        $this->putJson(route('checklists.template.update', $template), $this->payload($template))
            ->assertOk()
            ->assertJsonPath('template.sections.0.items.0.metadata.responsible_role', 'GM')
            ->assertJsonPath('template.sections.0.items.0.metadata.pic', 'GM')
            ->assertJsonPath('template.sections.0.items.0.metadata.level', 'Standard');
    }

    public function test_existing_keys_cannot_be_changed_and_ids_cannot_reference_another_template(): void
    {
        $template = $this->template();
        $other = $this->template('service');
        $payload = $this->payload($template);
        $payload['sections'][0]['key'] = 'changed-section';
        $payload['sections'][0]['items'][0]['key'] = 'changed-question';
        $this->actingAs($this->administrator());
        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['sections.0.key', 'sections.0.items.0.key']);

        $payload = $this->payload($template);
        $payload['sections'][0]['id'] = $other->sections->first()->id;
        $payload['sections'][0]['items'][0]['id'] = $other->sections->first()->items->first()->id;
        $this->putJson(route('checklists.template.update', $template), $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['sections.0.id', 'sections.0.items.0.id']);
        $this->assertSame(1, $template->fresh()->version);
    }

    public function test_ordinary_checklists_reject_explicitly_blank_responsibility_and_unused_levels(): void
    {
        $template = $this->template();
        $payload = $this->payload($template);
        $payload['sections'][0]['items'][0]['responsible_role'] = '';
        $payload['sections'][0]['items'][0]['level'] = 'Basic';
        $this->actingAs($this->administrator())
            ->putJson(route('checklists.template.update', $template), $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['sections.0.items.0.metadata.responsible_role', 'sections.0.items.0.metadata.level']);
    }

    private function template(string $slug = 'sales'): ChecklistTemplate
    {
        $template = ChecklistTemplate::create([
            'slug' => $slug,
            'name' => 'Editor test '.$slug,
            'version' => 1,
            'is_active' => true,
            'settings' => [
                'validation_mode' => str_starts_with($slug, 'dealer-operations') ? 'dos' : 'yes_no_na',
                'instructions' => 'Original instructions.',
                'scoring' => ['overall_required_percentage' => 80],
            ],
        ]);
        foreach (['first', 'second'] as $sectionOrder => $key) {
            $section = ChecklistSection::create([
                'checklist_template_id' => $template->id,
                'key' => $key,
                'title' => ucfirst($key).' area',
                'sort_order' => $sectionOrder,
                'is_active' => true,
            ]);
            foreach ([0, 1] as $itemOrder) {
                ChecklistItem::create([
                    'checklist_template_id' => $template->id,
                    'checklist_section_id' => $section->id,
                    'key' => $key.'-'.$itemOrder,
                    'prompt' => 'Inspect '.$key.' '.$itemOrder,
                    'sort_order' => $itemOrder,
                    'metadata' => [
                        'number' => ($sectionOrder * 2) + $itemOrder + 1,
                        'checker' => 'ASM',
                        'how_to_check' => 'Keep the existing inspection guide.',
                        'escalation' => 'PM',
                    ],
                    'is_active' => true,
                ]);
            }
        }

        return $template->load('sections.items');
    }

    private function payload(ChecklistTemplate $template): array
    {
        return ['sections' => $template->sections->map(fn (ChecklistSection $section): array => [
            'id' => $section->id,
            'key' => $section->key,
            'title' => $section->title,
            'items' => $section->items->map(fn (ChecklistItem $item): array => [
                'id' => $item->id,
                'key' => $item->key,
                'prompt' => $item->prompt,
            ])->all(),
        ])->all()];
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
