<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Availability extends Model
{
    use HasFactory;

    protected $fillable = [
        'agent_id',
        'date',
        'is_available',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'is_available' => 'boolean',
    ];

    public function agent()
    {
        return $this->belongsTo(User::class, 'agent_id');
    }
}
