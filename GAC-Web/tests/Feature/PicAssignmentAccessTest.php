<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PicAssignmentAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_auth_payload_exposes_the_normalized_pic_assignment(): void
    {
        $user = $this->pic(User::PIC_ASSIGNMENT_UTILITIES);

        $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password',
            'device_name' => 'feature-test',
        ])
            ->assertOk()
            ->assertJsonPath('user.user_type', User::ROLE_PERSON_IN_CHARGE)
            ->assertJsonPath('user.pic_assignment_type', User::PIC_ASSIGNMENT_UTILITIES)
            ->assertJsonPath('user.pic_assignment_label', 'Utilities');
    }

    public function test_api_registration_requires_and_stores_a_pic_assignment(): void
    {
        $basePayload = [
            'name' => 'New Gateway PIC',
            'email' => 'new.gateway.pic@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'branch' => 'Pasong Tamo',
            'position' => 'Person In Charge',
        ];

        $this->postJson('/api/register', $basePayload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('pic_assignment_type');

        $this->postJson('/api/register', $basePayload + [
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
        ])
            ->assertCreated()
            ->assertJsonPath('user.pic_assignment_type', User::PIC_ASSIGNMENT_SALES_SERVICE)
            ->assertJsonPath('user.pic_assignment_label', 'Sales & Service');

        $this->assertDatabaseHas('users', [
            'email' => 'new.gateway.pic@example.com',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
            'account_status' => 'pending',
        ]);
    }

    public function test_catalog_only_returns_the_checklists_assigned_to_each_pic_type(): void
    {
        Sanctum::actingAs($this->pic(User::PIC_ASSIGNMENT_UTILITIES));

        $this->getJson(route('api.checklists.index', ['date' => '2026-09-02']))
            ->assertOk()
            ->assertJsonCount(1, 'checklists')
            ->assertJsonPath('checklists.0.slug', 'restroom')
            ->assertJsonPath('checklists.0.item_count', 30)
            ->assertJsonPath('checklists.0.work_unit_count', 270);

        Sanctum::actingAs($this->pic(User::PIC_ASSIGNMENT_SALES_SERVICE));

        $response = $this->getJson(route('api.checklists.index', ['date' => '2026-09-02']))
            ->assertOk()
            ->assertJsonCount(2, 'checklists');

        $this->assertSame(['sales', 'service'], $response->collect('checklists')->pluck('slug')->all());
        $this->assertSame([41, 33], $response->collect('checklists')->pluck('work_unit_count')->all());
    }

    public function test_catalog_submission_summary_includes_a_stable_issue_count(): void
    {
        $pic = $this->pic(User::PIC_ASSIGNMENT_SALES_SERVICE);
        $template = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $item = $template->items()->firstOrFail();
        Sanctum::actingAs($pic);

        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-09-02',
            'responses' => [[
                'item_id' => $item->id,
                'status' => 'no',
            ]],
        ])->assertCreated();

        $this->getJson(route('api.checklists.index', ['date' => '2026-09-02']))
            ->assertOk()
            ->assertJsonPath('checklists.0.slug', 'sales')
            ->assertJsonPath('checklists.0.submission.issue_count', 1)
            ->assertJsonPath('checklists.0.submission.answered_items', 1)
            ->assertJsonPath('checklists.0.submission.total_items', 41);
    }

    public function test_unauthorized_direct_load_save_submit_and_reset_are_all_forbidden(): void
    {
        $utilities = $this->pic(User::PIC_ASSIGNMENT_UTILITIES);
        $sales = ChecklistTemplate::where('slug', 'sales')->firstOrFail();
        $salesItem = $sales->items()->firstOrFail();
        Sanctum::actingAs($utilities);

        $this->getJson(route('api.checklists.show', [
            'template' => $sales,
            'date' => '2026-09-02',
        ]))->assertForbidden();

        $payload = [
            'date' => '2026-09-02',
            'responses' => [['item_id' => $salesItem->id, 'status' => 'yes']],
        ];
        $this->postJson(route('api.checklists.save-draft', $sales), $payload)->assertForbidden();
        $this->postJson(route('api.checklists.submit', $sales), $payload)->assertForbidden();
        $this->deleteJson(route('api.checklists.reset', $sales), [
            'date' => '2026-09-02',
        ])->assertForbidden();

        $salesService = $this->pic(User::PIC_ASSIGNMENT_SALES_SERVICE);
        $restroom = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        Sanctum::actingAs($salesService);

        $this->getJson(route('api.checklists.show', [
            'template' => $restroom,
            'date' => '2026-09-02',
        ]))->assertForbidden();

        $this->assertDatabaseCount('checklist_submissions', 0);
    }

    public function test_web_workspace_defaults_to_and_only_shows_the_pic_assignment(): void
    {
        $salesService = $this->pic(User::PIC_ASSIGNMENT_SALES_SERVICE);

        $this->actingAs($salesService)
            ->get(route('checklists.index'))
            ->assertOk()
            ->assertViewHas('checklistPage', fn (array $page): bool => $page['title'] === 'Sales Checklist')
            ->assertViewHas('checklistWorkspace', fn (array $workspace): bool => collect($workspace)
                ->pluck('slug')->all() === ['sales', 'service']);

        $this->get(route('checklists.index', ['checklist' => 'restroom']))
            ->assertForbidden();

        $utilities = $this->pic(User::PIC_ASSIGNMENT_UTILITIES);
        $this->actingAs($utilities)
            ->get(route('checklists.index'))
            ->assertOk()
            ->assertViewHas('checklistPage', fn (array $page): bool => $page['title'] === 'Restroom Checklist')
            ->assertViewHas('checklistWorkspace', fn (array $workspace): bool => collect($workspace)
                ->pluck('slug')->all() === ['restroom']);
    }

    private function pic(string $assignment): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => $assignment,
            'account_status' => 'active',
        ]);
    }
}
