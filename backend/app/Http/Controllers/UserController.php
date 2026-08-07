<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        return response()->json($query->orderBy('name')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users,phone',
            'password' => 'required|string|min:4',
            'role' => 'required|string|in:admin_direction,comptable,chef_chantier,magasinier,agent_cleaning',
            'status' => 'required|string|in:temporaire,permanent',
            'payment_operator' => 'nullable|string|in:T-Money,Flooz',
            'fixed_monthly_salary' => 'nullable|numeric|min:0',
        ]);

        $validated['password'] = Hash::make($validated['password']);
        $user = User::create($validated);

        return response()->json([
            'message' => 'Compte employé créé avec succès.',
            'user' => $user
        ], 201);
    }

    public function toggleSuspension(User $user)
    {
        $user->is_suspended = !$user->is_suspended;
        $user->save();

        $statusMsg = $user->is_suspended ? 'suspendu' : 'réactivé';

        return response()->json([
            'message' => "Le compte de {$user->name} a été {$statusMsg}.",
            'user' => $user
        ]);
    }

    public function updateSelfProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|unique:users,phone,' . $user->id,
            'payment_operator' => 'sometimes|string|in:T-Money,Flooz',
            'password' => 'nullable|string|min:4',
        ]);

        if (!empty($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $user->update($validated);

        return response()->json([
            'message' => 'Profil mis à jour avec succès.',
            'user' => $user
        ]);
    }
}
