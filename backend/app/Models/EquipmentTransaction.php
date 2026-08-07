<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EquipmentTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'equipment_id',
        'chantier_id',
        'agent_or_chef_id',
        'transaction_type',
        'condition',
        'is_indulgence_granted',
        'sanction_type',
        'penalty_amount',
        'date',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'is_indulgence_granted' => 'boolean',
        'penalty_amount' => 'decimal:2',
    ];

    public function equipment()
    {
        return $this->belongsTo(Equipment::class);
    }

    public function chantier()
    {
        return $this->belongsTo(Chantier::class);
    }

    public function agentOrChef()
    {
        return $this->belongsTo(User::class, 'agent_or_chef_id');
    }
}
