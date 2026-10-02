<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class UtilitiesScheduleMigrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_schedule_update_preserves_questions_toggles_and_saved_audits(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $legacyKeys = ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00', '17:00'];
        $settings = $template->settings;
        $settings['instructions'] = 'Custom branch instructions';
        $settings['time_slots'] = array_map(fn ($key): array => [
            'key' => $key, 'label' => $key, 'window_minutes' => 60,
        ], $legacyKeys);
        $template->update(['settings' => $settings]);
        $administrator = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);
        $responses = $template->items->map(fn ($item): array => [
            'item_id' => $item->id,
            'details' => ['slots' => array_fill_keys($legacyKeys, 'good')],
        ])->all();
        $this->actingAs($administrator)
            ->postJson(route('checklists.submit', $template), [
                'date' => '2026-09-18',
                'branch' => 'Pasong Tamo',
                'responses' => $responses,
            ])->assertCreated();

        $item = $template->items->first();
        $item->update(['metadata' => array_merge($item->metadata ?? [], [
            'active_slots' => ['08:00', '09:00', '14:00'],
        ])]);
        $alias = $template->replicate();
        $alias->slug = 'utilities';
        $alias->save();
        $tables = ['checklist_sections', 'checklist_items', 'checklist_submissions', 'checklist_responses', 'reports'];
        $before = [];
        foreach ($tables as $table) {
            $before[$table] = DB::table($table)->orderBy('id')->get()->toJson();
        }
        $otherTemplates = DB::table('checklist_templates')->whereNotIn('slug', ['restroom', 'utilities'])
            ->orderBy('id')->get()->toJson();
        $version = $template->version;
        $migration = require database_path('migrations/2026_09_19_000100_update_utilities_checklist_schedule.php');
        $migration->up();

        foreach ([$template->fresh(), $alias->fresh()] as $updated) {
            $this->assertSame(['08:00', '11:00', '14:00', '16:00'], array_column($updated->settings['time_slots'], 'key'));
            $this->assertSame($version + 1, $updated->version);
            $this->assertSame('Custom branch instructions', $updated->settings['instructions']);
            $this->assertSame(60, $updated->settings['time_slots'][0]['window_minutes']);
        }
        foreach ($tables as $table) {
            $this->assertSame($before[$table], DB::table($table)->orderBy('id')->get()->toJson(), $table);
        }
        $this->assertSame($otherTemplates, DB::table('checklist_templates')->whereNotIn('slug', ['restroom', 'utilities'])
            ->orderBy('id')->get()->toJson());

        $migration->up();
        $this->assertSame($version + 1, $template->fresh()->version);
    }

    public function test_standard_restroom_checklists_keep_their_existing_mode_and_settings(): void
    {
        $template = ChecklistTemplate::updateOrCreate(['slug' => 'restroom'], [
            'name' => 'Custom restroom checklist',
            'version' => 1,
            'settings' => ['validation_mode' => 'yes_no_na', 'instructions' => 'Inspect daily.'],
            'is_active' => true,
        ]);
        $before = $template->fresh()->getRawOriginal();
        $migration = require database_path('migrations/2026_09_19_000100_update_utilities_checklist_schedule.php');
        $migration->up();
        $this->assertSame($before, $template->fresh()->getRawOriginal());
    }
}
