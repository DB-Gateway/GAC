<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('checklist_responses', 'escalation_target')) {
            Schema::table('checklist_responses', function (Blueprint $table): void {
                $table->string('escalation_target', 50)
                    ->nullable()
                    ->after('action_plan');
            });
        }

        // Existing DATE values are retained as midnight when widened to DATETIME.
        Schema::table('checklist_responses', function (Blueprint $table): void {
            $table->dateTime('commitment_date')->nullable()->change();
        });

        // Preserve escalation choices saved by early mobile/web clients in details JSON.
        DB::table('checklist_responses')
            ->select(['id', 'details'])
            ->whereNull('escalation_target')
            ->whereNotNull('details')
            ->orderBy('id')
            ->chunkById(200, function ($responses): void {
                foreach ($responses as $response) {
                    $details = is_string($response->details)
                        ? json_decode($response->details, true)
                        : (array) $response->details;
                    $value = $details['escalation_target'] ?? $details['escalation'] ?? null;
                    $target = match (mb_strtolower(trim((string) $value))) {
                        'gm', 'general manager', 'general_manager' => 'general_manager',
                        'purchasing', 'purchasing team', 'purchasing_team' => 'purchasing',
                        'pm', 'property management', 'property_management',
                        'purchasing manager', 'purchasing_manager' => 'property_management',
                        'inventory', 'inventory team', 'inventory_team' => 'inventory',
                        default => null,
                    };

                    if ($target !== null) {
                        DB::table('checklist_responses')
                            ->where('id', $response->id)
                            ->update(['escalation_target' => $target]);
                    }
                }
            });
    }

    public function down(): void
    {
        Schema::table('checklist_responses', function (Blueprint $table): void {
            $table->date('commitment_date')->nullable()->change();
        });

        if (Schema::hasColumn('checklist_responses', 'escalation_target')) {
            Schema::table('checklist_responses', function (Blueprint $table): void {
                $table->dropColumn('escalation_target');
            });
        }
    }
};
