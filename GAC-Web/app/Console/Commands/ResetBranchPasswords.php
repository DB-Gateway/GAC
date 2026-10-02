<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class ResetBranchPasswords extends Command
{
    protected $signature = 'gac:reset-branch-passwords
        {branches* : Exact branch names to update}
        {--apply : Apply the password reset after previewing the accounts}
        {--include-management : Also include the existing GM/administrator and BOM accounts}
        {--verify : Verify an entered password without changing any data}';

    protected $description = 'Reset passwords for every account in the specified exact branches';

    public function handle(): int
    {
        $branches = collect($this->argument('branches'))
            ->map(fn (string $branch): string => trim($branch))
            ->filter()
            ->unique()
            ->values();
        $users = User::query()
            ->orderBy('branch')
            ->orderBy('user_type')
            ->get()
            ->filter(function (User $user) use ($branches): bool {
                if ($branches->contains($user->branch)) {
                    return true;
                }

                return $this->option('include-management')
                    && in_array($user->roleCode(), [
                        User::ROLE_GENERAL_MANAGER,
                        User::ROLE_BRANCH_OPERATIONS_MANAGER,
                    ], true);
            })
            ->values();

        if ($users->isEmpty()) {
            $this->error('No accounts matched the exact branch names.');

            return self::FAILURE;
        }

        $this->table(
            ['ID', 'Username', 'Branch', 'Role'],
            $users->map(fn (User $user): array => [
                $user->id,
                $user->email,
                $user->branch,
                $user->user_type,
            ])->all()
        );

        if (! $this->option('apply') && ! $this->option('verify')) {
            $this->comment(sprintf(
                'Preview only: %d accounts matched. Run with --apply to enter and set the new password.',
                $users->count()
            ));

            return self::SUCCESS;
        }

        $password = (string) $this->secret('New password');

        if (strlen($password) < 8) {
            $this->error('The password must contain at least 8 characters.');

            return self::FAILURE;
        }

        if ($this->option('verify')) {
            $verified = $users->every(
                fn (User $user): bool => Hash::check($password, $user->fresh()->password)
            );

            if (! $verified) {
                $this->error('The entered password does not match every selected account.');

                return self::FAILURE;
            }

            $this->info(sprintf(
                'Password verified for all %d selected accounts.',
                $users->count()
            ));

            return self::SUCCESS;
        }

        DB::transaction(function () use ($users, $password): void {
            foreach ($users as $user) {
                $user->forceFill([
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();
                $user->tokens()->delete();
                DB::table('sessions')->where('user_id', $user->id)->delete();
            }
        });

        $this->info(sprintf(
            'Password reset completed for %d accounts. Existing sessions and access tokens were revoked.',
            $users->count()
        ));

        return self::SUCCESS;
    }
}
