<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use RuntimeException;

class BranchPicSeeder extends Seeder
{
    /**
     * New accounts use the canonical {role}.{branch} username format.
     * Their shared initial password comes from GAC_PIC_INITIAL_PASSWORD and must be
     * changed operationally after first login. Re-seeding never resets a password.
     */
    public function run(): void
    {
        $branches = collect(config('gac.branches', []))
            ->filter(fn ($branch): bool => is_string($branch) && trim($branch) !== '')
            ->unique(fn (string $branch): string => Str::lower(trim($branch)))
            ->values();
        $assignments = array_keys(User::picAssignmentOptions());
        $initialPassword = (string) config('gac.seeded_pic_accounts.initial_password');

        if ($branches->count() !== 49) {
            throw new RuntimeException('The GAC branch configuration must contain exactly 49 unique branches.');
        }

        if (strlen($initialPassword) < 12) {
            throw new RuntimeException('Set GAC_PIC_INITIAL_PASSWORD to at least 12 characters before seeding PIC accounts.');
        }

        $created = 0;
        $reused = 0;

        foreach ($branches as $branch) {
            foreach ($assignments as $assignment) {
                $user = $this->assignedPic($branch, $assignment);

                if ($user === null && $assignment === User::PIC_ASSIGNMENT_SALES_SERVICE) {
                    $user = $this->legacyPic($branch);
                }

                if ($user !== null) {
                    $user->forceFill([
                        'email' => User::usernameFor(User::ROLE_PERSON_IN_CHARGE, $branch, $assignment),
                        'branch' => $branch,
                        'user_type' => User::ROLE_PERSON_IN_CHARGE,
                        'pic_assignment_type' => $assignment,
                        'account_status' => 'active',
                    ])->save();
                    $reused++;

                    continue;
                }

                User::create([
                    'name' => sprintf('%s %s PIC', $branch, User::picAssignmentLabelFor($assignment)),
                    'email' => User::usernameFor(User::ROLE_PERSON_IN_CHARGE, $branch, $assignment),
                    'email_verified_at' => now(),
                    'branch' => $branch,
                    'user_type' => User::ROLE_PERSON_IN_CHARGE,
                    'pic_assignment_type' => $assignment,
                    'account_status' => 'active',
                    'password' => Hash::make($initialPassword),
                ]);
                $created++;
            }
        }

        $this->command?->info(sprintf(
            'Ensured 98 assigned PIC accounts across 49 branches (%d created, %d reused). Usernames use {role}.{branch}; the initial password came from GAC_PIC_INITIAL_PASSWORD.',
            $created,
            $reused
        ));
    }

    private function assignedPic(string $branch, string $assignment): ?User
    {
        return $this->branchPics($branch)
            ->first(fn (User $user): bool => $user->picAssignmentType() === $assignment);
    }

    private function legacyPic(string $branch): ?User
    {
        return $this->branchPics($branch)
            ->first(fn (User $user): bool => $user->account_status === 'active'
                && $user->picAssignmentType() === null);
    }

    private function branchPics(string $branch)
    {
        return User::query()
            ->whereRaw('LOWER(TRIM(branch)) = ?', [Str::lower(trim($branch))])
            ->orderBy('id')
            ->get()
            ->filter(fn (User $user): bool => $user->roleCode() === User::ROLE_PERSON_IN_CHARGE);
    }
}
