@php
    $formatPercent = static fn ($value) => $value === null ? '—' : number_format((float) $value, 1).'%';
    $barWidth = static fn ($value) => min(100, max(0, (float) ($value ?? 0)));
    $reportQuery = array_filter($reportFilters, static fn ($value) => $value !== null && $value !== '');
    $reportsTabUrl = route('dashboard', array_merge(['tab' => 'reports'], $reportQuery));
    $usersTabUrl = route('dashboard', ['tab' => 'users']);
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    @include('partials.browser-push-head')
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#F5F6F8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/dashboard.css') }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
</head>
<body class="gateway-dashboard gateway-page-dashboard">
    <div class="sidebar-trigger" aria-hidden="true"></div>
    @include('layouts.navigation')

    <div class="main" id="mainShell">
        @include('partials.app-topbar', [
            'notificationId' => 'notificationsBtn',
            'notificationBadge' => (string) $notificationBadgeCount,
            'notificationBadgeId' => 'notificationsBadge',
            'showMobileMenu' => false,
        ])

        <main class="dashboard-content">
            @if ($activeTab === 'follow-up' && $canAccessFollowUp)
                <section class="workspace-panel follow-up-workspace" id="workspace-panel-follow-up" aria-label="Finding follow-up">
                    @include('dashboard.follow-up')
                </section>
            @elseif ($activeTab === 'override')
                <section class="workspace-panel override-workspace" id="workspace-panel-override" aria-label="Checklist override">
                    @include('dashboard.override')
                </section>
            @elseif ($activeTab === 'reports')
                <section class="workspace-panel" id="workspace-panel-reports" aria-label="Reports and analytics">
                    @include('dashboard.reports')
                </section>
            @elseif ($activeTab === 'users' && $canViewUserUsages)
                <section class="workspace-panel" id="workspace-panel-users" aria-label="User usages">
                    @include('dashboard.users')
                </section>
            @else
                <section class="workspace-panel" id="workspace-panel-overview" aria-label="Dashboard overview">
                    @include('dashboard.overview')
                </section>
            @endif

            <footer class="footer">
                Gateway Audit Compliance System &copy; {{ now()->year }}
                <br>
                Dealer Operations Standards &bull; Sales &bull; Service &bull; Restroom Compliance
            </footer>
        </main>
    </div>

    @include('partials.notifications-modal')

    <script>
        (() => {
            const sidebarToggle = document.getElementById('sidebarToggle');
            const sidebar = document.getElementById('sidebar');
            const mainShell = document.getElementById('mainShell');
            const sidebarBackdrop = document.getElementById('sidebarBackdrop');

            const setDesktopSidebarCollapsed = (collapsed) => {
                if (!sidebar || !mainShell || !sidebarToggle) return;

                sidebar.classList.toggle('desktop-collapsed', collapsed);
                mainShell.classList.toggle('sidebar-collapsed', collapsed);
                sidebarToggle.classList.toggle('is-active', collapsed);
                sidebarToggle.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
                sidebarToggle.setAttribute('aria-label', collapsed ? 'Expand navigation' : 'Collapse navigation');
                const icon = sidebarToggle.querySelector('i');
                if (icon) icon.className = collapsed ? 'fas fa-angles-right' : 'fas fa-angles-left';
                localStorage.setItem('gatewaySidebarCollapsed', collapsed ? '1' : '0');
            };

            sidebarToggle?.addEventListener('click', () => {
                if (!sidebar) return;

                if (window.innerWidth <= 900) {
                    const isOpen = sidebar.classList.toggle('mobile-open');
                    sidebarBackdrop?.classList.toggle('visible', isOpen);
                    return;
                }

                setDesktopSidebarCollapsed(!sidebar.classList.contains('desktop-collapsed'));
            });

            sidebarBackdrop?.addEventListener('click', () => {
                sidebar?.classList.remove('mobile-open');
                sidebarBackdrop.classList.remove('visible');
            });

            if (localStorage.getItem('gatewaySidebarCollapsed') === '1' && window.innerWidth > 900) {
                setDesktopSidebarCollapsed(true);
            }

            document.getElementById('printDashboardReport')?.addEventListener('click', () => window.print());

            document.addEventListener('keydown', (event) => {
                if (event.key !== 'Escape') return;
                sidebar?.classList.remove('mobile-open');
                sidebarBackdrop?.classList.remove('visible');
            });
        })();
    </script>
</body>
</html>
