<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class NormalizeAccountUsernames extends Command
{
    protected $signature = 'gac:normalize-usernames
        {--apply : Back up the users table and apply the username changes}';

    protected $description = 'Preview or apply canonical Role.BrandBranch usernames to GAC accounts';

    private const BACKUP_TABLE = 'users_before_username_20260924';

    public function handle(): int
    {
        $users = User::query()->orderBy('id')->get();
        $plan = $users->map(fn (User $user): array => [
            'id' => (int) $user->id,
            'current' => (string) $user->email,
            'username' => $user->suggestedUsername(),
            'references' => $this->referenceCount((int) $user->id),
        ]);
        $collisions = $plan
            ->groupBy(fn (array $row): string => strtolower($row['username']))
            ->filter(fn (Collection $group): bool => $group->count() > 1);

        $duplicateIds = collect();
        $blocked = collect();

        foreach ($collisions as $group) {
            $keeper = $group
                ->sortBy([
                    ['references', 'desc'],
                    ['id', 'asc'],
                ])
                ->first();

            foreach ($group as $row) {
                if ($row['id'] === $keeper['id']) {
                    continue;
                }

                if ($row['references'] > 0) {
                    $blocked->push($row);
                } else {
                    $duplicateIds->push($row['id']);
                }
            }
        }

        $this->info(sprintf(
            '%d accounts will become %d unique usernames; %d unused duplicate accounts will be consolidated.',
            $plan->count(),
            $plan->pluck('username')->map('strtolower')->unique()->count(),
            $duplicateIds->count()
        ));

        $this->table(
            ['ID', 'Current login', 'New username', 'References'],
            $plan->filter(fn (array $row): bool => $row['current'] !== $row['username'])
                ->take(12)
                ->map(fn (array $row): array => array_values($row))
                ->all()
        );

        if ($blocked->isNotEmpty()) {
            $this->error('Normalization stopped because more than one colliding account owns related data.');
            $this->table(
                ['ID', 'Current login', 'New username', 'References'],
                $blocked->map(fn (array $row): array => array_values($row))->all()
            );

            return self::FAILURE;
        }

        if (! $this->option('apply')) {
            $this->comment('Preview only. Run with --apply to back up and update the database.');

            return self::SUCCESS;
        }

        $this->backupUsers();

        DB::transaction(function () use ($plan, $duplicateIds): void {
            foreach ($plan as $row) {
                DB::table('users')->where('id', $row['id'])->update([
                    'email' => '__username_migration__.'.$row['id'],
                ]);
            }

            if ($duplicateIds->isNotEmpty()) {
                DB::table('users')->whereIn('id', $duplicateIds)->delete();
            }

            foreach ($plan->reject(fn (array $row): bool => $duplicateIds->contains($row['id'])) as $row) {
                DB::table('users')->where('id', $row['id'])->update([
                    'email' => $row['username'],
                    'updated_at' => now(),
                ]);
            }
        });

        $this->info(sprintf(
            'Username normalization complete. The original rows are in `%s`.',
            self::BACKUP_TABLE
        ));

        return self::SUCCESS;
    }

    private function backupUsers(): void
    {
        if (! Schema::hasTable(self::BACKUP_TABLE)) {
            DB::statement(sprintf(
                'CREATE TABLE `%s` LIKE `users`',
                self::BACKUP_TABLE
            ));
        }

        if (DB::table(self::BACKUP_TABLE)->doesntExist()) {
            DB::statement(sprintf(
                'INSERT INTO `%s` SELECT * FROM `users`',
                self::BACKUP_TABLE
            ));
        }
    }

    private function referenceCount(int $userId): int
    {
        $references = [
            ['checklist_submissions', 'user_id'],
            ['checklist_submissions', 'submitted_by_user_id'],
            ['reports', 'generated_by_user_id'],
            ['sessions', 'user_id'],
            ['web_push_subscriptions', 'user_id'],
        ];
        $count = 0;

        foreach ($references as [$table, $column]) {
            if (Schema::hasTable($table) && Schema::hasColumn($table, $column)) {
                $count += DB::table($table)->where($column, $userId)->count();
            }
        }

        if (Schema::hasTable('personal_access_tokens')) {
            $count += DB::table('personal_access_tokens')
                ->where('tokenable_type', User::class)
                ->where('tokenable_id', $userId)
                ->count();
        }

        if (Schema::hasTable('notifications')) {
            $count += DB::table('notifications')
                ->where('notifiable_type', User::class)
                ->where('notifiable_id', $userId)
                ->count();
        }

        return $count;
    }
}
