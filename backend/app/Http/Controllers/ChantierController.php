<?php

namespace App\Http\Controllers;

use App\Models\Chantier;
use Illuminate\Http\Request;

class ChantierController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Chantier::with('chef');

        if ($user->role === 'chef_chantier') {
            $query->where('assigned_chef_id', $user->id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'location' => 'required|string|max:255',
            'assigned_chef_id' => 'required|exists:users,id',
        ]);

        $chantier = Chantier::create($validated);
        $chantier->load('chef');

        return response()->json([
            'message' => 'Chantier créé avec succès.',
            'chantier' => $chantier
        ], 201);
    }
}
