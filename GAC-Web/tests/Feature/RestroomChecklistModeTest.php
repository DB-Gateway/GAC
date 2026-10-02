<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RestroomChecklistModeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_web_and_mobile_load_the_same_four_utilities_inspections(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);
        $slots = [
            ['key' => '08:00', 'label' => '8 AM'],
            ['key' => '11:00', 'label' => '11 AM'],
            ['key' => '13:00', 'label' => '1 PM'],
            ['key' => '16:00', 'label' => '4 PM'],
        ];

        foreach (['checklists.load', 'api.checklists.show'] as $route) {
            $this->actingAs($user)
                ->getJson(route($route, ['template' => 'utilities', 'date' => '2026-09-19']))
                ->assertOk()
                ->assertJsonPath('template.time_slots', $slots)
                ->assertJsonPath('template.settings.time_slots', $slots);
        }

        $response = $this->getJson(route('api.checklists.index', ['date' => '2026-09-19']))
            ->assertOk();
        $this->assertNotEmpty($response->json('checklists'));
        $this->assertSame($slots, $response->json('checklists.0.settings.time_slots'));
        $this->assertSame(120, $response->json('checklists.0.work_unit_count'));
    }

    public function test_non_hourly_restroom_template_is_loaded_as_an_editable_standard_checklist(): void
    {
        $template = ChecklistTemplate::query()->where('slug', 'restroom')->firstOrFail();
        $template->update([
            'settings' => [
                'validation_mode' => 'yes_no_na',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => 'Complete the restroom checklist once per audit.',
            ],
        ]);
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($user)
            ->getJson(route('checklists.load', [
                'template' => $template,
                'date' => '2026-09-08',
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk()
            ->assertJsonPath('template.settings.validation_mode', 'yes_no_na')
            ->assertJsonPath('template.time_slots', [])
            ->assertJsonPath('template.instructions', 'Complete the restroom checklist once per audit.');

        $responses = $template->items()->get()->map(fn ($item): array => [
            'item_id' => $item->id,
            'status' => 'yes',
        ])->all();

        $this->actingAs($user)
            ->postJson(route('checklists.submit', $template), [
                'date' => '2026-09-08',
                'branch' => 'Pasong Tamo',
                'responses' => $responses,
            ])
            ->assertCreated()
            ->assertJsonPath('submission.scores.total', 30)
            ->assertJsonPath('submission.scores.answered', 30)
            ->assertJsonMissingPath('submission.scores.slot_total');
    }
}
