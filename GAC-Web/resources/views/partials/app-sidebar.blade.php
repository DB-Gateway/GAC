@php
    $appNavigationGroups = [
        'Operations' => [
            ['route' => 'dashboard', 'active' => ['dashboard', 'reports.*', 'users.*'], 'icon' => 'images/sidebar-icons/website  icon_home.png', 'label' => 'Dashboard'],
            ['route' => 'checklists.index', 'active' => ['checklists.*'], 'icon' => 'images/sidebar-icons/website  icon_audit trail.png', 'label' => 'Checklists'],
        ],
    ];

    $canManageUsers = auth()->user()?->hasAdministrativeAccess() === true;

@endphp

<aside class="sidebar" id="sidebar" aria-label="Primary navigation">
    <a class="logo" href="{{ route('dashboard') }}" aria-label="Gateway Audit Compliance dashboard">
        <span class="logo-mark" aria-hidden="true">
            <img src="{{ asset('images/Gateway_logo_circle.png') }}" alt="" width="56" height="56">
        </span>
        <span class="logo-copy">
            <strong>GATEWAY</strong>
            <span>Audit Compliance System</span>
        </span>
    </a>

    @foreach ($appNavigationGroups as $groupLabel => $items)
        <div class="menu-title">{{ $groupLabel }}</div>

        <ul class="menu">
            @foreach ($items as $item)
                @php($isActive = request()->routeIs(...($item['active'] ?? [$item['route']])))
                <li>
                    <a href="{{ route($item['route']) }}"
                       class="{{ $isActive ? 'active' : '' }}"
                       @if ($isActive) aria-current="page" @endif>
                        <span class="menu-icon" aria-hidden="true">
                            <img src="{{ asset($item['icon']) }}" alt="" width="22" height="22">
                        </span>
                        <span>{{ $item['label'] }}</span>
                    </a>
                </li>
            @endforeach
        </ul>
    @endforeach

    <div class="admin-dropdown sidebar-account" id="adminDropdown">
        {{-- Existing page scripts still target this control; logout itself remains permanently visible. --}}
        <button type="button" class="admin-box shell-account-proxy" id="adminBoxToggle"
                aria-expanded="true" aria-controls="adminMenu" hidden>Account menu</button>

        <div class="admin-menu" id="adminMenu">
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit" class="logout-btn">
                    <i class="fas fa-power-off" aria-hidden="true"></i>
                    <span>Logout</span>
                </button>
            </form>
        </div>
    </div>
</aside>

<div class="sidebar-backdrop" id="sidebarBackdrop" aria-hidden="true"></div>
