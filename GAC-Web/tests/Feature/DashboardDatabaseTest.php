<?php

namespace Tests\Feature;

use App\Models\ChecklistResponse;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardDatabaseTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-08-29 10:00:00');
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_dashboard_metrics_are_calculated_from_visible_database_submissions(): void
    {
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $ownAuditor = User::factory()->create(['branch' => 'Pasong Tamo', 'user_type' => 'PIC']);
        $otherAuditor = User::factory()->create(['branch' => 'Cebu', 'user_type' => 'PIC']);
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $pic = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'account_status' => 'active',
        ]);

        $this->createSubmission($template, $ownAuditor, 'Pasong Tamo', 'submitted', 9, 1, 'no');
        $this->createSubmission($template, $otherAuditor, 'Cebu', 'submitted', 8, 2, 'yes');
        $this->createSubmission($template, $ownAuditor, 'Pasong Tamo', 'draft', 1, 0, 'yes');

        $adminPage = $this->actingAs($administrator)->get(route('dashboard'));

        $adminPage
            ->assertOk()
            ->assertViewIs('dashboard')
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['overall_compliance'] === 85.0
                && $summary['dos_completed'] === 2
                && $summary['pending_audits'] === 1
                && $summary['critical_findings'] === 1)
            ->assertViewHas('monthlyTrend', fn ($trend): bool => $trend->last()['score'] === 85.0
                && $trend->last()['count'] === 2)
            ->assertViewHas('branchRankings', fn ($rankings): bool => $rankings->pluck('branch')->all() === ['Pasong Tamo', 'Cebu'])
            ->assertViewHas('notifications', fn ($notifications): bool => $notifications->count() === 2)
            ->assertDontSee('id="notificationsBadge"', false)
            ->assertDontSee('Juan Dela Cruz')
            ->assertDontSee('Sucat');

        $branchPage = $this->actingAs($pic)->get(route('dashboard'));

        $branchPage
            ->assertOk()
            ->assertViewHas('dashboardScope', 'Pasong Tamo')
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['overall_compliance'] === 90.0
                && $summary['dos_completed'] === 1
                && $summary['pending_audits'] === 1
                && $summary['critical_findings'] === 1)
            ->assertViewHas('branchRankings', fn ($rankings): bool => $rankings->count() === 1
                && $rankings->first()['branch'] === 'Pasong Tamo')
            ->assertDontSee('Cebu');
    }

    public function test_empty_database_displays_real_empty_dashboard_state(): void
    {
        $administrator = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $this->actingAs($administrator)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['overall_compliance'] === null
                && $summary['dos_completed'] === 0
                && $summary['pending_audits'] === 0
                && $summary['critical_findings'] === 0)
            ->assertViewHas('dosCategories', fn ($categories): bool => $categories->isEmpty())
            ->assertViewHas('recentActivities', fn ($activities): bool => $activities->isEmpty())
            ->assertViewHas('branchRankings', fn ($rankings): bool => $rankings->isEmpty())
            ->assertViewHas('notifications', fn ($notifications): bool => $notifications->isEmpty())
            ->assertSee('NO RECORDED AUDIT')
            ->assertSee('No active audit alerts');
    }

    private function createSubmission(
        ChecklistTemplate $template,
        User $user,
        string $branch,
        string $status,
        int $yes,
        int $no,
        string $responseStatus
    ): ChecklistSubmission {
        $answered = $yes + $no;
        $submission = ChecklistSubmission::create([
            'checklist_template_id' => $template->id,
            'user_id' => $user->id,
            'submitted_by_user_id' => $status === 'submitted' ? $user->id : null,
            'status' => $status,
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => '2026-08-15',
            'template_version' => $template->version,
            'context' => ['auditor' => $user->name, 'branch' => $branch],
            'template_snapshot' => ['slug' => $template->slug, 'name' => $template->name],
            'scores' => [
                'total' => $answered,
                'answered' => $answered,
                'yes' => $yes,
                'no' => $no,
                'na' => 0,
                'applicable' => $answered,
                'percentage' => round(($yes / $answered) * 100, 2),
            ],
            'submitted_at' => $status === 'submitted' ? now() : null,
        ]);
        $item = $template->items()->with('section')->firstOrFail();

        ChecklistResponse::create([
            'checklist_submission_id' => $submission->id,
            'checklist_item_id' => $item->id,
            'item_key' => $item->key,
            'status' => $responseStatus,
            'item_snapshot' => [
                'key' => $item->key,
                'prompt' => $item->prompt,
                'section' => [
                    'title' => $item->section->title,
                    'sort_order' => $item->section->sort_order,
                ],
            ],
        ]);

        return $submission;
    }
}
