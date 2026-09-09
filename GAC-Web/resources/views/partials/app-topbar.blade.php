@php
    $topbarTitle = $topbarTitle ?? 'Administrator Dashboard';
    $topbarSubtitle = $topbarSubtitle ?? 'Gateway Audit Compliance Monitoring System';
    $notificationId = $notificationId ?? null;
    $notificationLabel = $notificationLabel ?? 'Open notifications';
    $notificationBadge = $notificationBadge ?? (isset($notificationBadgeCount) ? (string) $notificationBadgeCount : '0');
    $notificationBadgeCount = max(0, (int) $notificationBadge);
    $notificationBadgeId = $notificationBadgeId ?? ($notificationId ? 'notificationsBadge' : null);
    $showMobileMenu = $showMobileMenu ?? true;
    $account = Auth::user();
    $accountName = $account?->name ?? 'Gateway User';
    $trimmedAccountName = trim($accountName);
    $accountInitials = str($trimmedAccountName)->explode(' ')->filter()->take(2)->map(fn ($part) => str($part)->substr(0, 1)->upper())->join('');
    $accountInitials = $accountInitials === '' ? 'G' : $accountInitials;
    $accountRole = $account?->roleLabel() ?? 'Gateway User';
    $accountBranch = trim((string) ($account?->branch ?? '')) ?: 'Unassigned branch';
    $isProfileActive = request()->routeIs('profile.*');
@endphp

<header class="topbar">
    <div class="topbar-left">
        @if ($showMobileMenu)
            <button class="mobile-menu-button" id="mobileMenuButton" type="button" aria-label="Open navigation">
                <i class="fas fa-bars" aria-hidden="true"></i>
            </button>
        @endif
        <button class="sidebar-toggle" id="sidebarToggle" type="button" aria-label="Collapse navigation" aria-expanded="true">
            <i class="fas fa-bars" aria-hidden="true"></i>
        </button>
        <div class="topbar-title">
            <h1>{{ $topbarTitle }}</h1>
            <p>{{ $topbarSubtitle }}</p>
        </div>
    </div>

    <div class="topbar-actions">
        @if ($notificationId)
            <button class="notifications-btn"
                    id="{{ $notificationId }}"
                    type="button"
                    aria-label="{{ $notificationBadgeCount > 0 ? $notificationLabel.' ('.$notificationBadgeCount.' unread)' : $notificationLabel }}"
                    aria-expanded="false">
                <i class="fas fa-bell" aria-hidden="true"></i>
                @if ($notificationBadgeCount > 0)
                    <span class="notifications-badge" @if ($notificationBadgeId) id="{{ $notificationBadgeId }}" @endif>{{ $notificationBadgeCount }}</span>
                @endif
            </button>
        @endif

        <a class="topbar-account{{ $isProfileActive ? ' active' : '' }}"
           href="{{ route('profile.show') }}"
           aria-label="Open profile for {{ $accountName }}"
           @if ($isProfileActive) aria-current="page" @endif>
            <span class="topbar-avatar" aria-hidden="true">{{ $accountInitials }}</span>
            <span class="topbar-account-copy">
                <strong>{{ $accountName }}</strong>
                <small>{{ $accountRole }} <span aria-hidden="true">&middot;</span> {{ $accountBranch }}</small>
            </span>
        </a>
    </div>
</header>
