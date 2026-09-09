@php
    $roleOptions = \App\Models\User::roleOptions();
    $picAssignmentOptions = \App\Models\User::picAssignmentOptions();
    $successDialog = match (session('status')) {
        'User account updated.' => [
            'title' => 'User updated successfully',
            'message' => 'The account details have been saved.',
        ],
        'User password updated.' => [
            'title' => 'Password changed successfully',
            'message' => 'The new password is active and existing mobile access tokens were signed out.',
        ],
        default => null,
    };
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#F5F6F8">
    <title>Gateway Audit Compliance | User Management</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset('css/users-des.css') }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
</head>
<body class="gateway-dashboard gateway-page-users">
    @include('layouts.navigation')

    <div class="main-shell" id="mainShell">
        @include('partials.app-topbar', [
            'topbarTitle' => 'User Management',
            'topbarSubtitle' => 'GM-managed Gateway accounts and access',
            'notificationId' => 'notificationsBtn',
        ])

        <main class="content">
            <section class="page-heading">
                <div>
                    <span class="eyebrow"><span class="eyebrow-dot"></span> Account administration</span>
                    <h2>User Management</h2>
                    <p>Create, review, and maintain the accounts that can access the GAC system.</p>
                </div>
                <div class="header-actions">
                    <a class="button" href="{{ route('reports.index') }}"><i class="fas fa-chart-column"></i>View Reports</a>
                    @if ($canManageUsers)
                        <button class="button primary" id="openAddUserButton" type="button"><i class="fas fa-user-plus"></i>Add User</button>
                    @endif
                </div>
            </section>

            @if (session('status'))
                <section class="notice" role="status">
                    <span class="notice-icon"><i class="fas fa-circle-check"></i></span>
                    <div><strong>{{ session('status') }}</strong><p>The change has been saved to MariaDB.</p></div>
                </section>
            @endif

            @if ($errors->any())
                <section class="notice" role="alert">
                    <span class="notice-icon"><i class="fas fa-triangle-exclamation"></i></span>
                    <div><strong>Please correct the account form.</strong>@foreach ($errors->all() as $error)<p>{{ $error }}</p>@endforeach</div>
                </section>
            @endif

            <section class="stats-grid" aria-label="User management summary">
                <article class="stat-card"><div class="stat-top"><span class="stat-label">Total Accounts</span><span class="stat-icon"><i class="fas fa-users"></i></span></div><div class="stat-value">{{ $stats['total'] }}</div><div class="stat-meta">Stored user records</div></article>
                <article class="stat-card"><div class="stat-top"><span class="stat-label">Active</span><span class="stat-icon"><i class="fas fa-user-check"></i></span></div><div class="stat-value">{{ $stats['active'] }}</div><div class="stat-meta">Accounts allowed to sign in</div></article>
                <article class="stat-card"><div class="stat-top"><span class="stat-label">Inactive</span><span class="stat-icon"><i class="fas fa-user-slash"></i></span></div><div class="stat-value">{{ $stats['inactive'] }}</div><div class="stat-meta">Accounts blocked from signing in</div></article>
                <article class="stat-card"><div class="stat-top"><span class="stat-label">PIC</span><span class="stat-icon"><i class="fas fa-clipboard-check"></i></span></div><div class="stat-value">{{ $stats['pic'] }}</div><div class="stat-meta">Person In Charge accounts</div></article>
                <article class="stat-card"><div class="stat-top"><span class="stat-label">BOM</span><span class="stat-icon"><i class="fas fa-user-tie"></i></span></div><div class="stat-value">{{ $stats['bom'] }}</div><div class="stat-meta">Branch Operations Managers</div></article>
                <article class="stat-card"><div class="stat-top"><span class="stat-label">Admin</span><span class="stat-icon"><i class="fas fa-shield-halved"></i></span></div><div class="stat-value">{{ $stats['admin'] }}</div><div class="stat-meta">Compliance Administrator accounts</div></article>
            </section>

            <form class="panel filter-panel" method="GET" action="{{ route('users.index') }}" aria-label="User filters">
                <div class="field"><label for="userSearch">Search Users</label><input id="userSearch" name="search" type="search" value="{{ request('search') }}" placeholder="Name, email, branch, or role..."></div>
                <div class="field"><label for="roleFilter">Role</label><select id="roleFilter" name="role"><option value="">All roles</option>@foreach ($roleOptions as $code => $label)<option value="{{ $code }}" @selected(request('role') === $code)>{{ $label }}</option>@endforeach</select></div>
                <div class="field"><label for="branchFilter">Branch</label><select id="branchFilter" name="branch"><option value="">All branches</option>@foreach ($branches as $branch)<option value="{{ $branch }}" @selected(request('branch') === $branch)>{{ $branch }}</option>@endforeach</select></div>
                <div class="field"><label for="statusFilter">Account Status</label><select id="statusFilter" name="status"><option value="">All statuses</option>@foreach (['active', 'inactive'] as $status)<option value="{{ $status }}" @selected(request('status') === $status)>{{ ucfirst($status) }}</option>@endforeach</select></div>
                <div class="filter-actions"><button class="button primary" type="submit"><i class="fas fa-filter"></i>Apply</button><a class="button" href="{{ route('users.index') }}">Reset</a></div>
            </form>

            <section class="dashboard-grid">
                <article class="card span-12">
                    <div class="card-heading">
                        <div><h3>User Directory</h3><p>Roles, branches, and account states come directly from MariaDB.</p></div>
                        <span class="card-badge">{{ $users->total() }} {{ \Illuminate\Support\Str::plural('user', $users->total()) }}</span>
                    </div>
                    <div class="table-wrap">
                        <table>
                            <thead><tr><th>User</th><th>Role</th><th>Branch</th><th>Verified</th><th>Status</th>@if ($canManageUsers)<th>Actions</th>@endif</tr></thead>
                            <tbody>
                            @forelse ($users as $user)
                                @php
                                    $roleCode = $user->roleCode();
                                    $roleLabel = $user->roleLabel();
                                    $editingFailed = $errors->any() && (string) old('_editing_user_id') === (string) $user->id;
                                    $editValue = fn (string $field, $value) => $editingFailed ? old($field, $value) : $value;
                                @endphp
                                <tr>
                                    <td><strong>{{ $user->name }}</strong><br><small>{{ $user->email }}</small></td>
                                    <td>
                                        <span class="role-pill {{ strtolower($roleCode) }}">{{ $roleLabel }}</span>
                                        @if ($user->picAssignmentLabel())<br><small>{{ $user->picAssignmentLabel() }}</small>@endif
                                    </td>
                                    <td>{{ $user->branch ?: 'Unassigned' }}</td>
                                    <td>{{ $user->email_verified_at ? $user->email_verified_at->format('M j, Y') : 'Not verified' }}</td>
                                    <td><span class="status-pill {{ strtolower($user->account_status) }}">{{ ucfirst($user->account_status) }}</span></td>
                                    @if ($canManageUsers)
                                        <td>
                                            <details id="edit-user-{{ $user->id }}" {{ $editingFailed ? 'open' : '' }}>
                                                <summary class="button soft">Edit</summary>
                                                <form class="form-grid" method="POST" action="{{ route('users.update', $user) }}" style="min-width:320px;margin-top:12px">
                                                    @csrf
                                                    @method('PATCH')
                                                    <input type="hidden" name="_editing_user_id" value="{{ $user->id }}">
                                                    <div class="field full"><label>Full Name</label><input name="name" value="{{ $editValue('name', $user->name) }}" required></div>
                                                    <div class="field full"><label>Email</label><input name="email" type="email" value="{{ $editValue('email', $user->email) }}" required></div>
                                                    <div class="field"><label>Role</label><select name="user_type">@foreach ($roleOptions as $code => $label)<option value="{{ $code }}" @selected($editValue('user_type', $roleCode) === $code)>{{ $label }}</option>@endforeach</select></div>
                                                    <div class="field"><label>PIC Assignment</label><select name="pic_assignment_type"><option value="">Not applicable</option>@foreach ($picAssignmentOptions as $value => $label)<option value="{{ $value }}" @selected($editValue('pic_assignment_type', $user->picAssignmentType()) === $value)>{{ $label }}</option>@endforeach</select></div>
                                                    <div class="field"><label>Branch</label><select name="branch" required>@foreach ($branches as $branch)<option value="{{ $branch }}" @selected($editValue('branch', $user->branch) === $branch)>{{ $branch }}</option>@endforeach</select></div>
                                                    <div class="field"><label>Status</label><select name="account_status">@foreach (['active', 'pending', 'inactive', 'rejected'] as $status)<option value="{{ $status }}" @selected($editValue('account_status', $user->account_status) === $status)>{{ ucfirst($status) }}</option>@endforeach</select></div>
                                                    <div class="field full"><button class="button primary" type="submit">Save Account</button></div>
                                                </form>
                                                <form class="form-grid password-change-form" method="POST" action="{{ route('users.password.update', $user) }}" data-password-form>
                                                    @csrf
                                                    @method('PATCH')
                                                    <input type="hidden" name="_editing_user_id" value="{{ $user->id }}">
                                                    <div class="password-change-heading field full">
                                                        <strong>Change Password</strong>
                                                        <small>This is saved separately so other account fields cannot prevent the password change.</small>
                                                    </div>
                                                    <div class="field full">
                                                        <label for="edit-password-{{ $user->id }}">New Password</label>
                                                        <div class="password-input">
                                                            <input id="edit-password-{{ $user->id }}" name="password" type="password" minlength="8" autocomplete="new-password" aria-describedby="edit-password-help-{{ $user->id }}{{ $editingFailed && $errors->has('password') ? ' edit-password-error-'.$user->id : '' }}" @if ($editingFailed && $errors->has('password')) aria-invalid="true" @endif required>
                                                            <button class="password-toggle" type="button" data-password-toggle aria-controls="edit-password-{{ $user->id }}" aria-label="Show new password" aria-pressed="false"><i class="fas fa-eye" aria-hidden="true"></i><span>Show</span></button>
                                                        </div>
                                                        <small id="edit-password-help-{{ $user->id }}">Use at least 8 characters and enter the same password below.</small>
                                                        @if ($editingFailed && $errors->has('password'))
                                                            <small id="edit-password-error-{{ $user->id }}" role="alert">{{ $errors->first('password') }} Re-enter both password fields to try again.</small>
                                                        @endif
                                                    </div>
                                                    <div class="field full">
                                                        <label for="edit-password-confirmation-{{ $user->id }}">Confirm New Password</label>
                                                        <div class="password-input">
                                                            <input id="edit-password-confirmation-{{ $user->id }}" name="password_confirmation" type="password" minlength="8" autocomplete="new-password" required>
                                                            <button class="password-toggle" type="button" data-password-toggle aria-controls="edit-password-confirmation-{{ $user->id }}" aria-label="Show password confirmation" aria-pressed="false"><i class="fas fa-eye" aria-hidden="true"></i><span>Show</span></button>
                                                        </div>
                                                    </div>
                                                    <div class="field full"><button class="button primary" type="submit"><i class="fas fa-key" aria-hidden="true"></i>Change Password</button></div>
                                                </form>
                                            </details>
                                            @if (auth()->id() !== $user->id)
                                                <form method="POST" action="{{ route('users.status', $user) }}" style="margin-top:8px">
                                                    @csrf
                                                    @method('PATCH')
                                                    <input type="hidden" name="account_status" value="{{ $user->account_status === 'active' ? 'inactive' : 'active' }}">
                                                    <button class="button" type="submit">{{ $user->account_status === 'active' ? 'Deactivate' : 'Activate' }}</button>
                                                </form>
                                            @endif
                                        </td>
                                    @endif
                                </tr>
                            @empty
                                <tr><td colspan="6"><div class="empty-state">No database users match these filters.</div></td></tr>
                            @endforelse
                            </tbody>
                        </table>
                    </div>
                    @if ($users->hasPages())
                        <div class="table-pagination">
                            {{ $users->links() }}
                        </div>
                    @endif
                </article>
            </section>
        </main>
    </div>

    @if ($successDialog)
        <dialog class="user-success-dialog" id="userSuccessDialog" aria-labelledby="userSuccessTitle" aria-describedby="userSuccessMessage">
            <span class="user-success-icon" aria-hidden="true"><i class="fas fa-circle-check"></i></span>
            <h3 id="userSuccessTitle">{{ $successDialog['title'] }}</h3>
            <p id="userSuccessMessage">{{ $successDialog['message'] }}</p>
            <form method="dialog"><button class="button primary" type="submit" autofocus>OK</button></form>
        </dialog>
    @endif

    @if ($canManageUsers)
        <div class="modal" id="userModal" aria-hidden="true" role="dialog" aria-modal="true" aria-labelledby="userModalTitle">
            <div class="modal-card small">
                <div class="modal-heading"><div><h3 id="userModalTitle">Add User</h3><p>Create an account in the GAC database.</p></div><button class="modal-close" data-close-modal="userModal" type="button" aria-label="Close"><i class="fas fa-xmark"></i></button></div>
                <form class="modal-body" method="POST" action="{{ route('users.store') }}" data-password-form>
                    @csrf
                    <div class="form-grid">
                        <div class="field full"><label for="userNameInput">Full Name</label><input id="userNameInput" name="name" value="{{ old('name') }}" required></div>
                        <div class="field full"><label for="userEmailInput">Email Address</label><input id="userEmailInput" name="email" type="email" value="{{ old('email') }}" required></div>
                        <div class="field"><label for="userRoleInput">System Role</label><select id="userRoleInput" name="user_type">@foreach ($roleOptions as $code => $label)<option value="{{ $code }}">{{ $label }}</option>@endforeach</select></div>
                        <div class="field"><label for="userPicAssignmentInput">PIC Assignment</label><select id="userPicAssignmentInput" name="pic_assignment_type"><option value="">Not applicable</option>@foreach ($picAssignmentOptions as $value => $label)<option value="{{ $value }}" @selected(old('pic_assignment_type') === $value)>{{ $label }}</option>@endforeach</select></div>
                        <div class="field"><label for="userBranchInput">Branch</label><select id="userBranchInput" name="branch" required>@foreach ($branches as $branch)<option value="{{ $branch }}" @selected(old('branch', auth()->user()->branch) === $branch)>{{ $branch }}</option>@endforeach</select></div>
                        <div class="field"><label for="userStatusInput">Account Status</label><select id="userStatusInput" name="account_status"><option value="active">Active</option><option value="pending">Pending</option><option value="inactive">Inactive</option></select></div>
                        <div class="field full">
                            <label for="userPasswordInput">Temporary Password</label>
                            <div class="password-input">
                                <input id="userPasswordInput" name="password" type="password" minlength="8" autocomplete="new-password" required>
                                <button class="password-toggle" type="button" data-password-toggle aria-controls="userPasswordInput" aria-label="Show temporary password" aria-pressed="false"><i class="fas fa-eye" aria-hidden="true"></i><span>Show</span></button>
                            </div>
                        </div>
                        <div class="field full">
                            <label for="userPasswordConfirmationInput">Confirm Password</label>
                            <div class="password-input">
                                <input id="userPasswordConfirmationInput" name="password_confirmation" type="password" minlength="8" autocomplete="new-password" required>
                                <button class="password-toggle" type="button" data-password-toggle aria-controls="userPasswordConfirmationInput" aria-label="Show password confirmation" aria-pressed="false"><i class="fas fa-eye" aria-hidden="true"></i><span>Show</span></button>
                            </div>
                        </div>
                    </div>
                    <div class="modal-actions"><button class="button" data-close-modal="userModal" type="button">Cancel</button><button class="button primary" type="submit">Create User</button></div>
                </form>
            </div>
        </div>
    @endif

    <script>
        const successDialog = document.getElementById('userSuccessDialog');
        if (successDialog && typeof successDialog.showModal === 'function') {
            successDialog.showModal();
        } else {
            successDialog?.setAttribute('open', '');
        }
        document.querySelectorAll('[data-password-toggle]').forEach((button) => {
            const input = document.getElementById(button.getAttribute('aria-controls'));
            button.addEventListener('click', () => {
                const showPassword = input.type === 'password';
                input.type = showPassword ? 'text' : 'password';
                button.setAttribute('aria-pressed', String(showPassword));
                button.setAttribute('aria-label', button.getAttribute('aria-label').replace(/^(Show|Hide)/, showPassword ? 'Hide' : 'Show'));
                button.querySelector('span').textContent = showPassword ? 'Hide' : 'Show';
                button.querySelector('i').classList.toggle('fa-eye', !showPassword);
                button.querySelector('i').classList.toggle('fa-eye-slash', showPassword);
            });
        });
        document.querySelectorAll('[data-password-form]').forEach((form) => {
            const password = form.elements.namedItem('password');
            const confirmation = form.elements.namedItem('password_confirmation');
            const validatePasswords = () => {
                confirmation.required = password.required || password.value.length > 0;
                confirmation.setCustomValidity(confirmation.value && confirmation.value !== password.value
                    ? 'The password confirmation must match the new password.'
                    : '');
            };
            password.addEventListener('input', validatePasswords);
            confirmation.addEventListener('input', validatePasswords);
            form.addEventListener('submit', (event) => {
                validatePasswords();
                if (!form.reportValidity()) event.preventDefault();
            });
            validatePasswords();
        });
        const modal = document.getElementById('userModal');
        document.getElementById('openAddUserButton')?.addEventListener('click', () => {
            modal?.classList.add('is-open');
            modal?.setAttribute('aria-hidden', 'false');
        });
        document.querySelectorAll('[data-close-modal="userModal"]').forEach((button) => button.addEventListener('click', () => {
            modal?.classList.remove('is-open');
            modal?.setAttribute('aria-hidden', 'true');
        }));
        modal?.addEventListener('click', (event) => { if (event.target === modal) event.currentTarget.querySelector('[data-close-modal]')?.click(); });
        document.getElementById('mobileMenuButton')?.addEventListener('click', () => {
            document.getElementById('sidebar')?.classList.add('mobile-open', 'open');
            document.getElementById('sidebarBackdrop')?.classList.add('visible', 'open');
        });
        document.getElementById('sidebarBackdrop')?.addEventListener('click', () => {
            document.getElementById('sidebar')?.classList.remove('mobile-open', 'open');
            document.getElementById('sidebarBackdrop')?.classList.remove('visible', 'open');
        });
    </script>

    @include('partials.notifications-modal')
</body>
</html>
