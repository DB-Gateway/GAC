<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RestroomChecklistQuestionToggleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_administrator_can_toggle_restroom_question_inclusion(): void
    {
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $template = ChecklistTemplate::query()->where('slug', 'restroom')->firstOrFail();
        $item = $template->items()->firstOrFail();

        // Admin toggles question OUT (inactive)
        $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $item->key,
                'is_active' => false,
            ])
            ->assertOk()
            ->assertJsonPath('item.key', $item->key)
            ->assertJsonPath('item.is_active', false);

        $this->assertFalse((bool) $item->fresh()->is_active);

        // Admin toggles question back IN (active)
        $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $item->key,
                'is_active' => true,
            ])
            ->assertOk()
            ->assertJsonPath('item.key', $item->key)
            ->assertJsonPath('item.is_active', true);

        $this->assertTrue((bool) $item->fresh()->is_active);
    }

    public function test_non_administrative_user_cannot_toggle_questions(): void
    {
        $utilityUser = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $template = ChecklistTemplate::query()->where('slug', 'restroom')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $this->actingAs($utilityUser)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $item->key,
                'is_active' => false,
            ])
            ->assertForbidden();

        $this->assertTrue((bool) $item->fresh()->is_active);
    }

    public function test_unchecked_question_is_hidden_from_utilities_user_but_visible_to_admin(): void
    {
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $utilityUser = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $template = ChecklistTemplate::query()->where('slug', 'restroom')->firstOrFail();
        $items = $template->items()->get();
        $firstItem = $items->first();
        $secondItem = $items->skip(1)->first();

        // Admin unchecks the first question
        $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $firstItem->key,
                'is_active' => false,
            ])
            ->assertOk();

        // 1. When Utilities user loads the checklist, the unchecked question is NOT included
        $userResponse = $this->actingAs($utilityUser)
            ->getJson(route('checklists.load', [
                'template' => $template,
                'date' => now()->toDateString(),
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk();

        $userItemKeys = collect($userResponse->json('template.sections'))
            ->flatMap(fn ($section) => $section['items'])
            ->pluck('key')
            ->all();

        $this->assertNotContains($firstItem->key, $userItemKeys);
        $this->assertContains($secondItem->key, $userItemKeys);

        // 2. When Admin loads the checklist, all questions are loaded including the unchecked one
        $adminResponse = $this->actingAs($admin)
            ->getJson(route('checklists.load', [
                'template' => $template,
                'date' => now()->toDateString(),
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk();

        $adminItems = collect($adminResponse->json('template.sections'))
            ->flatMap(fn ($section) => $section['items'])
            ->keyBy('key');

        $this->assertTrue($adminItems->has($firstItem->key));
        $this->assertFalse($adminItems->get($firstItem->key)['is_active']);
        $this->assertTrue($adminItems->has($secondItem->key));
        $this->assertTrue($adminItems->get($secondItem->key)['is_active']);

        // 3. Admin re-checks the question
        $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $firstItem->key,
                'is_active' => true,
            ])
            ->assertOk();

        // Utilities user now sees the question again
        $userResponseAfter = $this->actingAs($utilityUser)
            ->getJson(route('checklists.load', [
                'template' => $template,
                'date' => now()->toDateString(),
                'branch' => 'Pasong Tamo',
            ]))
            ->assertOk();

        $userItemKeysAfter = collect($userResponseAfter->json('template.sections'))
            ->flatMap(fn ($section) => $section['items'])
            ->pluck('key')
            ->all();

        $this->assertContains($firstItem->key, $userItemKeysAfter);
    }

    public function test_administrator_can_toggle_hourly_slot_for_restroom_question(): void
    {
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $template = ChecklistTemplate::query()->where('slug', 'restroom')->firstOrFail();
        $item = $template->items()->firstOrFail();

        // 1. Admin turns OFF 08:00
        $response = $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $item->key,
                'slot' => '08:00',
                'is_active' => false,
            ])
            ->assertOk()
            ->assertJsonPath('item.key', $item->key);

        $activeSlots = $response->json('item.active_slots');
        $this->assertIsArray($activeSlots);
        $this->assertNotContains('08:00', $activeSlots);
        $this->assertContains('09:00', $activeSlots);

        $updatedMetadata = $item->fresh()->metadata;
        $this->assertNotContains('08:00', $updatedMetadata['active_slots'] ?? []);

        // 2. Admin turns 08:00 back ON
        $response2 = $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $item->key,
                'slot' => '08:00',
                'is_active' => true,
            ])
            ->assertOk();

        $activeSlots2 = $response2->json('item.active_slots');
        $this->assertContains('08:00', $activeSlots2);
        $this->assertContains('09:00', $activeSlots2);
    }

    public function test_disabled_hourly_slot_is_not_required_in_submission(): void
    {
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $utilityUser = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $template = ChecklistTemplate::query()->where('slug', 'restroom')->firstOrFail();
        $items = $template->items()->get();
        $firstItem = $items->first();

        // Admin turns OFF 08:00 for the first item
        $this->actingAs($admin)
            ->postJson(route('checklists.item.toggle', $template), [
                'key' => $firstItem->key,
                'slot' => '08:00',
                'is_active' => false,
            ])
            ->assertOk();

        $yesterday = now()->subDay()->toDateString();

        // Prepare responses where 08:00 is omitted for first item, but all other slots are filled
        $timeSlots = collect($template->settings['time_slots'])->map(fn ($s) => is_array($s) ? $s['key'] : $s)->all();
        $otherSlots = array_values(array_filter($timeSlots, fn ($s) => $s !== '08:00'));

        $responses = [];
        foreach ($items as $item) {
            $slots = [];
            $slotsToFill = ($item->key === $firstItem->key) ? $otherSlots : $timeSlots;
            foreach ($slotsToFill as $slot) {
                $slots[$slot] = 'good';
            }
            $responses[] = [
                'item_key' => $item->key,
                'details' => ['slots' => $slots],
            ];
        }

        // Submitting with omitted 08:00 should succeed for first item
        $submitResponse = $this->actingAs($utilityUser)
            ->postJson(route('checklists.submit', $template), [
                'date' => $yesterday,
                'branch' => 'Pasong Tamo',
                'responses' => $responses,
            ])
            ->assertCreated();

        $this->assertEquals('submitted', $submitResponse->json('submission.status'));
    }
}
