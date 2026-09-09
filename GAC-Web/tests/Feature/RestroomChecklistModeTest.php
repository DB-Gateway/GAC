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
