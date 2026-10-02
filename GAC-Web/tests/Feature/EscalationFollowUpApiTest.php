<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use App\Notifications\EscalationFollowUpSubmitted;
use App\Notifications\FindingEscalated;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Testing\File;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EscalationFollowUpApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_preset_follow_up_is_saved_and_visible_to_the_original_manager(): void
    {
        [$checker, $manager, $finding, $notification] = $this->escalation();
        Sanctum::actingAs($checker);
        $this->postJson($this->url($notification), $this->payload() + ['remarks' => 'Discard stale custom text'])
            ->assertCreated()
            ->assertJsonPath('follow_up.remarks', 'Corrective action in progress')
            ->assertJsonPath('follow_up.recipient_name', 'Brenda BOM');

        $report = Report::where('type', 'escalation_follow_up')->sole();
        $this->assertSame($finding->id, $report->data_snapshot['response_id']);
        $this->assertSame([], $report->data_snapshot['photos']);
        $this->assertSame('no', $finding->fresh()->status);
        $this->assertSame('The sign is damaged.', $finding->fresh()->finding);
        $notice = $manager->notifications()->where('type', EscalationFollowUpSubmitted::class)->sole();
        $this->assertSame($checker->id, $notice->data['sender_user_id']);
        $this->assertSame('Corrective action in progress', $notice->data['remarks']);
        $this->assertTrue(app(NotificationService::class)->getTaskNotificationData($manager)['taskNotifications']->contains('id', $notice->id));

        $this->actingAs($manager)
            ->get(route('notifications.push.open', $notice->id))
            ->assertRedirect(route('notifications.view-task', $notice->id));

        $redirect = $this->get(route('notifications.view-task', $notice->id))->assertRedirect();
        $location = $redirect->headers->get('Location');
        parse_str((string) parse_url((string) $location, PHP_URL_QUERY), $query);
        $this->assertSame('follow-up', $query['tab'] ?? null);
        $this->assertSame((string) $finding->id, $query['follow_up_response_id'] ?? null);
        $this->get($location)
            ->assertOk()
            ->assertViewHas('activeTab', 'follow-up')
            ->assertSee('data-follow-up-highlight', false)
            ->assertSee('A follow-up update was submitted for the highlighted finding.');
    }

    public function test_other_remarks_and_camera_photos_survive_retries_without_duplicate_reports(): void
    {
        Storage::fake('public');
        [$checker, $manager, , $notification] = $this->escalation();
        Sanctum::actingAs($checker);
        $payload = array_merge($this->payload(), [
            'remark_option' => 'others', 'remarks' => '  Contractor confirmed tomorrow.  ',
            'photos' => [$this->photo('camera.png'), $this->photo('camera-2.png')],
        ]);
        $first = $this->postJson($this->url($notification), $payload)->assertCreated();
        $this->postJson($this->url($notification), $payload)->assertOk()
            ->assertJsonPath('follow_up.id', $first->json('follow_up.id'));
        $this->assertSame(1, Report::where('type', 'escalation_follow_up')->count());
        $notice = $manager->notifications()->where('type', EscalationFollowUpSubmitted::class)->sole();
        $this->assertSame('Contractor confirmed tomorrow.', $notice->data['remarks']);
        $this->assertCount(2, $notice->data['photos']);
        foreach ($notice->data['photos'] as $photo) {
            Storage::disk('public')->assertExists($photo['path']);
        }
        $this->assertCount(2, Storage::disk('public')->allFiles());

        $html = view('partials.task-notifications-list', ['activeTaskNotifications' => collect([$notice])])->render();
        $this->assertStringContainsString('Contractor confirmed tomorrow.', $html);
        $this->assertStringContainsString('View photo 1', $html);
        $this->assertStringContainsString('View photo 2', $html);
        $history = view('partials.task-notification-history', ['historicalTaskNotifications' => collect([$notice])])->render();
        $this->assertStringContainsString('View photo 2', $history);
    }

    public function test_blank_custom_remarks_invalid_presets_and_non_photos_are_rejected(): void
    {
        Storage::fake('public');
        [$checker, $manager, , $notification] = $this->escalation();
        Sanctum::actingAs($checker);
        foreach ([null, '', '   '] as $remarks) {
            $this->postJson($this->url($notification), array_merge($this->payload(), ['remark_option' => 'others', 'remarks' => $remarks]))
                ->assertUnprocessable()->assertJsonValidationErrors('remarks');
        }
        $this->postJson($this->url($notification), ['request_id' => str_repeat('a', 32)])
            ->assertUnprocessable()->assertJsonValidationErrors('remark_option');
        $this->postJson($this->url($notification), array_merge($this->payload(), ['remark_option' => 'anything']))
            ->assertUnprocessable()->assertJsonValidationErrors('remark_option');
        $this->postJson($this->url($notification), $this->payload() + ['photos' => [UploadedFile::fake()->create('report.pdf', 10, 'application/pdf')]])
            ->assertUnprocessable()->assertJsonValidationErrors('photos.0');
        $this->postJson($this->url($notification), $this->payload() + ['photos' => [$this->photo('large.png')->size(10241)]])
            ->assertUnprocessable()->assertJsonValidationErrors('photos.0');
        $this->postJson($this->url($notification), $this->payload() + ['photos' => array_map(fn ($i) => $this->photo("photo-$i.png"), range(1, 4))])
            ->assertUnprocessable()->assertJsonValidationErrors('photos');
        $this->assertSame(0, Report::where('type', 'escalation_follow_up')->count());
        $this->assertCount(0, Storage::disk('public')->allFiles());
        $this->assertSame(0, $manager->notifications()->count());
    }

    public function test_other_accounts_and_read_only_notification_tokens_cannot_submit(): void
    {
        [$checker, , , $notification] = $this->escalation();
        $this->postJson($this->url($notification), $this->payload())->assertUnauthorized();
        $deviceToken = $checker->createToken('notifications:test', ['notifications:read'])->plainTextToken;
        $this->withToken($deviceToken)->postJson($this->url($notification), $this->payload())->assertForbidden();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson($this->url($notification), $this->payload())->assertNotFound();
        $this->assertSame(0, Report::where('type', 'escalation_follow_up')->count());
    }

    public function test_changed_branch_or_unavailable_manager_cannot_receive_a_misrouted_follow_up(): void
    {
        [$checker, $manager, , $notification] = $this->escalation();
        Sanctum::actingAs($checker);
        $checker->update(['branch' => 'Cebu']);
        $this->postJson($this->url($notification), $this->payload())->assertForbidden();
        $checker->update(['branch' => 'Pasong Tamo']);
        $manager->update(['account_status' => 'inactive']);
        $this->postJson($this->url($notification), $this->payload())->assertUnprocessable();
        $this->assertSame(0, Report::where('type', 'escalation_follow_up')->count());
    }

    public function test_subsequent_follow_up_with_different_request_id_is_rejected_and_notification_marks_has_follow_up(): void
    {
        [$checker, , , $notification] = $this->escalation();
        Sanctum::actingAs($checker);

        // First submission succeeds
        $this->postJson($this->url($notification), $this->payload())
            ->assertCreated();

        // Notification data has been updated
        $notifRecord = $checker->notifications()->whereKey($notification)->first();
        $this->assertTrue(data_get($notifRecord->data, 'has_follow_up'));
        $this->assertNotNull(data_get($notifRecord->data, 'follow_up_submitted_at'));

        // API endpoint /notifications returns has_follow_up = true
        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('notifications.0.data.has_follow_up', true);

        // Retry with same request_id is accepted as idempotent retry
        $this->postJson($this->url($notification), $this->payload())
            ->assertOk();

        // Attempting another follow-up with a NEW request_id is rejected with 409 Conflict
        $differentRequestId = str_repeat('b', 32);
        $this->postJson($this->url($notification), array_merge($this->payload(), ['request_id' => $differentRequestId]))
            ->assertStatus(409);

        $this->assertSame(1, Report::where('type', 'escalation_follow_up')->count());
    }

    public function test_non_utility_user_cannot_submit_follow_up(): void
    {
        $salesManager = User::factory()->create(['user_type' => User::ROLE_SALES_MANAGER, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $manager = User::factory()->create(['name' => 'Brenda BOM', 'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $template = ChecklistTemplate::firstOrCreate(['slug' => 'dealer-operations-standards-sales'], ['name' => 'Sales Standards', 'version' => 1, 'is_active' => true]);
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id, 'user_id' => $salesManager->id,
            'status' => 'submitted', 'branch' => $salesManager->branch, 'scope_key' => hash('sha256', $salesManager->branch),
            'audit_date' => '2026-09-14', 'template_version' => 1,
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
        ]);
        $finding = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id, 'item_key' => 'sales-2', 'status' => 'no',
            'finding' => 'The sign is damaged.', 'action_plan' => 'Replace the sign.',
            'item_snapshot' => ['prompt' => 'Is the signage in good condition?'],
        ]);
        $salesManager->notify(new FindingEscalated($finding, $manager));
        $notificationId = $salesManager->notifications()->sole()->id;

        Sanctum::actingAs($salesManager);
        $this->postJson($this->url($notificationId), $this->payload())
            ->assertForbidden()
            ->assertJsonPath('message', 'Only utility personnel can submit an escalation follow-up.');
        $this->assertSame(0, Report::where('type', 'escalation_follow_up')->count());
    }

    public function test_utility_follow_up_marks_other_branch_users_notifications_as_followed_up(): void
    {
        $salesManager = User::factory()->create(['user_type' => User::ROLE_SALES_MANAGER, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $utilityUser = User::factory()->create(['user_type' => User::ROLE_5S_UTILITIES, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $manager = User::factory()->create(['name' => 'Brenda BOM', 'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $template = ChecklistTemplate::firstOrCreate(['slug' => 'dealer-operations-standards-sales'], ['name' => 'Sales Standards', 'version' => 1, 'is_active' => true]);
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id, 'user_id' => $salesManager->id,
            'status' => 'submitted', 'branch' => $salesManager->branch, 'scope_key' => hash('sha256', $salesManager->branch),
            'audit_date' => '2026-09-14', 'template_version' => 1,
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
        ]);
        $finding = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id, 'item_key' => 'sales-2', 'status' => 'no',
            'finding' => 'The sign is damaged.', 'action_plan' => 'Replace the sign.',
            'item_snapshot' => ['prompt' => 'Is the signage in good condition?'],
        ]);
        $salesManager->notify(new FindingEscalated($finding, $manager));
        $utilityUser->notify(new FindingEscalated($finding, $manager));

        // Before follow-up: sales manager notification shows has_follow_up = false
        Sanctum::actingAs($salesManager);
        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('notifications.0.data.has_follow_up', false);

        // Utility user submits follow-up
        Sanctum::actingAs($utilityUser);
        $this->postJson($this->url($utilityUser->notifications()->sole()->id), $this->payload())
            ->assertCreated();

        // After follow-up: sales manager notification now shows has_follow_up = true
        Sanctum::actingAs($salesManager);
        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonPath('notifications.0.data.has_follow_up', true);
    }

    private function escalation(): array
    {
        $checker = User::factory()->create(['user_type' => User::ROLE_5S_UTILITIES, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $manager = User::factory()->create(['name' => 'Brenda BOM', 'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER, 'branch' => 'Pasong Tamo', 'account_status' => 'active']);
        $template = ChecklistTemplate::firstOrCreate(['slug' => 'dealer-operations-standards-sales'], ['name' => 'Sales Standards', 'version' => 1, 'is_active' => true]);
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id, 'user_id' => $checker->id,
            'status' => 'submitted', 'branch' => $checker->branch, 'scope_key' => hash('sha256', $checker->branch),
            'audit_date' => '2026-09-14', 'template_version' => 1,
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
        ]);
        $finding = ChecklistResponse::create([
            'checklist_submission_id' => $submission->id, 'item_key' => 'sales-2', 'status' => 'no',
            'finding' => 'The sign is damaged.', 'action_plan' => 'Replace the sign.',
            'item_snapshot' => ['prompt' => 'Is the signage in good condition?'],
        ]);
        $checker->notify(new FindingEscalated($finding, $manager));

        return [$checker, $manager, $finding, $checker->notifications()->sole()->id];
    }

    private function url(string $notification): string
    {
        return '/api/notifications/'.$notification.'/follow-ups';
    }

    private function payload(): array
    {
        return ['request_id' => str_repeat('a', 32), 'remark_option' => 'in_progress'];
    }

    private function photo(string $filename): File
    {
        return UploadedFile::fake()->createWithContent($filename, base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aDa8AAAAASUVORK5CYII='
        ));
    }
}
