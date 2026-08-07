<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PricingGrid extends Model
{
    use HasFactory;

    protected $fillable = [
        'standard_day_rate',
        'night_rate',
        'sunday_rate',
    ];

    protected $casts = [
        'standard_day_rate' => 'decimal:2',
        'night_rate' => 'decimal:2',
        'sunday_rate' => 'decimal:2',
    ];
}
