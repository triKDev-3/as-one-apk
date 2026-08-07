<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'phone',
        'email',
        'password',
        'role',
        'status',
        'is_suspended',
        'payment_operator',
        'fixed_monthly_salary',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_suspended' => 'boolean',
            'fixed_monthly_salary' => 'decimal:2',
        ];
    }

    public function chantiersAssigned()
    {
        return $this->hasMany(Chantier::class, 'assigned_chef_id');
    }

    public function pointages()
    {
        return $this->hasMany(Pointage::class, 'agent_id');
    }

    public function availabilities()
    {
        return $this->hasMany(Availability::class, 'agent_id');
    }

    public function payrollAdjustments()
    {
        return $this->hasMany(PayrollAdjustment::class, 'agent_id');
    }
}
