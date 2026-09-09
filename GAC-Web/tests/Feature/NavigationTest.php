<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class NavigationTest extends TestCase
{
    use RefreshDatabase;

    public function test_all_gateway_audit_compliance_pages_render_the_shared_navigation(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);
        $this->actingAs(User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]));

        $pages = [
            'dashboard' => ['view' => 'dashboard', 'title' => 'Gateway Audit Compliance Dashboard'],
            'checklists.index' => ['view' => 'checklists.index', 'title' => 'Dealer Operations Standards'],
            'reports.index' => ['view' => 'reports.index', 'title' => 'Reports &amp; Analytics'],
            'users.index' => ['view' => 'users.index', 'title' => 'User Management'],
        ];

        $icons = [
            'website  icon_home.png',
            'website  icon_audit trail.png',
        ];

        foreach ($pages as $route => $page) {
            $response = $this->get(route($route));

            $response
                ->assertOk()
                ->assertViewIs($page['view'])
                ->assertSee('aria-label="Primary navigation"', false)
                ->assertSee('aria-current="', false)
                ->assertSee($page['title'], false)
                ->assertSee('class="topbar-account"', false)
                ->assertSee('class="logout-btn"', false);

            foreach ($icons as $icon) {
                $response->assertSee('images/sidebar-icons/'.$icon, false);
            }

            self::assertSame(1, substr_count($response->getContent(), 'id="sidebar"'));
        }
    }

    public function test_editor_dropdown_is_shared_by_general_and_branch_operations_managers(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);

        foreach (['GM', 'General Manager', User::ROLE_ADMINISTRATOR, 'BOM', 'Branch Operations Manager'] as $role) {
            $manager = User::factory()->create([
                'user_type' => $role,
                'account_status' => 'active',
            ]);

            $this->actingAs($manager)
                ->get(route('dashboard'))
                ->assertOk()
                ->assertSee('id="editorDropdown" open', false)
                ->assertSee('id="editorMenu"', false)
                ->assertSee('Editor')
                ->assertSee('5S Checklist')
                ->assertSee('DOS Checklist')
                ->assertSee('Utilities Checklist');
        }

        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'account_status' => 'active',
        ]);

        $this->actingAs($pic)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertDontSee('id="editorDropdown"', false)
            ->assertDontSee('id="editorMenu"', false)
            ->assertDontSee('data-editor-checklist=', false);
    }

    public function test_reports_dropdown_routes_both_managers_to_analytics_and_user_usages(): void
    {
        foreach (['GM', User::ROLE_ADMINISTRATOR, User::ROLE_BRANCH_OPERATIONS_MANAGER] as $role) {
            $manager = User::factory()->create([
                'user_type' => $role,
                'account_status' => 'active',
            ]);

            $response = $this->actingAs($manager)->get(route('dashboard'));

            $response
                ->assertOk()
                ->assertSee('id="reportsDropdown"', false)
                ->assertSee('id="reportsMenu"', false)
                ->assertSeeInOrder(['Reports', 'Analytics', 'User Usages']);

            $analytics = $this->reportLink($response, 'analytics');
            $userUsages = $this->reportLink($response, 'user-usages');

            $this->assertSame(route('dashboard', ['tab' => 'reports']), $analytics->getAttribute('href'));
            $this->assertSame(route('dashboard', ['tab' => 'users']), $userUsages->getAttribute('href'));
        }
    }

    public function test_reports_dropdown_hides_user_usages_from_non_managers(): void
    {
        $pic = User::factory()->create([
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'account_status' => 'active',
        ]);

        $response = $this->actingAs($pic)->get(route('dashboard', ['tab' => 'reports']));

        $response
            ->assertOk()
            ->assertSee('id="reportsDropdown"', false)
            ->assertSee('id="reportsMenu"', false)
            ->assertSee('data-report-view="analytics"', false)
            ->assertDontSee('data-report-view="user-usages"', false);

        $this->assertSame(
            route('dashboard', ['tab' => 'reports']),
            $this->reportLink($response, 'analytics')->getAttribute('href')
        );

        $forbiddenView = $this->get(route('dashboard', ['tab' => 'users']));
        $this->assertNavigationLinkActive($forbiddenView, true);
        $this->assertFalse($this->elementById($forbiddenView, 'reportsDropdown')->hasAttribute('open'));
        $forbiddenView->assertViewHas('activeTab', 'overview');
        $forbiddenView->assertViewMissing('userStats');
    }

    public function test_branch_manager_user_usages_only_include_their_assigned_branch(): void
    {
        $branchManager = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);
        $localUser = User::factory()->create(['branch' => ' pasong tamo ']);
        $otherUser = User::factory()->create(['branch' => 'Cebu']);

        $response = $this->actingAs($branchManager)
            ->get(route('dashboard', ['tab' => 'users', 'branch' => 'Cebu']))
            ->assertOk()
            ->assertViewHas('activeTab', 'users')
            ->assertViewHas('isAdministrator', false)
            ->assertViewHas('userStats', fn (array $stats): bool => $stats['total'] === 2)
            ->assertViewHas('recentUsers', fn ($users): bool => $users->pluck('id')->sort()->values()->all()
                === [$branchManager->id, $localUser->id])
            ->assertViewHas('userBranchSummaries', fn ($branches): bool => $branches->count() === 1
                && $branches->first()['count'] === 2)
            ->assertSee('id="workspace-panel-users"', false)
            ->assertSee($localUser->email)
            ->assertDontSee($otherUser->email)
            ->assertDontSee(route('users.index'), false);

        $this->assertNavigationLinkActive($response, false);
        $this->assertTrue($this->elementById($response, 'reportsDropdown')->hasAttribute('open'));
        $this->assertSame('page', $this->reportLink($response, 'user-usages')->getAttribute('aria-current'));
        $this->get(route('users.index'))->assertForbidden();

        $this->actingAs(User::factory()->create(['user_type' => 'GM']))
            ->get(route('dashboard', ['tab' => 'users']))
            ->assertOk()
            ->assertViewHas('userStats', fn (array $stats): bool => $stats['total'] === 4)
            ->assertSee($otherUser->email)
            ->assertSee(route('users.index'), false);
    }

    public function test_branch_manager_without_an_assigned_branch_has_empty_user_usages(): void
    {
        User::factory()->create(['branch' => 'Cebu']);

        foreach ([null, '   '] as $branch) {
            $branchManager = User::factory()->create([
                'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
                'branch' => $branch,
            ]);

            $this->actingAs($branchManager)
                ->get(route('dashboard', ['tab' => 'users', 'branch' => 'Cebu']))
                ->assertOk()
                ->assertViewHas('activeTab', 'users')
                ->assertViewHas('userStats', fn (array $stats): bool => $stats['total'] === 0)
                ->assertViewHas('recentUsers', fn ($users): bool => $users->isEmpty())
                ->assertSee('No user accounts are available.');
        }
    }

    public function test_branch_manager_can_open_each_editor_checklist(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);
        $branchManager = User::factory()->create(['user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER]);
        $response = $this->actingAs($branchManager)->get(route('dashboard'))->assertOk();
        $links = $this->xpath($response)->query('//*[@data-editor-checklist]');
        $this->assertCount(5, $links);

        foreach ($links as $link) {
            $checklist = $link->getAttribute('data-editor-checklist');
            $page = $this->get($link->getAttribute('href'))->assertOk();
            $activeLink = $this->xpath($page)->query('//*[@data-editor-checklist="'.$checklist.'"]')->item(0);

            $this->assertInstanceOf(\DOMElement::class, $activeLink);
            $this->assertSame('page', $activeLink->getAttribute('aria-current'));
        }
    }

    public function test_dashboard_and_reports_dropdown_have_distinct_active_states(): void
    {
        $generalManager = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $overview = $this->actingAs($generalManager)->get(route('dashboard'));
        $this->assertNavigationLinkActive($overview, true);
        $this->assertFalse($this->elementById($overview, 'reportsDropdown')->hasAttribute('open'));

        foreach ([
            [route('dashboard', ['tab' => 'reports']), 'analytics', 'page'],
            [route('dashboard', ['tab' => 'users']), 'user-usages', 'page'],
            [route('reports.index'), 'analytics', 'location'],
            [route('users.index'), 'user-usages', 'location'],
        ] as [$url, $activeReportView, $ariaCurrent]) {
            $response = $this->get($url)->assertOk();

            $this->assertNavigationLinkActive($response, false);
            $this->assertTrue($this->elementById($response, 'reportsDropdown')->hasAttribute('open'));
            $this->assertSame($ariaCurrent, $this->reportLink($response, $activeReportView)->getAttribute('aria-current'));
        }
    }

    public function test_dashboard_no_longer_renders_the_internal_tab_strip(): void
    {
        $generalManager = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        foreach (['overview', 'reports', 'users'] as $view) {
            $response = $this->actingAs($generalManager)->get(route('dashboard', ['tab' => $view]));

            $response
                ->assertOk()
                ->assertViewHas('activeTab', $view)
                ->assertDontSee('class="workspace-tabs"', false)
                ->assertDontSee('aria-label="Dashboard sections"', false)
                ->assertDontSee('data-workspace-tab=', false)
                ->assertDontSee('data-workspace-target=', false);
        }
    }

    private function assertNavigationLinkActive(TestResponse $response, bool $expectedActive): void
    {
        $xpath = $this->xpath($response);
        $dashboardLink = $xpath->query(
            '//nav[@aria-label="Primary navigation"]//a[@href="'.route('dashboard').'"]'
        )?->item(0);

        $this->assertInstanceOf(\DOMElement::class, $dashboardLink);
        $classes = preg_split('/\s+/', trim($dashboardLink->getAttribute('class'))) ?: [];

        $this->assertSame($expectedActive, in_array('active', $classes, true));
        $this->assertSame($expectedActive ? 'page' : '', $dashboardLink->getAttribute('aria-current'));
    }

    public function test_dashboard_reports_tab_audit_date_is_strictly_monthly(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);

        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $response = $this->actingAs($admin)->get(route('dashboard', ['tab' => 'reports']));

        $response
            ->assertOk()
            ->assertViewHas('reportFilters', fn (array $filters): bool => isset($filters['month'])
                && ! array_key_exists('date_from', $filters)
                && ! array_key_exists('date_to', $filters))
            ->assertSee('Audit Month')
            ->assertSee('id="dashboardReportMonth"', false)
            ->assertSee('type="month"', false)
            ->assertDontSee('Audit date range')
            ->assertDontSee('name="date_from"', false)
            ->assertDontSee('name="date_to"', false);
    }

    private function reportLink(TestResponse $response, string $view): \DOMElement
    {
        $link = $this->xpath($response)
            ->query('//*[@data-report-view="'.$view.'"]')
            ?->item(0);

        $this->assertInstanceOf(\DOMElement::class, $link);

        return $link;
    }

    private function elementById(TestResponse $response, string $id): \DOMElement
    {
        $element = $this->xpath($response)->query('//*[@id="'.$id.'"]')?->item(0);

        $this->assertInstanceOf(\DOMElement::class, $element);

        return $element;
    }

    private function xpath(TestResponse $response): \DOMXPath
    {
        $document = new \DOMDocument;
        $previous = libxml_use_internal_errors(true);
        $document->loadHTML($response->getContent());
        libxml_clear_errors();
        libxml_use_internal_errors($previous);

        return new \DOMXPath($document);
    }
}
