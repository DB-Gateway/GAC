@if (request()->routeIs(['dashboard', 'checklists.*', 'reports.*', 'users.*', 'profile.*']))
    @php
        $hasManagerNavigation = auth()->user()?->hasAdministrativeAccess() === true
            || auth()->user()?->roleCode() === \App\Models\User::ROLE_BRANCH_OPERATIONS_MANAGER;
        $dashboardSection = null;

        if (request()->routeIs('dashboard')) {
            $requestedDashboardSection = mb_strtolower(trim((string) request()->query('tab', 'overview')));
            $dashboardSection = in_array($requestedDashboardSection, ['overview', 'reports', 'users'], true)
                ? $requestedDashboardSection
                : 'overview';

            if ($dashboardSection === 'users' && ! $hasManagerNavigation) {
                $dashboardSection = 'overview';
            }
        }

        $dashboardIsActive = request()->routeIs('dashboard') && $dashboardSection === 'overview';
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

        if (! $hasManagerNavigation) {
            $appNavigationItems[] = [
                'route' => 'checklists.index',
                'active' => ['checklists.*'],
                'icon' => 'images/sidebar-icons/website  icon_audit trail.png',
                'label' => 'Checklists',
            ];
        }

        $checklistEditorGroups = [
            [
                'label' => '5S Checklist',
                'items' => [
                    ['label' => 'Sales 5S', 'slug' => 'sales'],
                    ['label' => 'Service 5S', 'slug' => 'service'],
                ],
            ],
            [
                'label' => 'DOS Checklist',
                'items' => [
                    ['label' => 'Sales DOS', 'slug' => 'dealer-operations-standards-sales'],
                    ['label' => 'Aftersales DOS', 'slug' => 'dealer-operations-standards'],
                ],
            ],
            [
                'label' => 'Utilities Checklist',
                'items' => [
                    ['label' => 'Restroom', 'slug' => 'restroom'],
                ],
            ],
        ];

        $currentChecklist = request()->routeIs('checklists.*')
            ? (string) request()->query('checklist', 'dealer-operations-standards')
            : null;
        $currentChecklist = match ($currentChecklist) {
            'dealer-operations', 'dos' => 'dealer-operations-standards',
            'gateway-5s', '5s' => 'sales',
            'utilities' => 'restroom',
            default => $currentChecklist,
        };
        $editorIsActive = $hasManagerNavigation && request()->routeIs('checklists.*');
        $editorContext = array_filter(
            request()->only(['branch', 'date']),
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
                           href="{{ route($item['route']) }}"
                           @if ($isActive) aria-current="page" @endif>
                            <span class="menu-icon nav-icon" aria-hidden="true">
                                <img src="{{ asset($item['icon']) }}" alt="" width="22" height="22">
                            </span>
                            <span>{{ $item['label'] }}</span>
                        </a>
                    </li>
                @endforeach

                @if ($hasManagerNavigation)
                    <li class="sidebar-editor-item">
                        <details class="sidebar-editor" id="editorDropdown" open>
                            <summary class="sidebar-editor-toggle{{ $editorIsActive ? ' active' : '' }}"
                                     aria-controls="editorMenu">
                                <span class="menu-icon nav-icon" aria-hidden="true">
                                    <img src="{{ asset('images/sidebar-icons/website  icon_audit trail.png') }}" alt="" width="22" height="22">
                                </span>
                                <span>Editor</span>
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
                                        <span>User Usages</span>
                                    </a>
                                </li>
                            @endif
                        </ul>
                    </details>
                </li>

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
                                        id="sidebarDebugResetBtn"
                                        title="Reset checklist answers">
                                    <span class="sidebar-editor-dot" style="background: #FF4D6D;" aria-hidden="true"></span>
                                    <span>Reset Checklist</span>
                                </button>
                            </li>
                        </ul>
                    </details>
                </li>
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
                        id="fallbackDebugResetBtn"
                        class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-100 flex items-center gap-2 font-medium">
                    <i class="fas fa-bug" aria-hidden="true"></i>
                    <span>Debug: Reset Checklist</span>
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
                <span class="debug-modal-badge" aria-hidden="true">
                    <i class="fas fa-bug"></i>
                </span>
                <div>
                    <h3 id="debugResetModalTitle">Debug: Reset Checklist Answers</h3>
                    <p>Clear answer entries while preserving master items &amp; accounts.</p>
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
                    <p>Only checklist answers (user responses, drafts, and submissions) will be reset. Master checklist templates, sections, questions, rating rules, and user accounts will <strong>NEVER</strong> be deleted or altered.</p>
                </div>
            </div>

            <div class="debug-modal-field">
                <label for="debugTemplateSelect">Select Checklist to Reset</label>
                <select id="debugTemplateSelect" class="debug-select-control">
                    @if (isset($currentChecklist) && $currentChecklist)
                        <option value="{{ $currentChecklist }}" selected>Current Checklist ({{ ucwords(str_replace('-', ' ', $currentChecklist)) }})</option>
                    @endif
                    <option value="all" @if (!isset($currentChecklist) || !$currentChecklist) selected @endif>All Checklists (All Types)</option>
                    <option value="dealer-operations-standards">Dealer Operations Standards (Aftersales)</option>
                    <option value="dealer-operations-standards-sales">Dealer Operations Standards (Sales)</option>
                    <option value="sales">Sales 5S Checklist</option>
                    <option value="service">Service 5S Checklist</option>
                    <option value="restroom">Restroom Checklist</option>
                </select>
            </div>

            <div class="debug-modal-field">
                <label>Reset Scope</label>
                <div class="debug-scope-options">
                    <label class="debug-radio-label">
                        <input type="radio" name="debugResetScope" value="all" checked>
                        <span>
                            <strong>All entries</strong>
                            <small>Clears all drafts and submitted answers across all dates and branches.</small>
                        </span>
                    </label>
                    @if (isset($currentChecklist) && $currentChecklist)
                        <label class="debug-radio-label" id="debugScopeCurrentLabel">
                            <input type="radio" name="debugResetScope" value="current">
                            <span>
                                <strong>Current branch &amp; date only</strong>
                                <small>Only clear answers for the active branch &amp; date being viewed.</small>
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

        const openBtnSidebar = document.getElementById('sidebarDebugResetBtn');
        const openBtnFallback = document.getElementById('fallbackDebugResetBtn');
        const closeBtn = document.getElementById('debugResetModalClose');
        const cancelBtn = document.getElementById('debugResetModalCancel');
        const executeBtn = document.getElementById('debugResetExecuteBtn');
        const templateSelect = document.getElementById('debugTemplateSelect');
        const alertBox = document.getElementById('debugResetAlert');

        function openModal() {
            modal.classList.add('is-open');
            modal.setAttribute('aria-hidden', 'false');
            if (alertBox) {
                alertBox.style.display = 'none';
                alertBox.className = 'debug-modal-alert';
                alertBox.textContent = '';
            }
            if (executeBtn) {
                executeBtn.disabled = false;
                executeBtn.innerHTML = '<i class="fas fa-trash-can" aria-hidden="true"></i><span>Reset Answers</span>';
            }
        }

        function closeModal() {
            modal.classList.remove('is-open');
            modal.setAttribute('aria-hidden', 'true');
        }

        if (openBtnSidebar) openBtnSidebar.addEventListener('click', openModal);
        if (openBtnFallback) openBtnFallback.addEventListener('click', openModal);
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

                const auditDateEl = document.getElementById('auditDate') || document.querySelector('input[name="date"]');
                const branchEl = document.getElementById('branchSelect') || document.querySelector('select[name="branch"]');
                const date = auditDateEl ? auditDateEl.value : '';
                const branch = branchEl ? branchEl.value : '';

                if (!confirm('Are you sure you want to reset the checklist answers? Master templates, questions, and accounts will be preserved.')) {
                    return;
                }

                executeBtn.disabled = true;
                executeBtn.innerHTML = '<i class="fas fa-spinner fa-spin" aria-hidden="true"></i><span>Resetting answers…</span>';
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
                            date: date,
                            branch: branch
                        })
                    });

                    const data = await response.json();

                    if (!response.ok) {
                        throw new Error(data.message || 'Failed to reset checklist answers.');
                    }

                    if (alertBox) {
                        alertBox.className = 'debug-modal-alert is-success';
                        alertBox.textContent = data.message || 'Checklist answers successfully reset.';
                        alertBox.style.display = 'block';
                    }

                    executeBtn.innerHTML = '<i class="fas fa-check" aria-hidden="true"></i><span>Answers Reset!</span>';

                    setTimeout(function() {
                        closeModal();
                        window.location.reload();
                    }, 1200);
                } catch (err) {
                    if (alertBox) {
                        alertBox.className = 'debug-modal-alert is-error';
                        alertBox.textContent = err.message || 'Error resetting checklist answers.';
                        alertBox.style.display = 'block';
                    }
                    executeBtn.disabled = false;
                    executeBtn.innerHTML = '<i class="fas fa-trash-can" aria-hidden="true"></i><span>Try Again</span>';
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
