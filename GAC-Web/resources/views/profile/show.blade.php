@php
    $roleLabel = $user->roleLabel();
    $isAdministrator = $user->hasAdministrativeAccess();
    $roleBadge = $isAdministrator ? 'badge-success' : ($user->roleCode() === \App\Models\User::ROLE_BRANCH_OPERATIONS_MANAGER ? 'badge-warning' : 'badge-neutral');
    $branchAccess = $isAdministrator ? 'All branches' : (trim((string) $user->branch) ?: 'Unassigned');
@endphp

<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    @include('partials.browser-push-head')
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="theme-color" content="#F5F6F8">
    <title>My Profile | Gateway Audit Compliance</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/users-des.css') }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
    <link rel="stylesheet" href="{{ asset('css/profile-des.css') }}">
</head>
<body class="gateway-dashboard gateway-page-profile">
    @include('layouts.navigation')

    <div class="main-shell" id="mainShell">
        @include('partials.app-topbar', [
            'topbarTitle' => 'My Profile',
            'topbarSubtitle' => 'Signed-in account and access information',
            'notificationId' => 'notificationsBtn',
        ])

        <main class="content profile-content">
            <div class="page-heading profile-heading">
                <div>
                    <p class="page-eyebrow">Signed-in account</p>
                    <h2 class="page-title">My profile</h2>
                    <p class="page-description">Your login identity and current access level for the Gateway Audit Compliance System.</p>
                </div>

                <div class="button-row">
                    <a class="button button-back" href="{{ route('dashboard') }}" data-history-back>
                        <svg aria-hidden="true" viewBox="0 0 20 20" fill="none">
                            <path d="M16.25 10H3.75M8.75 5 3.75 10l5 5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.7" />
                        </svg>
                        <span>Back</span>
                    </a>

                    @if ($isAdministrator)
                        <a class="button button-primary" href="{{ route('users.index', ['search' => $user->email]) }}">Edit account</a>
                    @endif
                </div>
            </div>

            <section class="panel profile-panel" aria-labelledby="profile-name">
                <div class="users-panel-header">
                    <div class="user-identity">
                        <span class="user-avatar" aria-hidden="true">{{ str($user->name)->explode(' ')->filter()->take(2)->map(fn ($part) => str($part)->substr(0, 1)->upper())->join('') }}</span>
                        <span>
                            <span class="cell-primary" id="profile-name">{{ $user->name }}</span>
                            <span class="cell-secondary">Account ID {{ $user->id }}</span>
                        </span>
                    </div>
                    <span class="badge {{ $roleBadge }}">{{ $roleLabel }}</span>
                </div>

                <div class="detail-grid">
                    <div class="detail-item">
                        <span class="detail-label">Username</span>
                        <span class="detail-value">{{ $user->email }}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Access level</span>
                        <span class="detail-value">{{ $roleLabel }}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Branch access</span>
                        <span class="detail-value">{{ $branchAccess }}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Account created</span>
                        <span class="detail-value">{{ $user->created_at?->format('F j, Y \a\t g:i A') ?? 'Not available' }}</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Last updated</span>
                        <span class="detail-value">{{ $user->updated_at?->format('F j, Y \a\t g:i A') ?? 'Not available' }}</span>
                    </div>
                </div>
            </section>
        </main>
    </div>

    <script>
        (() => {
            const sidebar = document.getElementById('sidebar');
            const sidebarToggle = document.getElementById('sidebarToggle');
            const mobileMenuButton = document.getElementById('mobileMenuButton');
            const sidebarBackdrop = document.getElementById('sidebarBackdrop');
            const mainShell = document.getElementById('mainShell');
            const storageKey = 'gatewaySidebarCollapsed';

            const closeMobileSidebar = () => {
                sidebar?.classList.remove('mobile-open', 'open');
                sidebarBackdrop?.classList.remove('visible', 'open');
            };

            const setDesktopSidebarCollapsed = (collapsed) => {
                sidebar?.classList.toggle('desktop-collapsed', collapsed);
                mainShell?.classList.toggle('sidebar-collapsed', collapsed);
                sidebarToggle?.classList.toggle('is-active', collapsed);
                sidebarToggle?.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
                sidebarToggle?.setAttribute('aria-label', collapsed ? 'Expand navigation' : 'Collapse navigation');

                const icon = sidebarToggle?.querySelector('i');
                if (icon) icon.className = collapsed ? 'fas fa-angles-right' : 'fas fa-angles-left';

                try {
                    localStorage.setItem(storageKey, collapsed ? '1' : '0');
                } catch (error) {
                    // The sidebar remains usable when browser storage is unavailable.
                }
            };

            sidebarToggle?.addEventListener('click', () => {
                setDesktopSidebarCollapsed(!sidebar?.classList.contains('desktop-collapsed'));
            });

            mobileMenuButton?.addEventListener('click', () => {
                const isOpen = !sidebar?.classList.contains('mobile-open');
                sidebar?.classList.toggle('mobile-open', isOpen);
                sidebar?.classList.toggle('open', isOpen);
                sidebarBackdrop?.classList.toggle('visible', isOpen);
                sidebarBackdrop?.classList.toggle('open', isOpen);
            });

            sidebarBackdrop?.addEventListener('click', closeMobileSidebar);
            document.addEventListener('keydown', (event) => {
                if (event.key === 'Escape') closeMobileSidebar();
            });

            try {
                if (localStorage.getItem(storageKey) === '1' && window.innerWidth > 900) {
                    setDesktopSidebarCollapsed(true);
                }
            } catch (error) {
                // Use the expanded default when browser storage is unavailable.
            }
        })();
    </script>

    @include('partials.notifications-modal')
</body>
</html>
