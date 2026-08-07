<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Chantier extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'location',
        'assigned_chef_id',
    ];

    public function chef()
    {
        return $this->belongsTo(User::class, 'assigned_chef_id');
    }

    public function pointages()
    {
        return $this->hasMany(Pointage::class);
    }
}
