<?php

namespace Tests\Feature;

use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use App\Services\UtilitiesInspectionService;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UtilitiesInspectionDeadlineTest extends TestCase
{
    use RefreshDatabase;

    private User $utility;
    private ChecklistTemplate $template;

    protected function setUp(): void
    {
        parent::setUp();
        $this->utility = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES, 'branch' => 'Cebu', 'account_status' => 'active',
            'created_at' => CarbonImmutable::parse('2026-09-19 07:00', 'Asia/Manila')->utc(),
        ]);
        $this->template = ChecklistTemplate::updateOrCreate(['slug' => 'restroom'], [
            'slug' => 'restroom', 'name' => '5S Utilities', 'version' => 1, 'is_active' => true,
            'settings' => ['validation_mode' => 'time_slots', 'time_slots' => [
                ['key' => '08:00', 'label' => '8 AM'], ['key' => '11:00', 'label' => '11 AM'],
            ]],
        ]);
        $this->template->sections()->delete();
        $section = $this->template->sections()->create([
            'key' => 'hygiene', 'title' => 'Hygiene', 'sort_order' => 1, 'is_active' => true,
        ]);
        foreach (['mirror', 'sink'] as $index => $key) {
            $section->items()->create([
                'checklist_template_id' => $this->template->id, 'key' => $key,
                'prompt' => $key.' clean?', 'sort_order' => $index, 'is_active' => true,
            ]);
        }
    }

    private function sync(string $time): void
    {
        app(UtilitiesInspectionService::class)->sync($this->utility, CarbonImmutable::parse('2026-09-19 '.$time, 'Asia/Manila'));
    }

    private function sheet(string $status, array $details): ChecklistSubmission
    {
        $sheet = ChecklistSubmission::create([
            'checklist_template_id' => $this->template->id, 'user_id' => $this->utility->id,
            'branch' => 'Cebu', 'scope_key' => hash('sha256', 'cebu'), 'audit_date' => '2026-09-19',
            'template_version' => 1, 'status' => $status,
            'template_snapshot' => [],
        ]);
        foreach ($this->template->items as $item) {
            $sheet->responses()->create([
                'checklist_item_id' => $item->id, 'item_key' => $item->key,
                'details' => $details, 'remark' => 'Keep this note',
                'item_snapshot' => [],
                'action_plan' => 'Keep this plan', 'attachment_path' => 'attachments/photo.jpg',
            ]);
        }

        return $sheet;
    }

    public function test_reminders_at_850_and_900_then_missed_at_901_are_idempotent_and_reach_both_managers(): void
    {
        $gm = User::factory()->create(['user_type' => 'GM', 'branch' => 'Cebu', 'account_status' => 'active']);
        $bom = User::factory()->create(['user_type' => 'BOM', 'branch' => 'Cebu', 'account_status' => 'active']);
        $otherBom = User::factory()->create(['user_type' => 'BOM', 'branch' => 'Manila', 'account_status' => 'active']);
        $otherGm = User::factory()->create(['user_type' => 'GM', 'branch' => 'Manila', 'account_status' => 'active']);
        $this->sync('08:49:59');
        $this->assertSame(0, $this->utility->notifications()->count());
        $this->sync('08:50:00');
        $this->sync('08:50:15');
        $this->assertSame('utilities_due_soon', $this->utility->notifications()->sole()->data['event']);
        $this->sync('09:00:00');
        $this->sync('09:00:59');
        $this->assertSame(2, $this->utility->notifications()->count());
        $this->assertDatabaseCount('checklist_submissions', 0);
        $this->sync('09:01:00');
        $this->sync('09:02:00');
        $this->assertSame(3, $this->utility->notifications()->count());
        $this->assertDatabaseCount('checklist_submissions', 1);
        $this->assertDatabaseCount('reports', 1);
        foreach ([$gm, $bom] as $manager) {
            $notice = $manager->notifications()->sole();
            $this->assertSame('utilities_inspection_missed', $notice->data['event']);
            $this->assertSame(['08:00'], $notice->data['missed_slots']);
            $this->assertStringContainsString('failed checklist', $notice->data['message']);
        }
        $this->assertSame(0, $otherBom->notifications()->count());
        $this->assertSame(0, $otherGm->notifications()->count());
        foreach (ChecklistSubmission::sole()->responses as $response) {
            $this->assertSame(['08:00' => 'not_good'], $response->details['slots']);
            $this->assertSame(['08:00'], $response->details['submitted_slots']);
        }
    }

    public function test_submitted_inspection_gets_no_reminder_or_failure(): void
    {
        $this->sheet('submitted', ['slots' => ['08:00' => 'good'], 'submitted_slots' => ['08:00']]);
        foreach (['08:50', '09:00', '09:01'] as $time) {
            $this->sync($time);
        }
        $this->assertSame(0, $this->utility->notifications()->count());
        $this->assertDatabaseCount('reports', 0);
        $this->assertSame('good', ChecklistSubmission::sole()->responses->first()->details['slots']['08:00']);
    }

    public function test_draft_answers_are_not_submission_and_fail_without_erasing_other_details(): void
    {
        $this->sheet('draft', ['slots' => ['08:00' => 'good', '11:00' => 'good'], 'submitted_slots' => [], 'custom' => 'keep']);
        // A catch-up while another window is open must not require that window.
        $this->sync('11:30');
        foreach (ChecklistSubmission::sole()->responses as $response) {
            $this->assertSame('not_good', $response->details['slots']['08:00']);
            $this->assertSame('good', $response->details['slots']['11:00']);
            $this->assertSame('keep', $response->details['custom']);
            $this->assertSame('Keep this note', $response->remark);
            $this->assertSame('Keep this plan', $response->action_plan);
            $this->assertSame('attachments/photo.jpg', $response->attachment_path);
        }
        $this->sync('12:01');
        $this->assertDatabaseCount('checklist_submissions', 1);
        $this->assertDatabaseCount('reports', 1);
        $this->assertSame(2, $this->utility->notifications()->count());
    }

    public function test_completed_earlier_slot_is_preserved_when_next_slot_is_missed(): void
    {
        $this->sheet('submitted', ['slots' => ['08:00' => 'good'], 'submitted_slots' => ['08:00']]);
        $this->sync('12:01');
        foreach (ChecklistSubmission::sole()->responses as $response) {
            $this->assertSame(['08:00' => 'good', '11:00' => 'not_good'], $response->details['slots']);
        }
    }

    public function test_disabled_slots_and_inactive_users_are_ignored(): void
    {
        $this->template->items()->update(['metadata' => ['active_slots' => ['11:00']]]);
        $this->sync('09:01');
        $this->assertDatabaseCount('notifications', 0);
        $this->assertDatabaseCount('checklist_submissions', 0);
        $this->utility->update(['account_status' => 'inactive']);
        $this->sync('12:01');
        $this->assertDatabaseCount('checklist_submissions', 0);
    }

    public function test_non_utilities_roles_are_ignored(): void
    {
        $this->utility->update(['user_type' => User::ROLE_5S_SALES]);
        $this->sync('12:01');
        $this->assertDatabaseCount('notifications', 0);
        $this->assertDatabaseCount('checklist_submissions', 0);
    }

    public function test_accounts_created_after_a_deadline_do_not_inherit_missed_tasks(): void
    {
        $this->utility->forceFill(['created_at' => CarbonImmutable::parse('2026-09-19 09:30', 'Asia/Manila')->utc()])->save();
        $this->sync('09:31');
        $this->assertDatabaseCount('notifications', 0);
        $this->assertDatabaseCount('checklist_submissions', 0);
    }

    public function test_midnight_window_uses_the_inspections_original_audit_date(): void
    {
        $this->utility->forceFill(['created_at' => CarbonImmutable::parse('2026-09-18 07:00', 'Asia/Manila')->utc()])->save();
        $this->template->update(['settings' => ['validation_mode' => 'time_slots', 'time_slots' => ['23:00']]]);
        $this->sync('00:00');
        $this->assertSame('2026-09-18', $this->utility->notifications()->sole()->data['audit_date']);
        $this->sync('00:01');
        $this->assertSame('2026-09-18', ChecklistSubmission::sole()->audit_date->toDateString());
        $this->assertSame('not_good', ChecklistSubmission::sole()->responses->first()->details['slots']['23:00']);
    }

    public function test_mobile_inbox_poll_catches_up_and_returns_a_checklist_deep_link(): void
    {
        $this->travelTo(CarbonImmutable::parse('2026-09-19 08:50', 'Asia/Manila'));
        \Laravel\Sanctum\Sanctum::actingAs($this->utility);
        $this->getJson(route('api.notifications.index'))->assertOk()
            ->assertJsonCount(1, 'notifications')
            ->assertJsonPath('notifications.0.type', 'utilities_due_soon')
            ->assertJsonPath('notifications.0.data.template_slug', 'restroom')
            ->assertJsonPath('notifications.0.data.slot_key', '08:00')
            ->assertJsonPath('notifications.0.data.audit_date', '2026-09-19');
    }

    public function test_failed_checklist_notifies_gm_and_bom_with_compiled_questions_and_displays_as_compiled_row(): void
    {
        $gm = User::factory()->create(['user_type' => 'GM', 'branch' => 'Cebu', 'account_status' => 'active']);
        $bom = User::factory()->create(['user_type' => 'BOM', 'branch' => 'Cebu', 'account_status' => 'active']);

        $this->sync('09:01:00');

        foreach ([$gm, $bom] as $manager) {
            $notice = $manager->notifications()->sole();
            $this->assertSame('utilities_inspection_missed', $notice->data['event']);
            $this->assertTrue($notice->data['is_compiled']);
            $this->assertNotEmpty($notice->data['questions']);
            $this->assertSame(['08:00'], $notice->data['missed_slots']);
        }

        // Check that DashboardController::reportFindings returns 1 compiled row
        $submission = ChecklistSubmission::sole();
        $response = $this->actingAs($bom)->get(route('dashboard', ['tab' => 'follow-up']));
        $response->assertOk();
        $response->assertViewHas('reportFindings', function ($findings) {
            return $findings->count() === 1
                && ($findings->first()['is_compiled'] ?? false) === true
                && ! empty($findings->first()['compiled_questions']);
        });

        // Test that BOM escalating this finding updates the responses and sends 1 compiled notification
        $firstResponse = $submission->responses->first();
        $escalateRes = $this->actingAs($bom)->patchJson(route('reports.responses.escalations'), [
            'responses' => [
                [
                    'id' => $firstResponse->id,
                    'escalation_target' => 'property_management',
                    'action_plan' => 'Fix all restroom facilities immediately.',
                    'commitment_date' => '2026-09-20',
                ],
            ],
        ]);
        $escalateRes->assertOk();

        // Check that the utilities user received 1 compiled notification
        $utilityEscalation = $this->utility->notifications()
            ->where('data->event', 'finding_escalated')
            ->first();
        $this->assertNotNull($utilityEscalation);
        $this->assertTrue($utilityEscalation->data['is_compiled']);
        $this->assertNotEmpty($utilityEscalation->data['questions']);
    }
}
