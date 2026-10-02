<!DOCTYPE html>
<html lang="en">
<head>
    @include('partials.browser-push-head')
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#F5F6F8">
    <title>Gateway Audit Compliance | Checklist Availability</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/users-des.css') }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
    <style>
        /* Branch navigation and checklist workspace */
        .availability-grid {
            display: grid;
            grid-template-columns: minmax(250px, 300px) minmax(0, 1fr);
            gap: 18px;
            align-items: start;
            margin-bottom: 40px;
        }
        .branch-panel,
        .modules-panel {
            min-width: 0;
            background: #ffffff;
            border: 1px solid var(--line, #e2e8f0);
            border-radius: var(--radius, 16px);
            box-shadow: var(--shadow, 0 4px 18px rgba(15, 23, 42, 0.05));
        }
        .workspace-heading {
            padding: 18px 20px 14px;
            border-bottom: 1px solid #e9edf2;
        }
        .workspace-heading h3 {
            margin: 0 0 4px;
            color: var(--graphite-900, #0f172a);
            font-size: 15px;
            font-weight: 800;
        }
        .workspace-heading p {
            margin: 0;
            color: var(--slate-600, #64748b);
            font-size: 12px;
            line-height: 1.5;
        }
        .branch-list {
            max-height: min(68vh, 720px);
            overflow-y: auto;
            padding: 9px;
            scrollbar-color: #cbd5e1 transparent;
        }
        .branch-choice {
            display: block;
            width: 100%;
            margin: 0 0 5px;
            padding: 11px 12px;
            text-align: left;
            background: #ffffff;
            border: 1px solid transparent;
            border-radius: 10px;
            color: var(--graphite-900, #0f172a);
            cursor: pointer;
        }
        .branch-choice:hover { background: #f8fafc; border-color: #e2e8f0; }
        .branch-choice.is-selected {
            background: #fff4f5;
            border-color: var(--gateway-red-500, #e31c3d);
            box-shadow: inset 3px 0 var(--gateway-red-500, #e31c3d);
        }
        .branch-choice:focus-visible { outline: 3px solid rgba(227, 28, 61, 0.35); outline-offset: 2px; }
        .branch-choice-name { display: block; font-size: 13px; font-weight: 750; line-height: 1.35; }
        .branch-choice-meta { display: flex; flex-wrap: wrap; gap: 4px 8px; margin-top: 4px; color: #64748b; font-size: 11px; }
        .branch-empty { padding: 18px 12px; color: #64748b; font-size: 12px; text-align: center; }
        .modules-panel-body { padding: 18px; }
        .availability-card[hidden], .branch-choice[hidden], .branch-empty[hidden] { display: none; }
        @media (max-width: 900px) {
            .availability-grid { grid-template-columns: 1fr; }
            .branch-list { max-height: 250px; }
        }

        /* Availability Card */
        .availability-card {
            padding: 0;
            display: flex;
            flex-direction: column;
        }

        /* Card Header */
        .card-header-bar {
            margin-bottom: 16px;
            padding-bottom: 14px;
            border-bottom: 1px solid #f1f5f9;
        }
        .card-title-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 6px;
        }
        .card-dealer-name {
            display: flex;
            align-items: center;
            gap: 9px;
            margin: 0;
            color: var(--graphite-900, #0f172a);
            font-size: 18px;
            font-weight: 800;
            line-height: 1.3;
        }
        .card-dealer-name i {
            color: var(--gateway-red-500, #e31c3d);
            font-size: 16px;
        }
        .card-tags {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
        }
        .region-badge {
            font-size: 11px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 6px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #e2e8f0;
        }
        .region-badge.ncr { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
        .region-badge.visayas { background: #f0fdf4; color: #15803d; border-color: #bbf7d0; }
        .region-badge.mindanao { background: #fdf4ff; color: #86198f; border-color: #f5d0fe; }
        .region-badge.other { background: #f8fafc; color: #64748b; border-color: #e2e8f0; }

        .badge-pill {
            font-size: 11px;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .pill-success { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
        .pill-warning { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; }
        .pill-danger { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
        .pill-neutral { background: #f8fafc; color: #475569; border: 1px solid #e2e8f0; }

        .card-desc-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-top: 6px;
        }
        .card-desc-row p {
            margin: 0;
            color: var(--slate-600, #64748b);
            font-size: 12.5px;
        }
        .card-bulk-actions {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            flex-shrink: 0;
        }
        .btn-micro {
            font-size: 11px;
            font-weight: 600;
            padding: 3px 8px;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            background: #ffffff;
            color: #475569;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .btn-micro:hover {
            background: #f1f5f9;
            color: #0f172a;
            border-color: #94a3b8;
        }

        /* Section Headings inside Card */
        .card-section-label {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 11px;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            color: var(--slate-600, #64748b);
            margin: 12px 0 8px;
        }
        .card-section-label span {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        /* Checklist Options */
        .categories-list {
            display: flex;
            flex-direction: column;
            gap: 7px;
        }
        .availability-option {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            padding: 9px 12px;
            background: #fafbfc;
            border: 1px solid #eef2f7;
            border-radius: 10px;
            transition: background 0.15s, border-color 0.15s;
        }
        .availability-option:hover {
            background: #ffffff;
            border-color: #e2e8f0;
        }
        .option-main {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .option-icon-box {
            width: 32px;
            height: 32px;
            display: grid;
            place-items: center;
            border-radius: 8px;
            background: #f1f5f9;
            color: #334155;
            font-size: 13px;
            flex-shrink: 0;
            transition: all 0.15s;
        }
        .availability-option.is-enabled .option-icon-box {
            background: #e8f0fe;
            color: var(--info-blue-500, #2f6fed);
        }
        .option-info strong {
            display: block;
            font-size: 13px;
            color: #1e293b;
            font-weight: 700;
            line-height: 1.25;
        }
        .option-info small {
            display: block;
            color: #64748b;
            font-size: 11.5px;
            margin-top: 1px;
        }
        .availability-option.is-enabled .option-info small {
            color: #16a34a;
        }

        /* Switch */
        .availability-switch {
            position: relative;
            width: 44px;
            height: 24px;
            flex: 0 0 auto;
        }
        .availability-switch input { position: absolute; opacity: 0; width: 0; height: 0; }
        .availability-switch span {
            position: absolute;
            inset: 0;
            border-radius: 999px;
            background: #cbd5e1;
            cursor: pointer;
            transition: background 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .availability-switch span::after {
            content: "";
            position: absolute;
            width: 18px;
            height: 18px;
            left: 3px;
            top: 3px;
            border-radius: 50%;
            background: #ffffff;
            box-shadow: 0 2px 5px rgba(15, 23, 42, 0.22);
            transition: transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .availability-switch input:checked + span {
            background: #16a34a;
        }
        .availability-switch input:checked + span::after {
            transform: translateX(20px);
        }
        .availability-switch input:focus-visible + span {
            outline: 3px solid rgba(227, 28, 61, 0.4);
            outline-offset: 2px;
        }

        /* Restrooms section styling */
        .restrooms-section {
            margin-top: 18px;
            padding-top: 16px;
            border-top: 1px dashed #e2e8f0;
        }
        .restrooms-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 12px;
        }
        .restrooms-header h4 {
            margin: 0;
            font-size: 13.5px;
            font-weight: 700;
            color: #0f172a;
            display: flex;
            align-items: center;
            gap: 7px;
        }
        .restrooms-header h4 i { color: #2563eb; }
        .btn-add-restroom {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 11.5px;
            font-weight: 700;
            padding: 5px 10px;
            background: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
            border-radius: 7px;
            cursor: pointer;
            transition: all 0.15s ease;
        }
        .btn-add-restroom:hover {
            background: #dbeafe;
            color: #1e40af;
            border-color: #93c5fd;
        }

        .restroom-list {
            display: flex;
            flex-direction: column;
            gap: 9px;
        }
        .restroom-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 11px;
            padding: 10px 12px;
            transition: border-color 0.15s, background 0.15s;
        }
        .restroom-card:hover {
            border-color: #cbd5e1;
            background: #ffffff;
        }
        .restroom-card-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            margin-bottom: 7px;
        }
        .restroom-card-title {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12.5px;
            font-weight: 700;
            color: #1e293b;
        }
        .area-badge {
            font-size: 10.5px;
            font-weight: 700;
            padding: 2px 7px;
            border-radius: 999px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        .area-badge.customer { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }
        .area-badge.office { background: #f5f3ff; color: #5b21b6; border: 1px solid #ddd6fe; }
        .restroom-controls {
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .btn-action-icon {
            background: transparent;
            border: none;
            color: #64748b;
            cursor: pointer;
            padding: 4px 6px;
            border-radius: 6px;
            font-size: 12px;
            transition: all 0.15s;
        }
        .btn-action-icon:hover { color: #1e293b; background: #e2e8f0; }
        .btn-action-icon.delete:hover { color: #dc2626; background: #fee2e2; }
        .btn-action-icon:disabled,
        .btn-add-restroom:disabled {
            cursor: not-allowed;
            opacity: .45;
            pointer-events: none;
        }
        .restrooms-section.is-disabled .restroom-card,
        .restrooms-section.is-disabled .empty-restrooms-box {
            opacity: .62;
        }
        .restrooms-disabled-note {
            display: none;
            margin: 0 0 10px;
            padding: 9px 11px;
            border: 1px solid #fecaca;
            border-radius: 8px;
            background: #fff1f2;
            color: #9f1239;
            font-size: 12px;
            font-weight: 650;
        }
        .restrooms-section.is-disabled .restrooms-disabled-note { display: block; }
        .restrooms-section.is-disabled .switch-label {
            cursor: not-allowed;
            opacity: .55;
        }

        .restroom-switches {
            display: flex;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            font-size: 12px;
            color: #475569;
            background: #ffffff;
            padding: 5px 9px;
            border-radius: 7px;
            border: 1px solid #f1f5f9;
        }
        .switch-label {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 12px;
            cursor: pointer;
            font-weight: 500;
        }
        .switch-label input[type="checkbox"] { width: 14px; height: 14px; accent-color: #16a34a; cursor: pointer; }
        .badge-no-pwd { font-size: 11px; color: #94a3b8; font-style: italic; }

        .empty-restrooms-box {
            background: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 10px;
            padding: 14px;
            text-align: center;
        }
        .empty-restrooms-box p {
            margin: 0 0 8px;
            font-size: 12px;
            color: #64748b;
        }

        .availability-actions {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            margin-top: 18px;
            padding-top: 14px;
            border-top: 1px solid #f1f5f9;
        }

        /* Filter Panel Enhancement */
        .checklist-filters {
            display: grid;
            grid-template-columns: minmax(200px, 1.6fr) repeat(6, minmax(130px, 1fr)) auto;
            gap: 12px;
            align-items: end;
            background: #ffffff;
            border: 1px solid var(--line, #e2e8f0);
            border-radius: var(--radius, 12px);
            padding: 16px;
            margin-bottom: 14px;
            box-shadow: 0 2px 10px rgba(11, 15, 26, 0.05);
        }
        .checklist-filters .field {
            margin-bottom: 0;
        }
        .checklist-filters .field label {
            display: block;
            margin-bottom: 5px;
            font-size: 10.5px;
            font-weight: 800;
            color: var(--slate-600, #4b5563);
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .checklist-filters .field input,
        .checklist-filters .field select {
            width: 100%;
            min-height: 38px;
            padding: 7px 11px;
            border: 1px solid var(--line-dark, #8a94a6);
            border-radius: 8px;
            font-size: 12.5px;
            background: #ffffff;
            color: var(--graphite-900, #0b0f1a);
        }
        .checklist-filters .filter-actions {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 1px;
        }

        @media (max-width: 1400px) {
            .checklist-filters {
                grid-template-columns: repeat(3, minmax(180px, 1fr)) auto;
            }
        }
        @media (max-width: 900px) {
            .checklist-filters {
                grid-template-columns: repeat(2, 1fr);
            }
            .checklist-filters .filter-actions {
                grid-column: span 2;
                justify-content: flex-start;
            }
        }
        @media (max-width: 600px) {
            .checklist-filters {
                grid-template-columns: 1fr;
            }
            .checklist-filters .filter-actions {
                grid-column: span 1;
            }
        }

        /* Filter Results Bar */
        .filter-meta-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 18px;
            padding: 8px 14px;
            background: #ffffff;
            border: 1px solid var(--line, #e2e8f0);
            border-radius: 9px;
            font-size: 12px;
            color: var(--slate-600, #64748b);
        }
        .filter-meta-chips {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
        }
        .active-filter-chip {
            background: #eff6ff;
            color: #1d4ed8;
            border: 1px solid #bfdbfe;
            border-radius: 999px;
            padding: 2px 8px;
            font-size: 11px;
            font-weight: 600;
        }

        /* Modal styling */
        .modal-backdrop {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.55);
            backdrop-filter: blur(3px);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }
        .modal-backdrop.open { display: flex; }
        .modal-box {
            background: #ffffff;
            border-radius: 16px;
            width: 92%;
            max-width: 480px;
            padding: 24px;
            box-shadow: 0 20px 40px rgba(15, 23, 42, 0.2);
            border: 1px solid #e2e8f0;
            animation: modalIn 0.15s ease-out;
        }
        @keyframes modalIn { from { opacity: 0; transform: scale(0.96); } to { opacity: 1; transform: scale(1); } }
        .modal-box h3 { margin: 0 0 6px; font-size: 17px; font-weight: 700; color: #0f172a; }
        .modal-box p { margin: 0 0 18px; font-size: 13px; color: #64748b; }
        .modal-form-group { margin-bottom: 14px; }
        .modal-form-group label { display: block; font-size: 12px; font-weight: 600; color: #334155; margin-bottom: 5px; }
        .modal-form-group input[type="text"], .modal-form-group select {
            width: 100%;
            box-sizing: border-box;
            padding: 9px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            color: #1e293b;
        }
        .modal-form-group input[type="text"]:focus, .modal-form-group select:focus {
            outline: none;
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }
        .modal-switches-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 12px;
            display: flex;
            gap: 16px;
            margin-top: 8px;
        }
        .modal-footer {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 20px;
        }
        .btn-modal-cancel {
            padding: 8px 14px;
            border: 1px solid #cbd5e1;
            background: #ffffff;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            color: #475569;
            cursor: pointer;
        }
        .btn-modal-submit {
            padding: 8px 16px;
            border: none;
            background: var(--gateway-red-500, #e31c3d);
            color: #ffffff;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            transition: background 0.15s ease;
        }
        .btn-modal-submit:hover { background: var(--gateway-red-600, #c4162f); }
    </style>
</head>
<body class="gateway-dashboard gateway-page-users">
    @include('layouts.navigation')

    <div class="main-shell" id="mainShell">
        @include('partials.app-topbar', [
            'topbarTitle' => 'Checklist Availability',
            'topbarSubtitle' => 'Administrator controls by dealer / brand',
            'notificationId' => 'notificationsBtn',
        ])

        <main class="content">
            <section class="page-heading">
                <div>
                    <span class="eyebrow"><span class="eyebrow-dot"></span> Access assignment</span>
                    <h2>Dealer / Brand Checklist Availability</h2>
                    <p>Switch each approved checklist category on or off, and configure specific Customer Area and Office Restrooms (Male, Female, PWD) for each branch. Changes reflect immediately across both web and mobile apps.</p>
                </div>
                <div class="header-actions">
                    <a class="button" href="{{ route('dashboard', ['tab' => 'users']) }}"><i class="fas fa-chart-line"></i>User Usage</a>
                    <a class="button" href="{{ route('users.index') }}"><i class="fas fa-users-gear"></i>Manage Users</a>
                </div>
            </section>

            @if (session('status'))
                <section class="notice" role="status">
                    <span class="notice-icon"><i class="fas fa-circle-check"></i></span>
                    <div><strong>{{ session('status') }}</strong><p>The website and app access rules are effective immediately.</p></div>
                </section>
            @endif

            {{-- Summary Stats Grid --}}
            @if (isset($stats))
                <section class="stats-grid" aria-label="Checklist availability network overview">
                    <article class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Total Branches</span>
                            <span class="stat-icon"><i class="fas fa-building"></i></span>
                        </div>
                        <div class="stat-value">{{ $stats['total'] }}</div>
                        <div class="stat-meta">Configured dealerships & brands</div>
                    </article>
                    <article class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Full Availability</span>
                            <span class="stat-icon"><i class="fas fa-circle-check"></i></span>
                        </div>
                        <div class="stat-value">{{ $stats['fully_enabled'] }}</div>
                        <div class="stat-meta">All 5 checklist modules active</div>
                    </article>
                    <article class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Custom Access</span>
                            <span class="stat-icon"><i class="fas fa-sliders"></i></span>
                        </div>
                        <div class="stat-value">{{ $stats['restricted'] }}</div>
                        <div class="stat-meta">Branches with restricted modules</div>
                    </article>
                    <article class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Total Restrooms</span>
                            <span class="stat-icon"><i class="fas fa-restroom"></i></span>
                        </div>
                        <div class="stat-value">{{ $stats['restrooms'] }}</div>
                        <div class="stat-meta">Configured facility checklists</div>
                    </article>
                    <article class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Customer Facilities</span>
                            <span class="stat-icon"><i class="fas fa-users-viewfinder"></i></span>
                        </div>
                        <div class="stat-value">{{ $stats['customer_restrooms'] }}</div>
                        <div class="stat-meta">Showroom & lounge restrooms</div>
                    </article>
                    <article class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Office Facilities</span>
                            <span class="stat-icon"><i class="fas fa-briefcase"></i></span>
                        </div>
                        <div class="stat-value">{{ $stats['office_restrooms'] }}</div>
                        <div class="stat-meta">Administrative staff restrooms</div>
                    </article>
                </section>
            @endif

            {{-- Advanced Filter Panel --}}
            <form class="panel checklist-filters" method="GET" action="{{ route('admin.checklist-access.index') }}" aria-label="Checklist availability filters" id="filterForm">
                <div class="field">
                    <label for="dealerSearch">Search Branch</label>
                    <input id="dealerSearch" name="search" type="search" value="{{ request('search', $filters['search'] ?? '') }}" placeholder="Branch name, keyword..." autocomplete="off">
                </div>

                <div class="field">
                    <label for="brandFilter">Brand Name</label>
                    <select id="brandFilter" name="brand">
                        <option value="">All Brands</option>
                        @foreach ($brands as $brand)
                            <option value="{{ $brand }}" @selected(($filters['brand'] ?? '') === $brand)>{{ $brand }}</option>
                        @endforeach
                        <option value="Unspecified Brand" @selected(($filters['brand'] ?? '') === 'Unspecified Brand')>Unspecified Brand</option>
                    </select>
                </div>

                <div class="field">
                    <label for="regionFilter">Region</label>
                    <select id="regionFilter" name="region">
                        <option value="">All Regions</option>
                        @foreach ($regions ?? ['NCR', 'Visayas', 'Mindanao'] as $reg)
                            <option value="{{ $reg }}" @selected(request('region', $filters['region'] ?? '') === $reg)>{{ $reg }}</option>
                        @endforeach
                        <option value="Other" @selected(request('region', $filters['region'] ?? '') === 'Other')>Other / Unassigned</option>
                    </select>
                </div>

                <div class="field">
                    <label for="statusFilter">Module Status</label>
                    <select id="statusFilter" name="status">
                        <option value="">All Statuses</option>
                        <option value="fully_enabled" @selected(request('status', $filters['status'] ?? '') === 'fully_enabled')>Full Access (5/5 Active)</option>
                        <option value="restricted" @selected(request('status', $filters['status'] ?? '') === 'restricted')>Partially Restricted</option>
                        <option value="all_disabled" @selected(request('status', $filters['status'] ?? '') === 'all_disabled')>All Modules Disabled</option>
                    </select>
                </div>

                <div class="field">
                    <label for="categoryFilter">Checklist Module</label>
                    <select id="categoryFilter" name="category">
                        <option value="">All Modules</option>
                        @foreach ($categories as $catKey => $def)
                            <option value="{{ $catKey }}" @selected(request('category', $filters['category'] ?? '') === $catKey)>{{ $def['label'] }} (Active)</option>
                        @endforeach
                    </select>
                </div>

                <div class="field">
                    <label for="restroomFilter">Restrooms</label>
                    <select id="restroomFilter" name="restroom">
                        <option value="">All Facilities</option>
                        <option value="has_restrooms" @selected(request('restroom', $filters['restroom'] ?? '') === 'has_restrooms')>Has Branch Restrooms</option>
                        <option value="no_restrooms" @selected(request('restroom', $filters['restroom'] ?? '') === 'no_restrooms')>No Restrooms Configured</option>
                        <option value="has_customer" @selected(request('restroom', $filters['restroom'] ?? '') === 'has_customer')>Customer Area Restrooms</option>
                        <option value="has_office" @selected(request('restroom', $filters['restroom'] ?? '') === 'has_office')>Office Restrooms</option>
                        <option value="has_pwd" @selected(request('restroom', $filters['restroom'] ?? '') === 'has_pwd')>PWD Restroom Enabled</option>
                    </select>
                </div>

                <div class="field">
                    <label for="sortFilter">Sort By</label>
                    <select id="sortFilter" name="sort">
                        <option value="name_asc" @selected(request('sort', $filters['sort'] ?? '') === 'name_asc')>Branch Name (A → Z)</option>
                        <option value="name_desc" @selected(request('sort', $filters['sort'] ?? '') === 'name_desc')>Branch Name (Z → A)</option>
                        <option value="restrooms_desc" @selected(request('sort', $filters['sort'] ?? '') === 'restrooms_desc')>Most Restrooms</option>
                        <option value="restrooms_asc" @selected(request('sort', $filters['sort'] ?? '') === 'restrooms_asc')>Least Restrooms</option>
                        <option value="active_desc" @selected(request('sort', $filters['sort'] ?? '') === 'active_desc')>Most Active Modules</option>
                    </select>
                </div>

                <div class="filter-actions">
                    <button class="button primary" type="submit"><i class="fas fa-filter"></i>Apply</button>
                    <a class="button" href="{{ route('admin.checklist-access.index') }}"><i class="fas fa-rotate-left"></i>Reset</a>
                </div>
            </form>

            {{-- Filter Results Status Bar --}}
            <div class="filter-meta-bar" id="filterMetaBar">
                <div>
                    Showing <strong id="visibleCount">{{ count($dealers) }}</strong> of <strong>{{ $allDealersCount ?? count($dealers) }}</strong> dealer branches
                </div>
                <div class="filter-meta-chips">
                    @if (request('search'))
                        <span class="active-filter-chip"><i class="fas fa-magnifying-glass"></i> "{{ request('search') }}"</span>
                    @endif
                    @if (request('region'))
                        <span class="active-filter-chip"><i class="fas fa-location-dot"></i> {{ request('region') }}</span>
                    @endif
                    @if (request('brand'))
                        <span class="active-filter-chip"><i class="fas fa-tag"></i> {{ request('brand') }}</span>
                    @endif
                    @if (request('status'))
                        <span class="active-filter-chip"><i class="fas fa-sliders"></i> {{ ucfirst(str_replace('_', ' ', request('status'))) }}</span>
                    @endif
                    @if (request('category'))
                        <span class="active-filter-chip"><i class="fas fa-list-check"></i> {{ $categories[request('category')]['label'] ?? request('category') }}</span>
                    @endif
                    @if (request('restroom'))
                        <span class="active-filter-chip"><i class="fas fa-restroom"></i> {{ ucfirst(str_replace('_', ' ', request('restroom'))) }}</span>
                    @endif
                    @if (request()->hasAny(['search', 'region', 'brand', 'status', 'category', 'restroom']))
                        <a href="{{ route('admin.checklist-access.index') }}" style="font-size:11px; color:var(--gateway-red-500, #e31c3d); text-decoration:none; font-weight:700;">Clear All</a>
                    @endif
                </div>
            </div>

            {{-- Branch list and selected branch checklist --}}
            <section class="availability-grid" id="availabilityGrid" aria-label="Checklist availability by dealer">
                <aside class="branch-panel" aria-label="Branches">
                    <div class="workspace-heading">
                        <h3>Branches</h3>
                        <p>Select a branch to manage its checklist access.</p>
                    </div>
                    <div class="branch-list" id="branchList">
                        @foreach ($dealers as $dealer)
                            @php
                                $branchKey = mb_strtolower(trim($dealer));
                                $branchSlug = Str::slug($dealer);
                                $branchStats = $dealerStats[$branchKey] ?? ['enabled_count' => 0, 'restroom_count' => 0];
                            @endphp
                            <button class="branch-choice {{ $loop->first ? 'is-selected' : '' }}" type="button"
                                    data-card="card-{{ $branchSlug }}" data-dealer="{{ $branchKey }}"
                                    aria-controls="card-{{ $branchSlug }}" aria-pressed="{{ $loop->first ? 'true' : 'false' }}">
                                <span class="branch-choice-name">{{ $dealer }}</span>
                                <span class="branch-choice-meta">
                                    <span>{{ $dealerBrands[$branchKey] ?? 'Unspecified Brand' }}</span>
                                    <span>·</span>
                                    <span class="branch-modules-count">{{ $branchStats['enabled_count'] }}/{{ count($categories) }} modules</span>
                                </span>
                            </button>
                        @endforeach
                        <p class="branch-empty" id="branchEmpty" @if ($dealers->isNotEmpty()) hidden @endif>No matching branches found.</p>
                    </div>
                </aside>
                <div class="modules-panel">
                    <div class="workspace-heading">
                        <h3>Audit Checklist Modules</h3>
                        <p>Manage the selected branch’s modules and restroom checklists, then save your changes.</p>
                    </div>
                    <div class="modules-panel-body">
                @php
                    $categoryIcons = [
                        'dos_sales' => 'fa-car',
                        'dos_aftersales' => 'fa-wrench',
                        'five_s_sales' => 'fa-boxes-stacked',
                        'five_s_service' => 'fa-screwdriver-wrench',
                        'five_s_utility' => 'fa-broom',
                    ];
                @endphp

                @forelse ($dealers as $dealer)
                    @php
                        $dealerKey = mb_strtolower(trim($dealer));
                        $settingKeyPrefix = $dealerKey.'|';
                        $dealersRestrooms = $branchRestrooms->get($dealerKey, collect());
                        $dealerSlug = Str::slug($dealer);
                        $region = $dealerRegions[$dealerKey] ?? 'Other';
                        $regionClass = strtolower(trim($region));

                        // Count active categories for badge
                        $enabledCount = 0;
                        foreach ($categories as $catKey => $def) {
                            $rec = $settings->get($settingKeyPrefix.$catKey);
                            if ($rec?->is_enabled ?? true) {
                                $enabledCount++;
                            }
                        }
                        $utilityRecord = $settings->get($settingKeyPrefix.'five_s_utility');
                        $utilityEnabled = $utilityRecord?->is_enabled ?? true;
                    @endphp
                    <div class="availability-card" id="card-{{ $dealerSlug }}" @if (! $loop->first) hidden @endif
                         data-dealer="{{ $dealerKey }}"
                         data-region="{{ strtolower($region) }}"
                         data-active-count="{{ $enabledCount }}"
                         data-restroom-count="{{ $dealersRestrooms->count() }}">
                        <form id="form-dealer-{{ $dealerSlug }}" method="POST" action="{{ route('admin.checklist-access.update', ['dealer' => $dealer]) }}">
                            @csrf
                            @method('PATCH')

                            {{-- Card Header --}}
                            <div class="card-header-bar">
                                <div class="card-title-row">
                                    <h3 class="card-dealer-name">
                                        <i class="fas fa-building"></i>
                                        <span>{{ $dealer }}</span>
                                    </h3>
                                    <div class="card-tags">
                                        <span class="region-badge {{ in_array($regionClass, ['ncr', 'visayas', 'mindanao']) ? $regionClass : 'other' }}" title="Region: {{ $region }}">
                                            <i class="fas fa-location-dot"></i> {{ $region }}
                                        </span>
                                        <span class="badge-pill {{ $enabledCount === 5 ? 'pill-success' : ($enabledCount > 0 ? 'pill-warning' : 'pill-danger') }}" id="badge-count-{{ $dealerSlug }}" title="{{ $enabledCount }} of 5 checklist modules active">
                                            <i class="fas fa-layer-group"></i> {{ $enabledCount }}/5 Active
                                        </span>
                                        <span class="badge-pill pill-neutral" title="{{ $dealersRestrooms->count() }} restrooms configured">
                                            <i class="fas fa-restroom"></i> {{ $dealersRestrooms->count() }}
                                        </span>
                                    </div>
                                </div>
                                <div class="card-desc-row">
                                    <p>Checklist categories and branch restroom availability.</p>
                                    <div class="card-bulk-actions">
                                        <button type="button" class="btn-micro" onclick="toggleAllCategories('{{ $dealerSlug }}', true)" title="Enable all 5 modules for this branch">Enable All</button>
                                        <button type="button" class="btn-micro" onclick="toggleAllCategories('{{ $dealerSlug }}', false)" title="Disable all 5 modules for this branch">Disable All</button>
                                    </div>
                                </div>
                            </div>

                            {{-- Checklist Modules Section --}}
                            <div class="card-section-label">
                                <span><i class="fas fa-list-check"></i> Audit Checklist Modules</span>
                                <small style="font-weight:600; text-transform:none;">Web & Mobile</small>
                            </div>

                            <div class="categories-list" id="cat-list-{{ $dealerSlug }}">
                                @foreach ($categories as $category => $definition)
                                    @php
                                        $record = $settings->get($settingKeyPrefix.$category);
                                        $enabled = $record?->is_enabled ?? true;
                                        $icon = $categoryIcons[$category] ?? 'fa-clipboard-check';
                                    @endphp
                                    <div class="availability-option {{ $enabled ? 'is-enabled' : '' }}" id="opt-{{ $dealerSlug }}-{{ $category }}">
                                        <div class="option-main">
                                            <div class="option-icon-box" aria-hidden="true">
                                                <i class="fas {{ $icon }}"></i>
                                            </div>
                                            <div class="option-info">
                                                <strong>{{ $definition['label'] }}</strong>
                                                <small class="option-state-text">{{ $enabled ? 'Available to assigned users' : 'Hidden and blocked' }}</small>
                                            </div>
                                        </div>
                                        <label class="availability-switch" title="Toggle {{ $definition['label'] }} for {{ $dealer }}">
                                            <input type="hidden" name="availability[{{ $category }}]" value="0">
                                            <input type="checkbox" name="availability[{{ $category }}]" value="1"
                                                   class="category-toggle-{{ $dealerSlug }}"
                                                   data-category="{{ $category }}"
                                                   @checked($enabled)
                                                   onchange="handleCategoryToggle(this, '{{ $dealerSlug }}', '{{ $category }}')"
                                                   aria-label="{{ $definition['label'] }} for {{ $dealer }}">
                                            <span aria-hidden="true"></span>
                                        </label>
                                    </div>
                                @endforeach
                            </div>

                            {{-- Branch Restrooms Section --}}
                            <div class="restrooms-section {{ $utilityEnabled ? '' : 'is-disabled' }}"
                                 id="restrooms-{{ $dealerSlug }}"
                                 data-utility-enabled="{{ $utilityEnabled ? '1' : '0' }}">
                                <div class="restrooms-header">
                                    <h4><i class="fas fa-restroom"></i> Branch Restrooms</h4>
                                    <button type="button"
                                            class="btn-add-restroom restroom-config-control-{{ $dealerSlug }}"
                                            onclick="openAddRestroomModal('{{ addslashes($dealer) }}')"
                                            @disabled(! $utilityEnabled)>
                                        <i class="fas fa-plus"></i> Add Restroom
                                    </button>
                                </div>
                                <p class="restrooms-disabled-note">
                                    <i class="fas fa-lock" aria-hidden="true"></i>
                                    Turn on 5S - Utility and save before configuring Male, Female, PWD, or adding a restroom.
                                </p>

                                <div class="restroom-list">
                                    @forelse ($dealersRestrooms as $restroom)
                                        <div class="restroom-card">
                                            <div class="restroom-card-head">
                                                <div class="restroom-card-title">
                                                    <i class="fas fa-door-closed" style="color:#64748b; font-size:12px;"></i>
                                                    <span>{{ $restroom->name }}</span>
                                                    <span class="area-badge {{ $restroom->area_type }}">
                                                        {{ $restroom->isCustomerArea() ? 'Customer Area' : 'Office' }}
                                                    </span>
                                                </div>
                                                <div class="restroom-controls">
                                                    <button type="button" class="btn-action-icon restroom-config-control-{{ $dealerSlug }}" title="Edit Restroom"
                                                            @disabled(! $utilityEnabled)
                                                            onclick="openEditRestroomModal('{{ addslashes($dealer) }}', {{ $restroom->id }}, '{{ addslashes($restroom->name) }}', '{{ $restroom->area_type }}', {{ $restroom->has_male ? 'true' : 'false' }}, {{ $restroom->has_female ? 'true' : 'false' }}, {{ $restroom->has_pwd ? 'true' : 'false' }})">
                                                        <i class="fas fa-pen-to-square"></i>
                                                    </button>
                                                    <button type="button" class="btn-action-icon delete" title="Delete Restroom"
                                                            onclick="confirmDeleteRestroom('{{ addslashes($dealer) }}', {{ $restroom->id }}, '{{ addslashes($restroom->name) }}')">
                                                        <i class="fas fa-trash-can"></i>
                                                    </button>
                                                </div>
                                            </div>

                                            <div class="restroom-switches">
                                                <span style="font-size:11px; font-weight:700; color:#64748b; margin-right:4px;">Genders:</span>
                                                <label class="switch-label" title="Enable Male restroom checklist">
                                                    <input type="hidden" name="restrooms[{{ $restroom->id }}][has_male]" value="0">
                                                    <input type="checkbox" class="restroom-gender-control-{{ $dealerSlug }}" name="restrooms[{{ $restroom->id }}][has_male]" value="1" @checked($restroom->has_male) @disabled(! $utilityEnabled)>
                                                    <span>Male</span>
                                                </label>

                                                <label class="switch-label" title="Enable Female restroom checklist">
                                                    <input type="hidden" name="restrooms[{{ $restroom->id }}][has_female]" value="0">
                                                    <input type="checkbox" class="restroom-gender-control-{{ $dealerSlug }}" name="restrooms[{{ $restroom->id }}][has_female]" value="1" @checked($restroom->has_female) @disabled(! $utilityEnabled)>
                                                    <span>Female</span>
                                                </label>

                                                @if ($restroom->isCustomerArea())
                                                    <label class="switch-label" title="Enable PWD restroom checklist">
                                                        <input type="hidden" name="restrooms[{{ $restroom->id }}][has_pwd]" value="0">
                                                        <input type="checkbox" class="restroom-gender-control-{{ $dealerSlug }}" name="restrooms[{{ $restroom->id }}][has_pwd]" value="1" @checked($restroom->has_pwd) @disabled(! $utilityEnabled)>
                                                        <span>PWD</span>
                                                    </label>
                                                @else
                                                    <span class="badge-no-pwd" title="Office restrooms do not contain PWD checklists">(No PWD)</span>
                                                @endif
                                            </div>
                                        </div>
                                    @empty
                                        <div class="empty-restrooms-box">
                                            <p><i class="fas fa-restroom" style="color:#94a3b8; margin-right:4px;"></i> No restrooms configured for this branch.</p>
                                            <button type="button"
                                                    class="btn-add-restroom restroom-config-control-{{ $dealerSlug }}"
                                                    onclick="openAddRestroomModal('{{ addslashes($dealer) }}')"
                                                    @disabled(! $utilityEnabled)>
                                                <i class="fas fa-plus"></i> Configure First Restroom
                                            </button>
                                        </div>
                                    @endforelse
                                </div>
                            </div>

                            {{-- Card Footer --}}
                            <div class="availability-actions">
                                <button class="button primary" type="submit">
                                    <i class="fas fa-floppy-disk"></i> Save All Changes
                                </button>
                            </div>
                        </form>
                    </div>
                @empty
                    <article class="availability-card" style="text-align: center; padding: 48px 24px;">
                        <div style="font-size: 36px; color: #94a3b8; margin-bottom: 12px;"><i class="fas fa-building-circle-xmark"></i></div>
                        <h3 style="font-size: 18px; margin: 0 0 6px; color: #1e293b;">No matching dealers found</h3>
                        <p style="color: #64748b; font-size: 13px; margin: 0 0 16px;">Try adjusting your search criteria, region filter, or module status.</p>
                        <div>
                            <a class="button primary" href="{{ route('admin.checklist-access.index') }}">
                                <i class="fas fa-rotate-left"></i> Reset All Filters
                            </a>
                        </div>
                    </article>
                @endforelse
                    <p class="branch-empty" id="detailEmpty" hidden>No matching branches found. Adjust the search or filters above.</p>
                    </div>
                </div>
            </section>
        </main>
    </div>

    {{-- Add Restroom Modal --}}
    <div class="modal-backdrop" id="addRestroomModal">
        <div class="modal-box">
            <h3>Add Branch Restroom</h3>
            <p id="addModalSubtitle">Configure a new restroom checklist for this branch.</p>
            <form id="addRestroomForm" method="POST" action="">
                @csrf
                <div class="modal-form-group">
                    <label for="addRestroomArea">Area Category</label>
                    <select id="addRestroomArea" name="area_type" onchange="toggleAddPwdSwitch(this.value)">
                        <option value="customer">Customer Area Restroom (Male, Female, PWD)</option>
                        <option value="office">Office Restroom (Male, Female - No PWD)</option>
                    </select>
                </div>
                <div class="modal-form-group">
                    <label for="addRestroomName">Restroom Name / Label</label>
                    <input type="text" id="addRestroomName" name="name" required placeholder="e.g., 2nd Floor Office Restroom">
                </div>
                <div class="modal-form-group">
                    <label>Active Checklist Options</label>
                    <div class="modal-switches-box">
                        <label class="switch-label">
                            <input type="checkbox" name="has_male" value="1" checked>
                            <span>Male</span>
                        </label>
                        <label class="switch-label">
                            <input type="checkbox" name="has_female" value="1" checked>
                            <span>Female</span>
                        </label>
                        <label class="switch-label" id="addPwdLabel">
                            <input type="checkbox" id="addPwdInput" name="has_pwd" value="1" checked>
                            <span>PWD</span>
                        </label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-modal-cancel" onclick="closeModal('addRestroomModal')">Cancel</button>
                    <button type="submit" class="btn-modal-submit"><i class="fas fa-plus"></i> Add Restroom</button>
                </div>
            </form>
        </div>
    </div>

    {{-- Edit Restroom Modal --}}
    <div class="modal-backdrop" id="editRestroomModal">
        <div class="modal-box">
            <h3>Edit Restroom</h3>
            <p>Update restroom title and available gender checklists.</p>
            <form id="editRestroomForm" method="POST" action="">
                @csrf
                @method('PATCH')
                <div class="modal-form-group">
                    <label for="editRestroomName">Restroom Name / Label</label>
                    <input type="text" id="editRestroomName" name="name" required>
                </div>
                <div class="modal-form-group">
                    <label>Active Checklist Options</label>
                    <div class="modal-switches-box">
                        <label class="switch-label">
                            <input type="hidden" name="has_male" value="0">
                            <input type="checkbox" id="editHasMale" name="has_male" value="1">
                            <span>Male</span>
                        </label>
                        <label class="switch-label">
                            <input type="hidden" name="has_female" value="0">
                            <input type="checkbox" id="editHasFemale" name="has_female" value="1">
                            <span>Female</span>
                        </label>
                        <label class="switch-label" id="editPwdLabel">
                            <input type="hidden" name="has_pwd" value="0">
                            <input type="checkbox" id="editHasPwd" name="has_pwd" value="1">
                            <span>PWD</span>
                        </label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-modal-cancel" onclick="closeModal('editRestroomModal')">Cancel</button>
                    <button type="submit" class="btn-modal-submit"><i class="fas fa-floppy-disk"></i> Save Restroom</button>
                </div>
            </form>
        </div>
    </div>

    {{-- Delete Restroom Form (Hidden) --}}
    <form id="deleteRestroomForm" method="POST" action="" style="display:none;">
        @csrf
        @method('DELETE')
    </form>

    <script>
        function openAddRestroomModal(dealer) {
            const form = document.getElementById('addRestroomForm');
            form.action = '{{ url("/admin/checklist-access") }}/' + encodeURIComponent(dealer) + '/restrooms';
            document.getElementById('addModalSubtitle').innerText = 'Add a new restroom checklist for ' + dealer;
            document.getElementById('addRestroomName').value = '';
            document.getElementById('addRestroomArea').value = 'customer';
            toggleAddPwdSwitch('customer');
            document.getElementById('addRestroomModal').classList.add('open');
        }

        function toggleAddPwdSwitch(areaType) {
            const pwdLabel = document.getElementById('addPwdLabel');
            const pwdInput = document.getElementById('addPwdInput');
            if (areaType === 'office') {
                pwdLabel.style.display = 'none';
                pwdInput.checked = false;
            } else {
                pwdLabel.style.display = 'inline-flex';
                pwdInput.checked = true;
            }
        }

        function openEditRestroomModal(dealer, restroomId, name, areaType, hasMale, hasFemale, hasPwd) {
            const form = document.getElementById('editRestroomForm');
            form.action = '{{ url("/admin/checklist-access") }}/' + encodeURIComponent(dealer) + '/restrooms/' + restroomId;
            document.getElementById('editRestroomName').value = name;
            document.getElementById('editHasMale').checked = hasMale;
            document.getElementById('editHasFemale').checked = hasFemale;

            const pwdLabel = document.getElementById('editPwdLabel');
            const pwdInput = document.getElementById('editHasPwd');
            if (areaType === 'office') {
                pwdLabel.style.display = 'none';
                pwdInput.checked = false;
            } else {
                pwdLabel.style.display = 'inline-flex';
                pwdInput.checked = hasPwd;
            }

            document.getElementById('editRestroomModal').classList.add('open');
        }

        function confirmDeleteRestroom(dealer, restroomId, name) {
            if (confirm('Are you sure you want to delete the "' + name + '" restroom for ' + dealer + '?')) {
                const form = document.getElementById('deleteRestroomForm');
                form.action = '{{ url("/admin/checklist-access") }}/' + encodeURIComponent(dealer) + '/restrooms/' + restroomId;
                form.submit();
            }
        }

        function closeModal(id) {
            document.getElementById(id).classList.remove('open');
        }

        // Close on backdrop click
        document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
            backdrop.addEventListener('click', function(e) {
                if (e.target === this) {
                    this.classList.remove('open');
                }
            });
        });

        // Close on Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                document.querySelectorAll('.modal-backdrop.open').forEach(m => m.classList.remove('open'));
            }
        });

        // Interactive toggle updates
        function handleCategoryToggle(checkbox, dealerSlug, category) {
            const row = document.getElementById('opt-' + dealerSlug + '-' + category);
            if (row) {
                const stateText = row.querySelector('.option-state-text');
                if (checkbox.checked) {
                    row.classList.add('is-enabled');
                    if (stateText) stateText.textContent = 'Available to assigned users';
                } else {
                    row.classList.remove('is-enabled');
                    if (stateText) stateText.textContent = 'Hidden and blocked';
                }
            }
            if (category === 'five_s_utility') {
                setRestroomControlsAvailability(dealerSlug, checkbox.checked);
            }
            updateActiveBadgeCount(dealerSlug);
        }

        function setRestroomControlsAvailability(dealerSlug, enabled) {
            const section = document.getElementById('restrooms-' + dealerSlug);
            if (section) {
                section.classList.toggle('is-disabled', !enabled);
                section.dataset.utilityEnabled = enabled ? '1' : '0';
            }

            document.querySelectorAll('.restroom-gender-control-' + dealerSlug).forEach(input => {
                if (!enabled) input.checked = false;
                input.disabled = !enabled;
            });

            document.querySelectorAll('.restroom-config-control-' + dealerSlug).forEach(control => {
                control.disabled = !enabled;
            });
        }

        // Enable All or Disable All for a branch
        function toggleAllCategories(dealerSlug, enable) {
            const checkboxes = document.querySelectorAll('.category-toggle-' + dealerSlug);
            checkboxes.forEach(cb => {
                cb.checked = enable;
                const cat = cb.getAttribute('data-category');
                handleCategoryToggle(cb, dealerSlug, cat);
            });
        }

        // Update the badge count pill on a card
        function updateActiveBadgeCount(dealerSlug) {
            const checkboxes = document.querySelectorAll('.category-toggle-' + dealerSlug);
            let count = 0;
            checkboxes.forEach(cb => { if (cb.checked) count++; });
            const badge = document.getElementById('badge-count-' + dealerSlug);
            if (badge) {
                badge.innerHTML = '<i class="fas fa-layer-group"></i> ' + count + '/5 Active';
                badge.className = 'badge-pill ' + (count === 5 ? 'pill-success' : (count > 0 ? 'pill-warning' : 'pill-danger'));
            }
            const card = document.getElementById('card-' + dealerSlug);
            if (card) {
                card.setAttribute('data-active-count', count);
            }
            const branchChoice = branchChoices.find(choice => choice.dataset.card === 'card-' + dealerSlug);
            const branchCount = branchChoice?.querySelector('.branch-modules-count');
            if (branchCount) branchCount.textContent = count + '/5 modules';
        }

        // Keep the branch navigator and detail panel in sync.
        const branchChoices = Array.from(document.querySelectorAll('.branch-choice'));
        const detailEmpty = document.getElementById('detailEmpty');
        const branchEmpty = document.getElementById('branchEmpty');
        const selectionKey = 'checklist-access-selected-branch';

        function selectBranch(choice) {
            branchChoices.forEach(button => {
                const selected = button === choice;
                button.classList.toggle('is-selected', selected);
                button.setAttribute('aria-pressed', selected ? 'true' : 'false');
                const card = document.getElementById(button.dataset.card);
                if (card) card.hidden = !selected;
            });
            if (detailEmpty) detailEmpty.hidden = Boolean(choice);
            if (choice) sessionStorage.setItem(selectionKey, choice.dataset.card);
        }

        branchChoices.forEach(choice => choice.addEventListener('click', () => selectBranch(choice)));
        const previousChoice = branchChoices.find(choice => choice.dataset.card === sessionStorage.getItem(selectionKey));
        if (previousChoice) selectBranch(previousChoice);

        const searchInput = document.getElementById('dealerSearch');
        if (searchInput) {
            searchInput.addEventListener('input', function() {
                const query = this.value.toLowerCase().trim();
                let visible = 0;

                branchChoices.forEach(choice => {
                    const matches = (choice.dataset.dealer || '').includes(query);
                    choice.hidden = !matches;
                    if (matches) visible++;
                });

                const countEl = document.getElementById('visibleCount');
                if (countEl) countEl.textContent = visible;
                if (branchEmpty) branchEmpty.hidden = visible > 0;
                if (!branchChoices.some(choice => choice.classList.contains('is-selected') && !choice.hidden)) {
                    selectBranch(branchChoices.find(choice => !choice.hidden) || null);
                }
            });
        }
    </script>

    @include('partials.browser-push')
</body>
</html>
