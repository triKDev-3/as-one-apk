<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PayrollAdjustment extends Model
{
    use HasFactory;

    protected $fillable = [
        'agent_id',
        'period',
        'primes',
        'advances',
        'penalties',
        'notes',
    ];

    protected $casts = [
        'primes' => 'decimal:2',
        'advances' => 'decimal:2',
        'penalties' => 'decimal:2',
    ];

    public function agent()
    {
        return $this->belongsTo(User::class, 'agent_id');
    }
}
