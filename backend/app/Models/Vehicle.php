<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Vehicle extends Model
{
    use HasFactory;

    protected $fillable = [
        'immatriculation',
        'model_name',
        'last_assurance_date',
        'assurance_validity_days',
        'last_vidange_date',
        'vidange_validity_days',
    ];

    protected $casts = [
        'last_assurance_date' => 'date:Y-m-d',
        'last_vidange_date' => 'date:Y-m-d',
        'assurance_validity_days' => 'integer',
        'vidange_validity_days' => 'integer',
    ];

    public function getAssuranceDaysRemainingAttribute()
    {
        $expiryDate = Carbon::parse($this->last_assurance_date)->addDays($this->assurance_validity_days);
        return (int) Carbon::now()->diffInDays($expiryDate, false);
    }

    public function getVidangeDaysRemainingAttribute()
    {
        $expiryDate = Carbon::parse($this->last_vidange_date)->addDays($this->vidange_validity_days);
        return (int) Carbon::now()->diffInDays($expiryDate, false);
    }
}
