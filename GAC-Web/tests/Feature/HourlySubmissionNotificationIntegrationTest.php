<?php

namespace Tests\Feature;

use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use App\Notifications\PicTaskCompleted;
use App\Services\DraftFollowUpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HourlySubmissionNotificationIntegrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_submitting_hourly_inspections_sends_notifications_to_gm_and_bom_and_updates_daily_submission(): void
    {
        $branch = 'Pasong Tamo';

        $gm = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'branch' => $branch,
            'account_status' => 'active',
        ]);

        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => $branch,
            'account_status' => 'active',
        ]);

        $utilitiesPic = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $branch,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $items = $template->items()->orderBy('sort_order')->get();
        $auditDate = '2026-09-11';

        // 1. Submit 08:00 inspection
        $responses08 = $items->map(function ($item, int $index): array {
            return [
                'item_id' => $item->id,
                'status' => 'yes',
                'details' => [
                    'slots' => ['08:00' => 'good'],
                    'submitted_slots' => ['08:00'],
                ],
            ];
        })->all();

        $res08 = $this->actingAs($utilitiesPic)
            ->withHeader('X-Client-Time', '2026-09-11 08:15:00')
            ->postJson(route('checklists.submit', $template), [
                'date' => $auditDate,
                'branch' => $branch,
                'responses' => $responses08,
            ]);

        $res08->assertStatus(201);
        $this->assertDatabaseCount('checklist_submissions', 1);

        $submission = ChecklistSubmission::firstOrFail();
        $this->assertSame('submitted', $submission->status);
        $this->assertSame(1, Report::where('checklist_submission_id', $submission->id)->count());

        // Verify GM and BOM received the 08:00 notification
        $gmNotifications = $gm->notifications()->where('type', PicTaskCompleted::class)->get();
        $bomNotifications = $bom->notifications()->where('type', PicTaskCompleted::class)->get();
        $this->assertCount(1, $gmNotifications);
        $this->assertCount(1, $bomNotifications);
        $this->assertSame('Utilities 5S checklist submitted', $gmNotifications->first()->data['title']);

        // Verify DraftFollowUpService does not see submitted checklist as an unfinished draft
        /** @var DraftFollowUpService $draftService */
        $draftService = app(DraftFollowUpService::class)->pendingDrafts($gm);
        $this->assertTrue($draftService->isEmpty());

        // 2. Submit 09:00 inspection on the same day
        $responses09 = $items->map(function ($item, int $index): array {
            return [
                'item_id' => $item->id,
                'status' => 'yes',
                'details' => [
                    'slots' => [
                        '08:00' => 'good',
                        '09:00' => 'good',
                    ],
                    'submitted_slots' => ['08:00', '09:00'],
                ],
            ];
        })->all();

        $res09 = $this->actingAs($utilitiesPic)
            ->withHeader('X-Client-Time', '2026-09-11 09:15:00')
            ->postJson(route('checklists.submit', $template), [
                'date' => $auditDate,
                'branch' => $branch,
                'responses' => $responses09,
            ]);

        $res09->assertStatus(201);

        // Still only 1 submission row (continuous daily sheet) and 1 report
        $this->assertDatabaseCount('checklist_submissions', 1);
        $this->assertSame(1, Report::where('checklist_submission_id', $submission->id)->count());

        // GM and BOM received the 09:00 notification (total 2 notifications each)
        $this->assertCount(2, $gm->notifications()->where('type', PicTaskCompleted::class)->get());
        $this->assertCount(2, $bom->notifications()->where('type', PicTaskCompleted::class)->get());
    }
}

