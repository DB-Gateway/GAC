<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\DealerChecklistSetting;
use App\Models\User;
use App\Models\UserUsageEvent;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdministratorChecklistAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_only_system_administrator_can_manage_audit_forms(): void
    {
        $template = ChecklistTemplate::query()->where('slug', 'sales')->firstOrFail();

        foreach ([User::ROLE_GENERAL_MANAGER, User::ROLE_BRANCH_OPERATIONS_MANAGER] as $role) {
            $manager = User::factory()->create(['user_type' => $role, 'branch' => 'Pasong Tamo']);

            $this->actingAs($manager)
                ->postJson(route('checklists.template.store'), [
                    'name' => 'Blocked form',
                    'slug' => 'blocked-form-'.$role,
                ])
                ->assertForbidden();
            $this->deleteJson(route('checklists.template.destroy', $template))->assertForbidden();
            $this->postJson(route('debug.checklists.reset-answers'), [])->assertForbidden();
            $this->get(route('dashboard'))
                ->assertOk()
                ->assertDontSee('id="editorDropdown"', false)
                ->assertDontSee('id="debugDropdown"', false);
        }

        $administrator = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);

        $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index'))
            ->assertOk()
            ->assertSee('Dealer / Brand Checklist Availability');

        $this->actingAs($administrator)
            ->deleteJson(route('checklists.template.destroy', $template))
            ->assertOk()
            ->assertJsonPath('message', 'Audit form deleted from active use. Historical submissions and reports were preserved.');

        $this->assertFalse($template->fresh()->is_active);
    }

    public function test_dealer_switch_is_enforced_on_web_and_mobile_without_affecting_other_dealers(): void
    {
        $administrator = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR, 'branch' => null]);
        $pasongSales = User::factory()->create([
            'user_type' => User::ROLE_5S_SALES,
            'branch' => 'Pasong Tamo',
        ]);
        $cebuSales = User::factory()->create([
            'user_type' => User::ROLE_5S_SALES,
            'branch' => 'Cebu',
        ]);

        $availability = collect(DealerChecklistSetting::CATEGORIES)
            ->mapWithKeys(fn (array $definition, string $category): array => [
                $category => $category !== DealerChecklistSetting::CATEGORY_5S_SALES,
            ])
            ->all();

        $this->actingAs($administrator)
            ->patch(route('admin.checklist-access.update', ['dealer' => 'Pasong Tamo']), [
                'availability' => $availability,
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('dealer_checklist_settings', [
            'dealer' => 'Pasong Tamo',
            'category' => DealerChecklistSetting::CATEGORY_5S_SALES,
            'is_enabled' => false,
            'updated_by_user_id' => $administrator->id,
        ]);

        $this->actingAs($pasongSales)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertForbidden();
        $this->actingAs($pasongSales, 'sanctum')
            ->getJson(route('api.checklists.index'))
            ->assertForbidden()
            ->assertJsonPath(
                'message',
                'Your assigned checklist is currently unavailable for your dealer. Contact your system administrator.'
            );

        $this->actingAs($cebuSales)
            ->get(route('checklists.index', ['checklist' => 'sales']))
            ->assertOk();
        $this->actingAs($cebuSales, 'sanctum')
            ->getJson(route('api.checklists.index'))
            ->assertOk()
            ->assertJsonFragment(['slug' => 'sales']);
    }

    public function test_manager_dashboard_switches_only_show_categories_enabled_for_their_branch(): void
    {
        foreach (DealerChecklistSetting::CATEGORIES as $category => $definition) {
            DealerChecklistSetting::query()->create([
                'dealer' => 'Pasong Tamo',
                'category' => $category,
                'is_enabled' => ! in_array($category, [
                    DealerChecklistSetting::CATEGORY_DOS_SALES,
                    DealerChecklistSetting::CATEGORY_5S_UTILITY,
                ], true),
            ]);
        }

        foreach ([User::ROLE_GENERAL_MANAGER, User::ROLE_BRANCH_OPERATIONS_MANAGER] as $role) {
            $manager = User::factory()->create([
                'user_type' => $role,
                'branch' => 'Pasong Tamo',
                'account_status' => 'active',
            ]);

            $this->actingAs($manager)
                ->get(route('dashboard', [
                    'form' => 'five_s',
                    'five_s_area' => 'restroom',
                ]))
                ->assertOk()
                ->assertViewHas('summarySheet', function (array $sheet): bool {
                    return $sheet['summaryFormOptions']->keys()->all() === ['aftersales', 'five_s']
                        && $sheet['fiveSAreaOptions']->keys()->all() === ['sales', 'service']
                        && $sheet['activeForm'] === 'five_s'
                        && $sheet['fiveSArea'] === 'sales';
                })
                ->assertDontSee('Sales Standards (FY25)')
                ->assertSee('Aftersales Standards (FY25)')
                ->assertDontSee('Restroom / Utility');
        }
    }

    public function test_admin_dashboard_defaults_to_web_and_app_user_usage(): void
    {
        $administrator = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR, 'branch' => null]);
        $operator = User::factory()->create(['branch' => 'Pasong Tamo']);

        UserUsageEvent::recordLogin($operator, UserUsageEvent::CHANNEL_WEB);
        UserUsageEvent::recordLogin($operator, UserUsageEvent::CHANNEL_APP);

        $this->actingAs($administrator)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('activeTab', 'users')
            ->assertViewHas('userStats', fn (array $stats): bool => $stats['web_logins_30d'] === 1
                && $stats['app_logins_30d'] === 1
                && $stats['active_users_30d'] === 1)
            ->assertSee('Website &amp; App Usage by User', false)
            ->assertSee('Assign Checklists');
    }

    public function test_successful_web_and_app_logins_are_tracked_separately(): void
    {
        $user = User::factory()->create([
            'email' => 'Usage.Operator',
            'password' => 'password',
            'account_status' => 'active',
        ]);

        $this->post(route('login'), [
            'username' => 'Usage.Operator',
            'password' => 'password',
        ])->assertRedirect();

        $this->postJson('/api/login', [
            'username' => 'Usage.Operator',
            'password' => 'password',
            'device_name' => 'usage-test-app',
        ])->assertOk();

        $this->assertDatabaseHas('user_usage_events', [
            'user_id' => $user->id,
            'channel' => UserUsageEvent::CHANNEL_WEB,
            'event' => 'login',
        ]);
        $this->assertDatabaseHas('user_usage_events', [
            'user_id' => $user->id,
            'channel' => UserUsageEvent::CHANNEL_APP,
            'event' => 'login',
        ]);
    }

    public function test_admin_checklist_access_page_supports_advanced_filters_and_summary_stats(): void
    {
        $administrator = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);

        // Default view
        $response = $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index'));

        $response->assertOk()
            ->assertSee('Dealer / Brand Checklist Availability')
            ->assertSee('Total Branches')
            ->assertSee('Full Availability')
            ->assertSee('Search Branch')
            ->assertSee('Brand Name')
            ->assertSee('Honda Cars')
            ->assertSee('All Regions')
            ->assertSee('Module Status')
            ->assertSee('Checklist Module')
            ->assertSee('Restrooms')
            ->assertSee('Sort By')
            ->assertSee('availability-grid', false)
            ->assertSee('branch-list', false)
            ->assertSee('modules-panel', false);

        // Region filter
        $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index', ['region' => 'NCR']))
            ->assertOk()
            ->assertSee('Pasong Tamo');

        // Search filter
        $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index', ['search' => 'Pasong Tamo']))
            ->assertOk()
            ->assertSee('Pasong Tamo');

        // Status filter
        $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index', ['status' => 'fully_enabled']))
            ->assertOk();
    }

    public function test_brand_filter_only_shows_matching_named_branches(): void
    {
        $administrator = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);
        User::factory()->create(['branch' => 'MITSUBISHI SUCAT']);
        User::factory()->create(['branch' => 'HONDA CARS MAKATI']);

        $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index', ['brand' => 'Mitsubishi']))
            ->assertOk()
            ->assertViewHas('dealers', fn ($dealers): bool => $dealers->values()->all() === ['MITSUBISHI SUCAT'])
            ->assertSee('Mitsubishi', false);

        $this->actingAs($administrator)
            ->get(route('admin.checklist-access.index', ['brand' => 'Honda Cars']))
            ->assertOk()
            ->assertViewHas('dealers', fn ($dealers): bool => $dealers->values()->all() === ['HONDA CARS MAKATI']);
    }
}
