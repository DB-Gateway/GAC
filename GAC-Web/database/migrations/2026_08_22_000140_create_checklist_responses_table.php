<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('checklist_responses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('checklist_submission_id')
                ->constrained()
                ->cascadeOnDelete();
            $table->foreignId('checklist_item_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();
            $table->string('item_key', 100);
            $table->string('status', 20)->nullable();
            $table->text('remark')->nullable();
            $table->text('finding')->nullable();
            $table->text('action_plan')->nullable();
            $table->date('commitment_date')->nullable();
            $table->json('details')->nullable();
            $table->json('item_snapshot');
            $table->timestamps();

            $table->unique(
                ['checklist_submission_id', 'item_key'],
                'checklist_response_item_unique'
            );
            $table->index(['checklist_item_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('checklist_responses');
    }
};
