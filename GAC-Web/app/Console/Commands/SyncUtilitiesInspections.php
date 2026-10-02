<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\UtilitiesInspectionService;
use Illuminate\Console\Command;

class SyncUtilitiesInspections extends Command
{
    protected $signature = 'utilities:sync-inspections';

    protected $description = 'Notify Utilities users at their deadlines and submit missed inspections to GM/BOM';

    public function handle(UtilitiesInspectionService $service): int
    {
        $failed = false;
        User::where('account_status', 'active')->eachById(function (User $user) use ($service, &$failed): void {
            if (! $user->isUtility()) {
                return;
            }
            try {
                $service->sync($user);
            } catch (\Throwable $error) {
                report($error);
                $failed = true;
                $this->error('Utilities sync failed for user '.$user->id.'. See application logs.');
            }
        });

        return $failed ? self::FAILURE : self::SUCCESS;
    }
}
