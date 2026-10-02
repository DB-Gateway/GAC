<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dealer_checklist_settings', function (Blueprint $table): void {
            $table->id();
            $table->string('dealer');
            $table->string('category', 40);
            $table->boolean('is_enabled')->default(true);
            $table->foreignId('updated_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['dealer', 'category']);
            $table->index(['category', 'is_enabled']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dealer_checklist_settings');
    }
};
