<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chantiers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('location');
            $table->foreignId('assigned_chef_id')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chantiers');
    }
};
