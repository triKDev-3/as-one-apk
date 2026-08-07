<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Equipment extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'category',
        'total_quantity',
        'available_quantity',
        'unit_value',
    ];

    protected $casts = [
        'unit_value' => 'decimal:2',
        'total_quantity' => 'integer',
        'available_quantity' => 'integer',
    ];

    public function transactions()
    {
        return $this->hasMany(EquipmentTransaction::class);
    }
}
