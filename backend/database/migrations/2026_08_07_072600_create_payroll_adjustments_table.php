<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payroll_adjustments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('agent_id')->constrained('users')->onDelete('cascade');
            $table->string('period'); // e.g. 2026-08-15 or 2026-08-31
            $table->decimal('primes', 12, 2)->default(0.00);
            $table->decimal('advances', 12, 2)->default(0.00);
            $table->decimal('penalties', 12, 2)->default(0.00);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['agent_id', 'period']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payroll_adjustments');
    }
};
