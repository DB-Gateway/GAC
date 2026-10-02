<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ProvisionBranchAccounts extends Command
{
    protected $signature = 'gac:provision-branch-accounts
        {branch : Existing exact branch name to provision}
        {--move-from= : Existing exact branch whose GM, BOM, and DOS accounts should be moved}
        {--apply : Apply the displayed account plan}';

    protected $description = 'Ensure an existing branch has GM, BOM, 5S, and DOS accounts';

    /** @var array<string, string> */
    private const ROLE_NAMES = [
        User::ROLE_GENERAL_MANAGER => 'General Manager',
        User::ROLE_BRANCH_OPERATIONS_MANAGER => 'Branch Operations Manager',
        User::ROLE_5S_UTILITIES => '5S Utilities',
        User::ROLE_5S_SERVICE => '5S Service',
        User::ROLE_5S_SALES => '5S Sales',
        User::ROLE_SALES_MANAGER => 'Sales Manager',
        User::ROLE_AFTERSALES_MANAGER => 'Aftersales Manager',
        User::ROLE_CE_SERVICE => 'Customer Experience Service',
        User::ROLE_JOB_CONTROLLER => 'Job Controller',
        User::ROLE_PARTS_SUPERVISOR => 'Parts Supervisor',
        User::ROLE_WORKSHOP_SUPERVISOR => 'Workshop Supervisor',
    ];

    /** @var list<string> */
    private const MOVABLE_ROLES = [
        User::ROLE_GENERAL_MANAGER,
        User::ROLE_BRANCH_OPERATIONS_MANAGER,
        User::ROLE_SALES_MANAGER,
        User::ROLE_AFTERSALES_MANAGER,
        User::ROLE_CE_SERVICE,
        User::ROLE_JOB_CONTROLLER,
        User::ROLE_PARTS_SUPERVISOR,
        User::ROLE_WORKSHOP_SUPERVISOR,
    ];

    public function handle(): int
    {
        $branch = trim((string) $this->argument('branch'));
        $sourceBranch = trim((string) $this->option('move-from'));
        $allUsers = User::query()->orderBy('id')->get();

        if (! $allUsers->contains(fn (User $user): bool => $user->branch === $branch)) {
            $this->error("The target branch `{$branch}` does not already exist in the users database.");

            return self::FAILURE;
        }

        if ($sourceBranch !== '' && ! $allUsers->contains(fn (User $user): bool => $user->branch === $sourceBranch)) {
            $this->error("The source branch `{$sourceBranch}` does not exist in the users database.");

            return self::FAILURE;
        }

        $plan = collect(self::ROLE_NAMES)->map(function (string $defaultName, string $role) use (
            $allUsers,
            $branch,
            $sourceBranch
        ): array {
            $target = $this->accountForRole($allUsers, $branch, $role);
            $source = $sourceBranch !== '' && in_array($role, self::MOVABLE_ROLES, true)
                ? $this->accountForRole($allUsers, $sourceBranch, $role)
                : null;
            $account = $target ?? $source;
            $action = $target !== null ? 'retain/reset' : ($source !== null ? 'move/reset' : 'create');
            $name = $account?->name ?: "{$branch} {$defaultName}";

            return [
                'action' => $action,
                'id' => $account?->id,
                'role' => $role,
                'name' => $name,
                'from' => $account?->branch,
                'username' => User::usernameFor($role, $branch, name: $name),
            ];
        })->values();

        if (! $this->validatePlan($plan, $allUsers)) {
            return self::FAILURE;
        }

        $this->table(
            ['Action', 'ID', 'Role', 'Current branch', 'Resulting username'],
            $plan->map(fn (array $row): array => [
                $row['action'],
                $row['id'] ?? 'new',
                $row['role'],
                $row['from'] ?? '—',
                $row['username'],
            ])->all()
        );

        if (! $this->option('apply')) {
            $this->comment('Preview only. Run with --apply to enter the branch password and apply this plan.');

            return self::SUCCESS;
        }

        $password = (string) $this->secret('Password for all 11 branch accounts');

        if (strlen($password) < 8) {
            $this->error('The password must contain at least 8 characters.');

            return self::FAILURE;
        }

        DB::transaction(function () use ($plan, $branch, $password): void {
            foreach ($plan as $row) {
                $user = $row['id'] === null
                    ? new User
                    : User::query()->findOrFail($row['id']);

                $user->forceFill([
                    'name' => $row['name'],
                    'email' => $row['username'],
                    'branch' => $branch,
                    'user_type' => $row['role'],
                    'pic_assignment_type' => null,
                    'account_status' => $user->exists ? $user->account_status : 'active',
                    'must_change_password' => false,
                    'email_verified_at' => $user->email_verified_at ?? now(),
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();

                $user->tokens()->delete();
                DB::table('sessions')->where('user_id', $user->id)->delete();
            }
        });

        $this->info("Provisioned 11 accounts for {$branch}; all passwords were reset and sessions revoked.");

        return self::SUCCESS;
    }

    private function accountForRole(Collection $users, string $branch, string $role): ?User
    {
        return $users->first(
            fn (User $user): bool => $user->branch === $branch && $user->roleCode() === $role
        );
    }

    private function validatePlan(Collection $plan, Collection $allUsers): bool
    {
        foreach ($plan as $row) {
            $conflict = $allUsers->first(function (User $user) use ($row): bool {
                return strcasecmp($user->email, $row['username']) === 0
                    && (int) $user->id !== (int) ($row['id'] ?? 0);
            });

            if ($conflict !== null) {
                $this->error(sprintf(
                    'Username %s already belongs to user ID %d.',
                    $row['username'],
                    $conflict->id
                ));

                return false;
            }
        }

        return true;
    }
}
