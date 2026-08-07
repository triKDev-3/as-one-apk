<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pointage extends Model
{
    use HasFactory;

    protected $fillable = [
        'date',
        'chantier_id',
        'agent_id',
        'validated_by_chef_id',
        'shift_type',
        'rate_amount',
        'photo_path',
        'is_replacement',
        'replaced_permanent_id',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'rate_amount' => 'decimal:2',
        'is_replacement' => 'boolean',
    ];

    public function chantier()
    {
        return $this->belongsTo(Chantier::class);
    }

    public function agent()
    {
        return $this->belongsTo(User::class, 'agent_id');
    }

    public function chef()
    {
        return $this->belongsTo(User::class, 'validated_by_chef_id');
    }

    public function replacedPermanent()
    {
        return $this->belongsTo(User::class, 'replaced_permanent_id');
    }
}
