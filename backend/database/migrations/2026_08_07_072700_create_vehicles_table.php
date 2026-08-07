<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->string('immatriculation')->unique();
            $table->string('model_name');
            $table->date('last_assurance_date');
            $table->integer('assurance_validity_days')->default(365);
            $table->date('last_vidange_date');
            $table->integer('vidange_validity_days')->default(90);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
