<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pointages', function (Blueprint $table) {
            $table->id();
            $table->date('date');
            $table->foreignId('chantier_id')->constrained('chantiers')->onDelete('cascade');
            $table->foreignId('agent_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('validated_by_chef_id')->constrained('users')->onDelete('cascade');
            $table->string('shift_type'); // JOURNEE, NUIT, DIMANCHE
            $table->decimal('rate_amount', 10, 2);
            $table->string('photo_path')->nullable();
            $table->boolean('is_replacement')->default(false);
            $table->foreignId('replaced_permanent_id')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pointages');
    }
};
