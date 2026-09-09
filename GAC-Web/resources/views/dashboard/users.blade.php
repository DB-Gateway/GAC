<div class="panel-heading">
    <div>
        <span class="section-kicker">{{ $isAdministrator ? 'Administrator access' : $dashboardScope }}</span>
        <h2>User Usages</h2>
        <p>{{ $isAdministrator ? 'Account status, role coverage, and branch distribution across the GAC system.' : 'Account status and role coverage for your assigned branch.' }}</p>
    </div>
    @if ($isAdministrator)
        <div class="header-actions">
            <a class="button primary" href="{{ route('users.index') }}"><i class="fas fa-user-gear" aria-hidden="true"></i>Manage User Accounts</a>
        </div>
    @endif
</div>

<section class="workspace-stats user-workspace-stats" aria-label="User account summary">
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Total Accounts</span><i class="fas fa-users" aria-hidden="true"></i></div>
        <strong>{{ number_format($userStats['total']) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $userStats['total'] > 0 ? 100 : 0 }}%"></span></div>
        <p>{{ $isAdministrator ? 'All stored GAC user records' : 'GAC user records in your assigned branch' }}</p>
    </article>
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Active</span><i class="fas fa-user-check" aria-hidden="true"></i></div>
        <strong>{{ number_format($userStats['active']) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $barWidth($userStats['total'] > 0 ? ($userStats['active'] / $userStats['total']) * 100 : 0) }}%"></span></div>
        <p>Accounts currently allowed to sign in</p>
    </article>
    <article class="workspace-stat">
        <div class="workspace-stat-top"><span>Inactive</span><i class="fas fa-user-slash" aria-hidden="true"></i></div>
        <strong>{{ number_format($userStats['inactive']) }}</strong>
        <div class="workspace-meter"><span style="width:{{ $barWidth($userStats['total'] > 0 ? ($userStats['inactive'] / $userStats['total']) * 100 : 0) }}%"></span></div>
        <p>Accounts currently blocked from signing in</p>
    </article>
</section>

<section class="insight-grid" aria-label="User account breakdowns">
    <article class="insight-card span-6">
        <div class="insight-heading">
            <div><h3>Accounts by Role</h3><p>{{ $isAdministrator ? 'Access responsibility across the organization.' : 'Access responsibility within your assigned branch.' }}</p></div>
            <span>{{ $userRoleSummaries->count() }} roles</span>
        </div>
        <div class="insight-body">
            @foreach ($userRoleSummaries as $role)
                <div class="metric-row">
                    <div class="metric-label" title="{{ $role['label'] }}">{{ $role['label'] }}</div>
                    <div class="metric-track"><span style="width:{{ $barWidth($role['percentage']) }}%"></span></div>
                    <strong>{{ number_format($role['count']) }}</strong>
                </div>
                <p class="metric-meta">{{ $formatPercent($role['percentage']) }} of all user accounts</p>
            @endforeach
        </div>
    </article>

    <article class="insight-card span-6">
        <div class="insight-heading">
            <div><h3>Account Health</h3><p>Current access state for every account.</p></div>
            <span>{{ number_format($userStats['total']) }} accounts</span>
        </div>
        <div class="insight-body">
            @foreach ($userStatusSummaries as $status)
                <div class="metric-row compact">
                    <div class="metric-label"><span class="status-dot {{ $status['status'] }}"></span>{{ $status['label'] }}</div>
                    <div class="metric-track"><span style="width:{{ $barWidth($status['percentage']) }}%"></span></div>
                    <strong>{{ number_format($status['count']) }}</strong>
                </div>
            @endforeach
        </div>
    </article>

    <article class="insight-card span-5">
        <div class="insight-heading">
            <div><h3>Branch Coverage</h3><p>Users assigned to each Gateway branch.</p></div>
            <span>{{ $userBranchSummaries->count() }} branches</span>
        </div>
        <div class="table-wrap compact-table">
            <table>
                <thead><tr><th>Branch</th><th>Total</th><th>Active</th><th>Inactive</th></tr></thead>
                <tbody>
                    @forelse ($userBranchSummaries as $branch)
                        <tr>
                            <td><strong>{{ $branch['label'] }}</strong></td>
                            <td>{{ number_format($branch['count']) }}</td>
                            <td>{{ number_format($branch['active']) }}</td>
                            <td>{{ number_format($branch['inactive']) }}</td>
                        </tr>
                    @empty
                        <tr><td class="dashboard-empty" colspan="4">No branch assignments are available.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </article>

    <article class="insight-card span-7">
        <div class="insight-heading">
            <div><h3>Role Coverage Snapshot</h3><p>Operational account counts by responsibility.</p></div>
            <span>Live directory</span>
        </div>
        <div class="role-snapshot-grid">
            <div><i class="fas fa-clipboard-check" aria-hidden="true"></i><strong>{{ number_format($userStats['pic']) }}</strong><span>Person In Charge</span></div>
            <div><i class="fas fa-user-tie" aria-hidden="true"></i><strong>{{ number_format($userStats['bom']) }}</strong><span>Branch Operations Managers</span></div>
            <div><i class="fas fa-shield-halved" aria-hidden="true"></i><strong>{{ number_format($userStats['admin']) }}</strong><span>Compliance Administrators</span></div>
        </div>
    </article>
</section>

<section class="workspace-table-card" aria-label="Recently created user accounts">
    <div class="insight-heading">
        <div><h3>Recent Accounts</h3><p>{{ $isAdministrator ? 'The 10 most recently created GAC user records.' : 'The 10 most recently created user records in your assigned branch.' }}</p></div>
        @if ($isAdministrator)
            <a class="inline-link" href="{{ route('users.index') }}">Open directory <i class="fas fa-arrow-right" aria-hidden="true"></i></a>
        @endif
    </div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>User</th><th>Role</th><th>Branch</th><th>Status</th><th>Created</th></tr></thead>
            <tbody>
                @forelse ($recentUsers as $user)
                    <tr>
                        <td><strong>{{ $user['name'] }}</strong><small class="table-subtext">{{ $user['email'] }}</small></td>
                        <td>{{ $user['role'] }}</td>
                        <td>{{ $user['branch'] }}</td>
                        <td><span class="status-pill {{ $user['status'] }}">{{ ucfirst($user['status']) }}</span></td>
                        <td>{{ $user['created_at'] }}</td>
                    </tr>
                @empty
                    <tr><td class="dashboard-empty" colspan="5">No user accounts are available.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</section>
