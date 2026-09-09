<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UnifiedChecklistWorkspaceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_general_manager_can_open_every_checklist_from_the_grouped_editor_sidebar(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response
            ->assertOk()
            ->assertSee('id="editorDropdown"', false)
            ->assertSee('id="editorMenu"', false)
            ->assertSee('Editor')
            ->assertSeeInOrder([
                '5S Checklist',
                'DOS Checklist',
                'Utilities Checklist',
            ]);

        foreach ([
            'sales',
            'service',
            'dealer-operations-standards-sales',
            'dealer-operations-standards',
            'restroom',
        ] as $checklist) {
            $response->assertSee('data-editor-checklist="'.$checklist.'"', false);
            $response->assertSee(
                'href="'.route('checklists.index', ['checklist' => $checklist]).'"',
                false
            );
        }
    }

    public function test_checklist_page_does_not_render_the_old_workspace_header_switcher(): void
    {
        $user = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($user)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertOk()
            ->assertViewIs('checklists.index')
            ->assertSee('id="editorDropdown" open', false)
            ->assertSee('class="sidebar-editor-link active"', false)
            ->assertSee('data-editor-checklist="sales"', false)
            ->assertDontSee('class="checklist-workspace-header"', false)
            ->assertDontSee('aria-label="Select checklist"', false)
            ->assertSee('Edit Master Checklist');
    }

    public function test_legacy_checklist_urls_redirect_to_the_workspace(): void
    {
        $user = User::factory()->create(['account_status' => 'active']);

        $this->actingAs($user)
            ->get(route('checklists.gateway-5s', ['branch' => 'Pasong Tamo', 'date' => '2026-08-29']))
            ->assertRedirect(route('checklists.index', [
                'branch' => 'Pasong Tamo', 'date' => '2026-08-29', 'checklist' => 'sales',
            ]));
    }
}
