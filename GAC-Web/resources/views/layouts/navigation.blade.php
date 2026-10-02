@if (request()->routeIs(['dashboard', 'checklists.*', 'reports.*', 'users.*', 'admin.*', 'profile.*']))
    @php
        $viewerRole = auth()->user()?->roleCode();
        $canEditChecklists = auth()->user()?->hasAdministrativeAccess() === true;
        $hasManagerNavigation = $canEditChecklists
            || in_array($viewerRole, [
                \App\Models\User::ROLE_GENERAL_MANAGER,
                \App\Models\User::ROLE_BRANCH_OPERATIONS_MANAGER,
            ], true);
        $dashboardSection = null;

        if (request()->routeIs('dashboard')) {
            $administratorDefaultSection = $canEditChecklists
                && ! request()->hasAny(['form', 'submission_id', 'audit_date', 'five_s_area', 'summary_mode'])
                    ? 'users'
                    : 'overview';
            $requestedDashboardSection = mb_strtolower(trim((string) request()->query(
                'tab',
                $administratorDefaultSection
            )));
            $dashboardSection = in_array($requestedDashboardSection, ['overview', 'follow-up', 'reports', 'users', 'override'], true)
                ? $requestedDashboardSection
                : 'overview';

            if ($dashboardSection === 'users' && ! $hasManagerNavigation) {
                $dashboardSection = 'overview';
            }

            if ($dashboardSection === 'follow-up' && ! $hasManagerNavigation) {
                $dashboardSection = 'overview';
            }
        }

        $dashboardIsActive = request()->routeIs('dashboard') && $dashboardSection === 'overview';
        $followUpIsActive = $hasManagerNavigation
            && request()->routeIs('dashboard')
            && $dashboardSection === 'follow-up';
        $analyticsIsActive = (request()->routeIs('dashboard') && $dashboardSection === 'reports')
            || request()->routeIs('reports.*');
        $userUsagesIsActive = $hasManagerNavigation
            && ((request()->routeIs('dashboard') && $dashboardSection === 'users')
                || request()->routeIs('users.*'));
        $reportsIsActive = $analyticsIsActive || $userUsagesIsActive;
        $analyticsIsCurrentPage = request()->routeIs('dashboard') && $dashboardSection === 'reports';
        $userUsagesIsCurrentPage = request()->routeIs('dashboard') && $dashboardSection === 'users';

        $appNavigationItems = [
            [
                'route' => 'dashboard',
                'active' => ['dashboard'],
                'is_active' => $dashboardIsActive,
                'icon' => 'images/sidebar-icons/website  icon_home.png',
                'label' => 'Dashboard',
            ],
        ];

        $followUpContext = array_filter(
            request()->only(['branch', 'month', 'status']),
            static fn ($value): bool => $value !== null && $value !== ''
        );
        $currentFollowUpTemplate = $followUpIsActive
            ? (string) request()->query('template', '')
            : null;
        $currentFollowUpView = $followUpIsActive
            ? (string) request()->query('view', 'findings')
            : 'findings';

        if (! $hasManagerNavigation) {
            $appNavigationItems[] = [
                'route' => 'checklists.index',
                'active' => ['checklists.*'],
                'icon' => 'images/sidebar-icons/website  icon_audit trail.png',
                'label' => 'Checklists',
            ];
        }

        $checklistEditorGroups = collect(config('checklists.navigation_groups'))
            ->map(function (array $group): array {
                $group['items'] = collect($group['items'])
                    ->filter(fn (array $item): bool => auth()->user()?->canAccessChecklist($item['slug']) === true)
                    ->values()
                    ->all();

                return $group;
            })
            ->filter(fn (array $group): bool => ! empty($group['items']))
            ->values()
            ->all();

        $currentChecklist = request()->routeIs('checklists.*')
            ? (string) request()->query('checklist', 'dealer-operations-standards')
            : null;
        $currentChecklist = match ($currentChecklist) {
            'dealer-operations', 'dos', 'dealer-operations-standards-aftersales', 'aftersales' => 'dealer-operations-standards',
            'subform', 'dos-subform', 'aftersales-subform' => 'dealer-operations-standards-subform',
            'documentation', 'doc', 'dos-documentation', 'dos-doc', 'aftersales-documentation' => 'dealer-operations-standards-documentation',
            'gateway-5s', '5s' => 'sales',
            'utilities' => 'restroom',
            default => $currentChecklist,
        };
        $editorIsActive = $hasManagerNavigation && request()->routeIs('checklists.*');
        $editorContext = array_filter(
            request()->only(['branch', 'date']),
            static fn ($value): bool => $value !== null && $value !== ''
        );
        $overrideIsActive = request()->routeIs('dashboard') && $dashboardSection === 'override';
        $currentOverrideChecklist = $overrideIsActive
            ? (string) request()->query('checklist', 'dealer-operations-standards')
            : null;
        $currentOverrideChecklist = match ($currentOverrideChecklist) {
            'dealer-operations', 'dos', 'dealer-operations-standards-aftersales', 'aftersales' => 'dealer-operations-standards',
            'gateway-5s', '5s' => 'sales',
            'utilities' => 'restroom',
            default => $currentOverrideChecklist,
        };
        $overrideContext = array_filter(
            request()->only(['branch', 'month', 'status']),
            static fn ($value): bool => $value !== null && $value !== ''
        );
    @endphp

    <aside class="sidebar" id="sidebar">
        <a class="logo" href="{{ route('dashboard') }}" aria-label="Gateway Audit Compliance dashboard">
            <span class="logo-mark" aria-hidden="true">
                <img src="{{ asset('images/Gateway_logo_circle.png') }}" alt="" width="56" height="56">
            </span>
            <span class="logo-copy">
                <strong>GATEWAY</strong>
                <span>Audit Compliance System</span>
            </span>
        </a>

        <nav class="sidebar-nav" aria-label="Primary navigation">
            <div class="menu-title">Audit Compliance</div>

            <ul class="menu">
                @foreach ($appNavigationItems as $item)
                    @php($isActive = $item['is_active'] ?? request()->routeIs(...$item['active']))
                    <li>
                        <a class="nav-link {{ $isActive ? 'active' : '' }}"
                           href="{{ route($item['route'], $item['parameters'] ?? []) }}"
                           @if (!empty($item['data_view'])) data-navigation-view="{{ $item['data_view'] }}" @endif
                           @if ($isActive) aria-current="page" @endif>
                            <span class="menu-icon nav-icon" aria-hidden="true">
                                <img src="{{ asset($item['icon']) }}" alt="" width="22" height="22">
                            </span>
                            <span>{{ $item['label'] }}</span>
                        </a>
                    </li>
                @endforeach

                @if ($hasManagerNavigation)
                    <li class="sidebar-editor-item sidebar-findings-item">
                        <details class="sidebar-editor sidebar-findings" id="findingsDropdown"{{ $followUpIsActive ? ' open' : '' }}>
                            <summary class="sidebar-editor-toggle{{ $followUpIsActive ? ' active' : '' }}"
                                     aria-controls="findingsMenu">
                                <span class="menu-icon nav-icon" aria-hidden="true">
                                    <img src="{{ asset('images/sidebar-icons/website  icon_task assigment.png') }}" alt="" width="22" height="22">
                                </span>
                                <span>Checklist Findings</span>
                                <i class="fas fa-chevron-down sidebar-editor-chevron" aria-hidden="true"></i>
                            </summary>

                            <div class="sidebar-editor-menu" id="findingsMenu" aria-label="Checklist findings">
                                <section class="sidebar-editor-group" aria-labelledby="findingsGroupViews">
                                    <div class="sidebar-editor-group-title" id="findingsGroupViews">
                                        Views
                                    </div>
                                    <div class="sidebar-editor-links">
                                        @php($allFindingsActive = $followUpIsActive && $currentFollowUpView === 'findings' && empty($currentFollowUpTemplate))
                                        <a href="{{ route('dashboard', ['tab' => 'follow-up']) }}"
                                           class="sidebar-editor-link{{ $allFindingsActive ? ' active' : '' }}"
                                           data-navigation-view="follow-up"
                                           @if ($allFindingsActive) aria-current="page" @endif>
                                            <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                            <span>All Findings</span>
                                        </a>
                                        @php($historyActive = $followUpIsActive && $currentFollowUpView === 'history')
                                        <a href="{{ route('dashboard', [...$followUpContext, 'tab' => 'follow-up', 'view' => 'history']) }}"
                                           class="sidebar-editor-link{{ $historyActive ? ' active' : '' }}"
                                           @if ($historyActive) aria-current="page" @endif>
                                            <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                            <span>Activity History</span>
                                        </a>
                                    </div>
                                </section>

                                @foreach ($checklistEditorGroups as $groupIndex => $group)
                                    <section class="sidebar-editor-group" aria-labelledby="findingsGroup{{ $groupIndex }}">
                                        <div class="sidebar-editor-group-title" id="findingsGroup{{ $groupIndex }}">
                                            {{ $group['label'] }}
                                        </div>
                                        <div class="sidebar-editor-links">
                                            @foreach ($group['items'] as $findingsItem)
                                                @php($findingsItemActive = $followUpIsActive && $currentFollowUpTemplate === $findingsItem['slug'])
                                                <a href="{{ route('dashboard', [...$followUpContext, 'tab' => 'follow-up', 'view' => 'findings', 'template' => $findingsItem['slug']]) }}"
                                                   class="sidebar-editor-link{{ $findingsItemActive ? ' active' : '' }}"
                                                   data-findings-checklist="{{ $findingsItem['slug'] }}"
                                                   @if ($findingsItemActive) aria-current="page" @endif>
                                                    <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                                    <span>{{ $findingsItem['label'] }}</span>
                                                </a>
                                            @endforeach
                                        </div>
                                    </section>
                                @endforeach
                            </div>
                        </details>
                    </li>
                @endif

                @if ($canEditChecklists)
                    <li class="sidebar-editor-item">
                        <details class="sidebar-editor" id="editorDropdown"{{ $editorIsActive ? ' open' : '' }}>
                            <summary class="sidebar-editor-toggle{{ $editorIsActive ? ' active' : '' }}"
                                     aria-controls="editorMenu">
                                <span class="menu-icon nav-icon" aria-hidden="true">
                                    <img src="{{ asset('images/sidebar-icons/website  icon_audit trail.png') }}" alt="" width="22" height="22">
                                </span>
                                <span>Checklist Editor</span>
                                <i class="fas fa-chevron-down sidebar-editor-chevron" aria-hidden="true"></i>
                            </summary>

                            <div class="sidebar-editor-menu" id="editorMenu" aria-label="Checklist editor">
                                @foreach ($checklistEditorGroups as $groupIndex => $group)
                                    <section class="sidebar-editor-group"
                                             aria-labelledby="editorGroup{{ $groupIndex }}">
                                        <div class="sidebar-editor-group-title" id="editorGroup{{ $groupIndex }}">
                                            {{ $group['label'] }}
                                        </div>
                                        <div class="sidebar-editor-links">
                                            @foreach ($group['items'] as $editorItem)
                                                @php($editorItemActive = $currentChecklist === $editorItem['slug'])
                                                <a href="{{ route('checklists.index', [...$editorContext, 'checklist' => $editorItem['slug']]) }}"
                                                   class="sidebar-editor-link{{ $editorItemActive ? ' active' : '' }}"
                                                   data-editor-checklist="{{ $editorItem['slug'] }}"
                                                   @if ($editorItemActive) aria-current="page" @endif>
                                                    <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                                    <span>{{ $editorItem['label'] }}</span>
                                                </a>
                                            @endforeach
                                        </div>
                                    </section>
                                @endforeach
                            </div>
                        </details>
                    </li>
                @endif

                @if (auth()->user()?->canOverrideChecklistResponses())
                    <li class="sidebar-override-item">
                        <details class="sidebar-editor sidebar-override" id="overrideDropdown"{{ $overrideIsActive ? ' open' : '' }}>
                            <summary class="sidebar-editor-toggle{{ $overrideIsActive ? ' active' : '' }}"
                                     aria-controls="overrideMenu">
                                <span class="menu-icon nav-icon" aria-hidden="true">
                                    <img src="{{ asset('images/sidebar-icons/website  icon_override.png') }}" alt="" width="22" height="22">
                                </span>
                                <span>Checklist Override</span>
                                <i class="fas fa-chevron-down sidebar-editor-chevron" aria-hidden="true"></i>
                            </summary>

                            <div class="sidebar-editor-menu" id="overrideMenu" aria-label="Checklist override">
                                @foreach ($checklistEditorGroups as $groupIndex => $group)
                                    <section class="sidebar-editor-group" aria-labelledby="overrideGroup{{ $groupIndex }}">
                                        <div class="sidebar-editor-group-title" id="overrideGroup{{ $groupIndex }}">
                                            {{ $group['label'] }}
                                        </div>
                                        <div class="sidebar-editor-links">
                                            @foreach ($group['items'] as $overrideItem)
                                                @php($overrideItemActive = $currentOverrideChecklist === $overrideItem['slug'])
                                                <a href="{{ route('dashboard', [...$overrideContext, 'tab' => 'override', 'checklist' => $overrideItem['slug']]) }}"
                                                   class="sidebar-editor-link{{ $overrideItemActive ? ' active' : '' }}"
                                                   data-override-checklist="{{ $overrideItem['slug'] }}"
                                                   @if ($overrideItemActive) aria-current="page" @endif>
                                                    <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                                    <span>{{ $overrideItem['label'] }}</span>
                                                </a>
                                            @endforeach
                                        </div>
                                    </section>
                                @endforeach
                            </div>
                        </details>
                    </li>
                @endif

                <li class="sidebar-reports-item">
                    <details class="sidebar-editor sidebar-reports"
                             id="reportsDropdown"{{ $reportsIsActive ? ' open' : '' }}>
                        <summary class="sidebar-editor-toggle sidebar-reports-toggle{{ $reportsIsActive ? ' active' : '' }}"
                                 aria-controls="reportsMenu">
                            <span class="menu-icon nav-icon" aria-hidden="true">
                                <img src="{{ asset('images/sidebar-icons/website  icon_report and analytics.png') }}" alt="" width="22" height="22">
                            </span>
                            <span>Reports</span>
                            <i class="fas fa-chevron-down sidebar-editor-chevron" aria-hidden="true"></i>
                        </summary>

                        <ul class="sidebar-editor-menu sidebar-reports-menu"
                            id="reportsMenu" aria-label="Reports">
                            <li>
                                <a href="{{ route('dashboard', ['tab' => 'reports']) }}"
                                   class="sidebar-editor-link sidebar-reports-link{{ $analyticsIsActive ? ' active' : '' }}"
                                   data-report-view="analytics"
                                   @if ($analyticsIsActive) aria-current="{{ $analyticsIsCurrentPage ? 'page' : 'location' }}" @endif>
                                    <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                    <span>Analytics</span>
                                </a>
                            </li>

                            @if ($hasManagerNavigation)
                                <li>
                                    <a href="{{ route('dashboard', ['tab' => 'users']) }}"
                                       class="sidebar-editor-link sidebar-reports-link{{ $userUsagesIsActive ? ' active' : '' }}"
                                       data-report-view="user-usages"
                                       @if ($userUsagesIsActive) aria-current="{{ $userUsagesIsCurrentPage ? 'page' : 'location' }}" @endif>
                                        <span class="sidebar-editor-dot" aria-hidden="true"></span>
                                        <span>User Usage</span>
                                    </a>
                                </li>
                            @endif
                        </ul>
                    </details>
                </li>

                @if ($canEditChecklists)
                <li class="sidebar-debug-item">
                    <details class="sidebar-editor sidebar-debug" id="debugDropdown">
                        <summary class="sidebar-editor-toggle sidebar-debug-toggle" aria-controls="debugMenu">
                            <span class="menu-icon nav-icon" aria-hidden="true">
                                <i class="fas fa-bug sidebar-debug-icon" aria-hidden="true"></i>
                            </span>
                            <span>Debug</span>
                            <i class="fas fa-chevron-down sidebar-editor-chevron" aria-hidden="true"></i>
                        </summary>

                        <ul class="sidebar-editor-menu sidebar-debug-menu" id="debugMenu" aria-label="Debug Tools">
                            <li>
                                <button type="button"
                                        class="sidebar-editor-link sidebar-debug-link"
                                        id="sidebarDebugResetDatabaseBtn"
                                        title="Reset database activity and checklist data">
                                    <span class="sidebar-editor-dot" style="background: #DC2626;" aria-hidden="true"></span>
                                    <span>Reset Database Data</span>
                                </button>
                            </li>
                            <li>
                                <button type="button"
                                        class="sidebar-editor-link sidebar-debug-link"
                                        id="sidebarDebugResetBtn"
                                        title="Reset checklist answers">
                                    <span class="sidebar-editor-dot" style="background: #FF4D6D;" aria-hidden="true"></span>
                                    <span>Reset Checklist</span>
                                </button>
                            </li>
                            <li>
                                <button type="button"
                                        class="sidebar-editor-link sidebar-debug-link"
                                        id="sidebarDebugResetDraftsBtn"
                                        title="Reset checklist drafts">
                                    <span class="sidebar-editor-dot" style="background: #F59E0B;" aria-hidden="true"></span>
                                    <span>Reset Drafts</span>
                                </button>
                            </li>
                            <li>
                                <button type="button"
                                        class="sidebar-editor-link sidebar-debug-link"
                                        id="sidebarDebugResetSubformsBtn"
                                        title="Reset subform submissions">
                                    <span class="sidebar-editor-dot" style="background: #10B981;" aria-hidden="true"></span>
                                    <span>Reset Subforms</span>
                                </button>
                            </li>
                            <li>
                                <button type="button"
                                        class="sidebar-editor-link sidebar-debug-link"
                                        id="sidebarDebugResetDocumentationBtn"
                                        title="Reset documentation submissions">
                                    <span class="sidebar-editor-dot" style="background: #8B5CF6;" aria-hidden="true"></span>
                                    <span>Reset Documentation</span>
                                </button>
                            </li>
                            <li>
                                <button type="button"
                                        class="sidebar-editor-link sidebar-debug-link"
                                        id="sidebarDebugResetNotificationsBtn"
                                        title="Reset notification history">
                                    <span class="sidebar-editor-dot" style="background: #3B82F6;" aria-hidden="true"></span>
                                    <span>Reset Notifications</span>
                                </button>
                            </li>
                        </ul>
                    </details>
                </li>
                @endif

                @if ($canEditChecklists)
                    <li>
                        <a class="nav-link {{ request()->routeIs('admin.checklist-access.*') ? 'active' : '' }}"
                           href="{{ route('admin.checklist-access.index') }}"
                           @if (request()->routeIs('admin.checklist-access.*')) aria-current="page" @endif>
                            <span class="menu-icon nav-icon" aria-hidden="true"><i class="fas fa-toggle-on"></i></span>
                            <span>Checklist Availability</span>
                        </a>
                    </li>
                @endif
            </ul>


            <div class="sidebar-footer admin-dropdown" id="adminDropdown">
                {{-- Kept for compatibility with the dashboard's existing account-menu script. --}}
                <button class="shell-account-proxy" id="adminBoxToggle" type="button"
                        aria-expanded="false" aria-controls="adminMenu" hidden>Account menu</button>

                <form class="sidebar-logout-form" id="adminMenu" method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button class="logout-btn" type="submit">
                        <i class="fas fa-power-off" aria-hidden="true"></i>
                        <span>Sign out</span>
                    </button>
                </form>
            </div>
        </nav>
    </aside>

    <div class="sidebar-backdrop" id="sidebarBackdrop" aria-hidden="true"></div>
@else
<nav x-data="{ open: false }" class="gac-main-nav">
    <!-- Primary Navigation Menu -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex">
                <!-- Logo -->
                <div class="shrink-0 flex items-center">
                    <a href="{{ route('dashboard') }}" class="gac-nav-logo">
                        <span class="gac-nav-logo-mark">
                            <x-application-logo />
                        </span>
                        <span class="gac-nav-brand-copy">
                            <strong>GATEWAY</strong>
                            <small>Audit Compliance</small>
                        </span>
                    </a>
                </div>

                <!-- Navigation Links -->
                <div class="hidden space-x-8 sm:-my-px sm:ms-10 sm:flex">
                    <x-nav-link :href="route('dashboard')" :active="request()->routeIs('dashboard')">
                        {{ __('Dashboard') }}
                    </x-nav-link>
                </div>
            </div>

            <!-- Settings Dropdown -->
            <div class="hidden sm:flex sm:items-center sm:ms-6">
                <x-dropdown align="right" width="48">
                    <x-slot name="trigger">
                        <button class="gac-nav-user-button">
                            <div>{{ Auth::user()->name }}</div>

                            <div class="ms-1">
                                <svg class="fill-current h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                                </svg>
                            </div>
                        </button>
                    </x-slot>

                    <x-slot name="content">
                        <x-dropdown-link :href="route('profile.show')">
                            {{ __('Profile') }}
                        </x-dropdown-link>

                        <!-- Authentication -->
                        <form method="POST" action="{{ route('logout') }}">
                            @csrf

                            <x-dropdown-link :href="route('logout')"
                                    onclick="event.preventDefault();
                                                this.closest('form').submit();">
                                {{ __('Log Out') }}
                            </x-dropdown-link>
                        </form>
                    </x-slot>
                </x-dropdown>
            </div>

            <!-- Hamburger -->
            <div class="-me-2 flex items-center sm:hidden">
                <button @click="open = ! open" class="gac-mobile-toggle" aria-label="Toggle navigation" :aria-expanded="open.toString()">
                    <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                        <path :class="{'hidden': open, 'inline-flex': ! open }" class="inline-flex" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                        <path :class="{'hidden': ! open, 'inline-flex': open }" class="hidden" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>
    </div>

    <!-- Responsive Navigation Menu -->
    <div :class="{'block': open, 'hidden': ! open}" class="gac-responsive-nav hidden sm:hidden">
        <div class="pt-2 pb-3 space-y-1">
            <x-responsive-nav-link :href="route('dashboard')" :active="request()->routeIs('dashboard')">
                {{ __('Dashboard') }}
            </x-responsive-nav-link>
        </div>

        <!-- Responsive Settings Options -->
        <div class="gac-responsive-account pt-4 pb-1">
            <div class="px-4">
                <div class="gac-responsive-account-name font-medium text-base">{{ Auth::user()->name }}</div>
                <div class="gac-responsive-account-email font-medium text-sm">{{ Auth::user()->email }}</div>
            </div>

            <div class="mt-3 space-y-1">
                <x-responsive-nav-link :href="route('profile.show')">
                    {{ __('Profile') }}
                </x-responsive-nav-link>

                <!-- Debug: Reset Checklist -->
                <button type="button"
                        id="fallbackDebugResetDatabaseBtn"
                        class="w-full text-left px-4 py-2 text-sm text-red-700 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-database" aria-hidden="true"></i>
                    <span>Debug: Reset Database Data</span>
                </button>

                <button type="button"
                        id="fallbackDebugResetBtn"
                        class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-bug" aria-hidden="true"></i>
                    <span>Debug: Reset Checklist</span>
                </button>

                <!-- Debug: Reset Drafts -->
                <button type="button"
                        id="fallbackDebugResetDraftsBtn"
                        class="w-full text-left px-4 py-2 text-sm text-amber-600 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-eraser" aria-hidden="true"></i>
                    <span>Debug: Reset Drafts</span>
                </button>

                <!-- Debug: Reset Subforms -->
                <button type="button"
                        id="fallbackDebugResetSubformsBtn"
                        class="w-full text-left px-4 py-2 text-sm text-emerald-600 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-table-list" aria-hidden="true"></i>
                    <span>Debug: Reset Subforms</span>
                </button>

                <!-- Debug: Reset Documentation -->
                <button type="button"
                        id="fallbackDebugResetDocumentationBtn"
                        class="w-full text-left px-4 py-2 text-sm text-purple-600 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-file-lines" aria-hidden="true"></i>
                    <span>Debug: Reset Documentation</span>
                </button>

                <!-- Debug: Reset Notifications -->
                <button type="button"
                        id="fallbackDebugResetNotificationsBtn"
                        class="w-full text-left px-4 py-2 text-sm text-blue-600 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-bell-slash" aria-hidden="true"></i>
                    <span>Debug: Reset Notifications</span>
                </button>

                <!-- Authentication -->
                <form method="POST" action="{{ route('logout') }}">
                    @csrf

                    <x-responsive-nav-link :href="route('logout')"
                            onclick="event.preventDefault();
                                        this.closest('form').submit();">
                        {{ __('Log Out') }}
                    </x-responsive-nav-link>
                </form>
            </div>
        </div>
    </div>
</nav>
@endif

<div class="debug-modal-overlay" id="debugResetModalOverlay" aria-hidden="true">
    <div class="debug-modal" role="dialog" aria-labelledby="debugResetModalTitle" aria-modal="true">
        <header class="debug-modal-header">
            <div class="debug-modal-title-wrap">
                <span class="debug-modal-badge" id="debugResetModalBadge" aria-hidden="true">
                    <i class="fas fa-bug" id="debugResetModalIcon"></i>
                </span>
                <div>
                    <h3 id="debugResetModalTitle">Debug: Reset Checklist Answers</h3>
                    <p id="debugResetModalSubtitle">Clear answer entries while preserving master items &amp; accounts.</p>
                </div>
            </div>
            <button type="button" class="debug-modal-close" id="debugResetModalClose" aria-label="Close debug dialog">
                <i class="fas fa-xmark" aria-hidden="true"></i>
            </button>
        </header>

        <div class="debug-modal-body">
            <div class="debug-safety-guarantee">
                <div class="debug-safety-icon">
                    <i class="fas fa-shield-halved" aria-hidden="true"></i>
                </div>
                <div class="debug-safety-copy">
                    <strong>Safety Guarantee</strong>
                    <p id="debugResetSafetyCopy">Only checklist answers (user responses, drafts, submissions, subforms, documentation) and notification history will be reset. Master checklist templates, sections, questions, rating rules, and user accounts will <strong>NEVER</strong> be deleted or altered.</p>
                </div>
            </div>

            <div class="debug-modal-field" id="debugTemplateField">
                <label for="debugTemplateSelect">Select Checklist to Reset</label>
                <select id="debugTemplateSelect" class="debug-select-control">
                    <option value="all" selected>All Checklists (All Types)</option>
                    @if (isset($currentChecklist) && $currentChecklist)
                        <option value="{{ $currentChecklist }}">Current Checklist ({{ ucwords(str_replace('-', ' ', $currentChecklist)) }})</option>
                    @endif
                    <option value="dealer-operations-standards">Dealer Operations Standards (Aftersales)</option>
                    <option value="dealer-operations-standards-subform">Dealer Operations Standards (Subform - 39 Items)</option>
                    <option value="dealer-operations-standards-documentation">Dealer Operations Standards (Documentation - 17 Standards)</option>
                    <option value="dealer-operations-standards-sales">Dealer Operations Standards (Sales)</option>
                    <option value="sales">Sales 5S Checklist</option>
                    <option value="service">Service 5S Checklist</option>
                    <option value="restroom">Restroom Checklist</option>
                </select>
            </div>

            <div class="debug-modal-field">
                <label>Target Entries</label>
                <div class="debug-scope-options">
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="database">
                        <span>
                            <strong>All database activity and checklist data</strong>
                            <small>Clears all checklist records, reports, notifications, usage history, and database queue/cache data.</small>
                        </span>
                    </label>
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="all" checked>
                        <span>
                            <strong>All entries (Drafts, Submissions &amp; Notifications)</strong>
                            <small>Clears unfinished drafts, submitted inspection records, and related notifications.</small>
                        </span>
                    </label>
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="drafts">
                        <span>
                            <strong>Drafts only</strong>
                            <small>Clears unfinished/in-progress drafts while keeping submitted history intact.</small>
                        </span>
                    </label>
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="submitted">
                        <span>
                            <strong>Submitted answers only</strong>
                            <small>Clears submitted records and their task notification history while preserving drafts.</small>
                        </span>
                    </label>
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="subforms">
                        <span>
                            <strong>Subform submissions only</strong>
                            <small>Clears subform checklist answers across standalone and DOS submissions.</small>
                        </span>
                    </label>
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="documentation">
                        <span>
                            <strong>Documentation submissions only</strong>
                            <small>Clears documentation audit samples across standalone and DOS submissions.</small>
                        </span>
                    </label>
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetTarget" value="notifications">
                        <span>
                            <strong>Notification history only</strong>
                            <small>Clears task completion and follow-up notifications without deleting checklist answers.</small>
                        </span>
                    </label>
                </div>
            </div>

            <div class="debug-modal-field" id="debugIncludeNotificationsField">
                <label class="debug-radio-label" style="align-items: center;">
                    <input type="checkbox" id="debugResetIncludeNotifications" name="include_notifications" value="1" checked>
                    <span>
                        <strong>Include notification history in reset</strong>
                        <small>Also clears task completion alerts and seen history related to these items.</small>
                    </span>
                </label>
            </div>

            <div class="debug-modal-field" id="debugScopeField">
                <label>Reset Scope</label>
                <div class="debug-scope-options">
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetScope" value="all" checked>
                        <span>
                            <strong>All branches &amp; dates</strong>
                            <small>Clears matching entries across all dates and branches.</small>
                        </span>
                    </label>
                    @if (isset($currentChecklist) && $currentChecklist)
                        <label class="debug-radio-label" id="debugScopeCurrentLabel">
                            <input type="radio" name="debugResetScope" value="current">
                            <span>
                                <strong>Current branch &amp; date only</strong>
                                <small>Only clear matching entries for the active branch &amp; date being viewed.</small>
                            </span>
                        </label>
                    @endif
                </div>
            </div>

            <div class="debug-modal-alert" id="debugResetAlert" style="display: none;"></div>
        </div>

        <footer class="debug-modal-footer">
            <button type="button" class="debug-btn-cancel" id="debugResetModalCancel">Cancel</button>
            <button type="button" class="debug-btn-reset" id="debugResetExecuteBtn">
                <i class="fas fa-trash-can" aria-hidden="true"></i>
                <span>Reset Answers</span>
            </button>
        </footer>
    </div>
</div>

<script>
(function() {
    function initDebugChecklistReset() {
        const modal = document.getElementById('debugResetModalOverlay');
        if (!modal) return;

        const openBtnSidebarDatabase = document.getElementById('sidebarDebugResetDatabaseBtn');
        const openBtnSidebar = document.getElementById('sidebarDebugResetBtn');
        const openBtnSidebarDrafts = document.getElementById('sidebarDebugResetDraftsBtn');
        const openBtnSidebarSubforms = document.getElementById('sidebarDebugResetSubformsBtn');
        const openBtnSidebarDoc = document.getElementById('sidebarDebugResetDocumentationBtn');
        const openBtnSidebarNotifications = document.getElementById('sidebarDebugResetNotificationsBtn');
        const openBtnFallbackDatabase = document.getElementById('fallbackDebugResetDatabaseBtn');
        const openBtnFallback = document.getElementById('fallbackDebugResetBtn');
        const openBtnFallbackDrafts = document.getElementById('fallbackDebugResetDraftsBtn');
        const openBtnFallbackSubforms = document.getElementById('fallbackDebugResetSubformsBtn');
        const openBtnFallbackDoc = document.getElementById('fallbackDebugResetDocumentationBtn');
        const openBtnFallbackNotifications = document.getElementById('fallbackDebugResetNotificationsBtn');
        const closeBtn = document.getElementById('debugResetModalClose');
        const cancelBtn = document.getElementById('debugResetModalCancel');
        const executeBtn = document.getElementById('debugResetExecuteBtn');
        const templateSelect = document.getElementById('debugTemplateSelect');
        const alertBox = document.getElementById('debugResetAlert');
        const modalTitle = document.getElementById('debugResetModalTitle');
        const modalSubtitle = document.getElementById('debugResetModalSubtitle');
        const modalIcon = document.getElementById('debugResetModalIcon');
        const safetyCopy = document.getElementById('debugResetSafetyCopy');
        const templateField = document.getElementById('debugTemplateField');
        const scopeField = document.getElementById('debugScopeField');
        const includeNotificationsField = document.getElementById('debugIncludeNotificationsField');
        const includeNotificationsCheckbox = document.getElementById('debugResetIncludeNotifications');

        function updateModalStateForTarget(target) {
            if (templateField) templateField.style.display = target === 'database' ? 'none' : 'block';
            if (scopeField) scopeField.style.display = target === 'database' ? 'none' : 'block';
            if (safetyCopy) {
                safetyCopy.textContent = target === 'database'
                    ? 'This clears all checklist records, reports, notifications, usage history, and database queue/cache data. Users, login and device settings, checklist definitions, restroom dropdowns, and dealer checklist settings are preserved.'
                    : 'Only checklist answers (user responses, drafts, submissions, subforms, documentation) and notification history will be reset. Master checklist templates, sections, questions, rating rules, and user accounts will never be deleted or altered.';
            }
            if (modalTitle) {
                modalTitle.textContent = target === 'database'
                    ? 'Debug: Reset Database Data'
                    : target === 'drafts'
                    ? 'Debug: Reset Checklist Drafts'
                    : (target === 'submitted'
                        ? 'Debug: Reset Submitted Answers'
                        : (target === 'subforms'
                            ? 'Debug: Reset Subform Submissions'
                            : (target === 'documentation'
                                ? 'Debug: Reset Documentation Submissions'
                                : (target === 'notifications' ? 'Debug: Reset Notification History' : 'Debug: Reset Checklist Answers'))));
            }
            if (modalSubtitle) {
                modalSubtitle.textContent = target === 'database'
                    ? 'Clear all operational records while preserving users and settings needed by other functions.'
                    : target === 'drafts'
                    ? 'Clear unfinished draft entries while preserving submitted history & master items.'
                    : (target === 'submitted'
                        ? 'Clear submitted inspection records while preserving in-progress drafts.'
                        : (target === 'subforms'
                            ? 'Clear subform submission entries while preserving core checklist answers and master items.'
                            : (target === 'documentation'
                                ? 'Clear documentation audit samples while preserving core checklist answers and master items.'
                                : (target === 'notifications'
                                    ? 'Clear task completion and follow-up notification history while preserving checklist items.'
                                    : 'Clear answers, subforms, documentation, and notification history while preserving master items & accounts.'))));
            }
            if (modalIcon) {
                modalIcon.className = target === 'database'
                    ? 'fas fa-database'
                    : target === 'drafts'
                    ? 'fas fa-eraser'
                    : (target === 'subforms'
                        ? 'fas fa-table-list'
                        : (target === 'documentation'
                            ? 'fas fa-file-lines'
                            : (target === 'notifications' ? 'fas fa-bell-slash' : 'fas fa-bug')));
            }
            if (includeNotificationsField) {
                includeNotificationsField.style.display = (target === 'database' || target === 'notifications' || target === 'subforms' || target === 'documentation') ? 'none' : 'block';
            }
            if (executeBtn) {
                const icon = target === 'database'
                    ? 'fa-database'
                    : target === 'drafts'
                    ? 'fa-eraser'
                    : (target === 'subforms'
                        ? 'fa-table-list'
                        : (target === 'documentation'
                            ? 'fa-file-lines'
                            : (target === 'notifications' ? 'fa-bell-slash' : 'fa-trash-can')));
                const label = target === 'database'
                    ? 'Reset Database Data'
                    : target === 'drafts'
                    ? 'Reset Drafts'
                    : (target === 'submitted'
                        ? 'Reset Submissions'
                        : (target === 'subforms'
                            ? 'Reset Subforms'
                            : (target === 'documentation'
                                ? 'Reset Documentation'
                                : (target === 'notifications' ? 'Reset Notifications' : 'Reset Answers'))));
                executeBtn.innerHTML = `<i class="fas ${icon}" aria-hidden="true"></i><span>${label}</span>`;
            }
        }

        function openModal(initialTarget = 'all') {
            modal.classList.add('is-open');
            modal.setAttribute('aria-hidden', 'false');

            if (templateSelect) templateSelect.value = 'all';
            const allScopeRadio = document.querySelector('input[name="debugResetScope"][value="all"]');
            if (allScopeRadio) allScopeRadio.checked = true;

            const targetRadio = document.querySelector(`input[name="debugResetTarget"][value="${initialTarget}"]`);
            if (targetRadio) {
                targetRadio.checked = true;
            }

            if (templateSelect) {
                if (initialTarget === 'subforms') {
                    const subformOpt = templateSelect.querySelector('option[value="dealer-operations-standards-subform"]');
                    if (subformOpt) subformOpt.selected = true;
                } else if (initialTarget === 'documentation') {
                    const docOpt = templateSelect.querySelector('option[value="dealer-operations-standards-documentation"]');
                    if (docOpt) docOpt.selected = true;
                }
            }

            updateModalStateForTarget(initialTarget);

            if (alertBox) {
                alertBox.style.display = 'none';
                alertBox.className = 'debug-modal-alert';
                alertBox.textContent = '';
            }
            if (executeBtn) {
                executeBtn.disabled = false;
            }
        }

        function closeModal() {
            modal.classList.remove('is-open');
            modal.setAttribute('aria-hidden', 'true');
        }

        document.querySelectorAll('input[name="debugResetTarget"]').forEach(radio => {
            radio.addEventListener('change', function() {
                updateModalStateForTarget(this.value);
            });
        });

        if (openBtnSidebarDatabase) openBtnSidebarDatabase.addEventListener('click', () => openModal('database'));
        if (openBtnSidebar) openBtnSidebar.addEventListener('click', () => openModal('all'));
        if (openBtnSidebarDrafts) openBtnSidebarDrafts.addEventListener('click', () => openModal('drafts'));
        if (openBtnSidebarSubforms) openBtnSidebarSubforms.addEventListener('click', () => openModal('subforms'));
        if (openBtnSidebarDoc) openBtnSidebarDoc.addEventListener('click', () => openModal('documentation'));
        if (openBtnSidebarNotifications) openBtnSidebarNotifications.addEventListener('click', () => openModal('notifications'));
        if (openBtnFallbackDatabase) openBtnFallbackDatabase.addEventListener('click', () => openModal('database'));
        if (openBtnFallback) openBtnFallback.addEventListener('click', () => openModal('all'));
        if (openBtnFallbackDrafts) openBtnFallbackDrafts.addEventListener('click', () => openModal('drafts'));
        if (openBtnFallbackSubforms) openBtnFallbackSubforms.addEventListener('click', () => openModal('subforms'));
        if (openBtnFallbackDoc) openBtnFallbackDoc.addEventListener('click', () => openModal('documentation'));
        if (openBtnFallbackNotifications) openBtnFallbackNotifications.addEventListener('click', () => openModal('notifications'));
        if (closeBtn) closeBtn.addEventListener('click', closeModal);
        if (cancelBtn) cancelBtn.addEventListener('click', closeModal);

        modal.addEventListener('click', function(e) {
            if (e.target === modal) closeModal();
        });

        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && modal.classList.contains('is-open')) {
                closeModal();
            }
        });

        if (executeBtn) {
            executeBtn.addEventListener('click', async function() {
                const template = templateSelect ? templateSelect.value : 'all';
                const scopeRadio = document.querySelector('input[name="debugResetScope"]:checked');
                const scope = scopeRadio ? scopeRadio.value : 'all';
                const targetRadio = document.querySelector('input[name="debugResetTarget"]:checked');
                const target = targetRadio ? targetRadio.value : 'all';
                const includeNotifications = includeNotificationsCheckbox ? includeNotificationsCheckbox.checked : true;

                const auditDateEl = document.getElementById('auditDate') || document.querySelector('input[name="date"]');
                const branchEl = document.getElementById('branchSelect') || document.querySelector('select[name="branch"]');
                const date = scope === 'current' && auditDateEl ? auditDateEl.value : '';
                const branch = scope === 'current' && branchEl ? branchEl.value : '';

                const confirmMsg = target === 'database'
                    ? 'Reset all database activity and checklist data across every branch and date? Users, login and device settings, checklist definitions, restroom dropdowns, and dealer checklist settings will be preserved.'
                    : target === 'drafts'
                    ? 'Are you sure you want to reset the checklist drafts? Submitted history, master templates, and questions will be preserved.'
                    : (target === 'submitted'
                        ? 'Are you sure you want to reset submitted checklist answers? Master templates, questions, and accounts will be preserved.'
                        : (target === 'subforms'
                            ? 'Are you sure you want to reset subform submissions? Core checklist responses, master templates, and accounts will be preserved.'
                            : (target === 'documentation'
                                ? 'Are you sure you want to reset documentation submissions? Core checklist responses, master templates, and accounts will be preserved.'
                                : (target === 'notifications'
                                    ? 'Are you sure you want to reset the notification history? Checklist answers and master templates will be preserved.'
                                    : 'Are you sure you want to reset the checklist answers, subforms, documentation, and notification history? Master templates, questions, and accounts will be preserved.'))));

                if (!confirm(confirmMsg)) {
                    return;
                }

                executeBtn.disabled = true;
                const spinnerLabel = target === 'database'
                    ? 'Resetting database data...'
                    : target === 'drafts'
                    ? 'Resetting drafts…'
                    : (target === 'subforms'
                        ? 'Resetting subforms…'
                        : (target === 'documentation'
                            ? 'Resetting documentation…'
                            : (target === 'notifications' ? 'Resetting notifications…' : 'Resetting answers…')));
                executeBtn.innerHTML = `<i class="fas fa-spinner fa-spin" aria-hidden="true"></i><span>${spinnerLabel}</span>`;
                if (alertBox) alertBox.style.display = 'none';

                try {
                    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
                    const response = await fetch('{{ route('debug.checklists.reset-answers') }}', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': token || ''
                        },
                        body: JSON.stringify({
                            template: template,
                            scope: scope,
                            target: target,
                            include_notifications: includeNotifications,
                            date: date,
                            branch: branch
                        })
                    });

                    const data = await response.json();

                    if (!response.ok) {
                        throw new Error(data.message || 'Failed to reset checklist records.');
                    }

                    if (alertBox) {
                        alertBox.className = 'debug-modal-alert is-success';
                        alertBox.textContent = data.message || 'Checklist records successfully reset.';
                        alertBox.style.display = 'block';
                    }

                    const successLabel = target === 'database'
                        ? 'Database Data Reset!'
                        : target === 'drafts'
                        ? 'Drafts Reset!'
                        : (target === 'subforms'
                            ? 'Subforms Reset!'
                            : (target === 'documentation'
                                ? 'Documentation Reset!'
                                : (target === 'notifications' ? 'Notifications Reset!' : 'Answers Reset!')));
                    executeBtn.innerHTML = `<i class="fas fa-check" aria-hidden="true"></i><span>${successLabel}</span>`;

                    setTimeout(function() {
                        closeModal();
                        window.location.reload();
                    }, 1200);
                } catch (err) {
                    if (alertBox) {
                        alertBox.className = 'debug-modal-alert is-error';
                        alertBox.textContent = err.message || 'Error resetting checklist records.';
                        alertBox.style.display = 'block';
                    }
                    executeBtn.disabled = false;
                    const retryLabel = target === 'drafts'
                        ? 'Try Resetting Drafts Again'
                        : (target === 'subforms'
                            ? 'Try Resetting Subforms Again'
                            : (target === 'documentation'
                                ? 'Try Resetting Documentation Again'
                                : (target === 'notifications' ? 'Try Resetting Notifications Again' : 'Try Again')));
                    executeBtn.innerHTML = `<i class="fas fa-trash-can" aria-hidden="true"></i><span>${retryLabel}</span>`;
                }
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initDebugChecklistReset);
    } else {
        initDebugChecklistReset();
    }
})();
</script>

@include('partials.browser-push')
