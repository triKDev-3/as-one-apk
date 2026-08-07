<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pricing_grids', function (Blueprint $table) {
            $table->id();
            $table->decimal('standard_day_rate', 10, 2)->default(2500.00);
            $table->decimal('night_rate', 10, 2)->default(4500.00);
            $table->decimal('sunday_rate', 10, 2)->default(5000.00);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pricing_grids');
    }
};
