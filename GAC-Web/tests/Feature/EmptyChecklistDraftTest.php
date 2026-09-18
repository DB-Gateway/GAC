<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EmptyChecklistDraftTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ChecklistTemplateSeeder::class);
        Sanctum::actingAs(User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
            'account_status' => 'active',
        ]));
    }

    public function test_empty_response_does_not_create_a_draft(): void
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        $response = $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-09-12',
            'responses' => [['item_key' => $item->key, 'status' => null, 'details' => ['client_time' => '2026-09-12T08:15:00']]],
        ])->assertOk()->assertJsonPath('submission.status', 'not_started');

        // The mobile parser expects an object keyed by item, even when empty.
        $this->assertIsObject(json_decode($response->getContent())->submission->responses);

        $this->assertDatabaseCount('checklist_submissions', 0);
        $this->assertDatabaseCount('checklist_responses', 0);
    }

    public function test_undoing_the_last_saved_answer_removes_the_draft_and_resets_catalog(): void
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        $endpoint = route('api.checklists.save-draft', $template);
        $this->postJson($endpoint, [
            'date' => '2026-09-12',
            'responses' => [['item_key' => $item->key, 'status' => 'yes']],
        ])->assertCreated();

        $this->postJson($endpoint, [
            'date' => '2026-09-12',
            'responses' => [['item_key' => $item->key, 'status' => null]],
        ])->assertOk()->assertJsonPath('submission.status', 'not_started')
            ->assertJsonPath('submission.scores.answered', 0)
            ->assertJsonCount(0, 'submission.responses');

        $this->assertDatabaseCount('checklist_submissions', 0);
        $this->assertDatabaseCount('checklist_responses', 0);
        $this->getJson(route('api.checklists.show', ['template' => $template, 'date' => '2026-09-12']))
            ->assertOk()->assertJsonPath('submission', null);
        $catalog = $this->getJson(route('api.checklists.index', ['date' => '2026-09-12']))->assertOk();
        $this->assertNull(collect($catalog->json('checklists'))->firstWhere('slug', 'sales')['submission']);
    }

    public function test_clearing_one_answer_preserves_saved_answers_outside_the_request(): void
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $items = $template->items()->take(2)->get();
        $endpoint = route('api.checklists.save-draft', $template);
        $this->postJson($endpoint, [
            'date' => '2026-09-12',
            'responses' => $items->map(fn ($item) => ['item_key' => $item->key, 'status' => 'yes'])->all(),
        ])->assertCreated();

        $this->postJson($endpoint, [
            'date' => '2026-09-12',
            'responses' => [['item_key' => $items[0]->key, 'status' => null]],
        ])->assertOk()->assertJsonPath('submission.status', 'draft')
            ->assertJsonPath("submission.responses.{$items[0]->key}.status", null)
            ->assertJsonPath("submission.responses.{$items[1]->key}.status", 'yes');
        $this->assertDatabaseCount('checklist_submissions', 1);
    }

    public function test_partial_notes_are_retained_as_draft_content(): void
    {
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-09-12',
            'responses' => [['item_key' => $item->key, 'status' => null, 'remark' => 'Inspection in progress']],
        ])->assertCreated()->assertJsonPath('submission.status', 'draft');
        $this->assertDatabaseCount('checklist_submissions', 1);
    }
}
