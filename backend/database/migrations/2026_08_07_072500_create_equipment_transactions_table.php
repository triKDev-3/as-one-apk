<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('equipment_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('equipment_id')->constrained('equipment')->onDelete('cascade');
            $table->foreignId('chantier_id')->constrained('chantiers')->onDelete('cascade');
            $table->foreignId('agent_or_chef_id')->constrained('users')->onDelete('cascade');
            $table->string('transaction_type'); // CHECKOUT, RETURN
            $table->string('condition')->default('BON'); // BON, DEGRADE, MANQUANT
            $table->boolean('is_indulgence_granted')->default(false);
            $table->string('sanction_type')->default('NONE'); // NONE, INDIVIDUAL, COLLECTIVE
            $table->decimal('penalty_amount', 12, 2)->default(0.00);
            $table->date('date');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('equipment_transactions');
    }
};
