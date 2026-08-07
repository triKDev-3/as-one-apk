<?php

namespace App\Http\Controllers;

use App\Models\Pointage;
use App\Models\PricingGrid;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PointageController extends Controller
{
    public function index(Request $request)
    {
        $query = Pointage::with(['chantier', 'agent', 'chef', 'replacedPermanent']);

        if ($request->has('date')) {
            $query->where('date', $request->date);
        }

        if ($request->has('chantier_id')) {
            $query->where('chantier_id', $request->chantier_id);
        }

        if ($request->has('agent_id')) {
            $query->where('agent_id', $request->agent_id);
        }

        return response()->json($query->orderBy('date', 'desc')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'date' => 'required|date',
            'chantier_id' => 'required|exists:chantiers,id',
            'photo' => 'nullable|image|max:10240', // 10MB max photo proof
            'agents' => 'required|array|min:1',
            'agents.*.agent_id' => 'required|exists:users,id',
            'agents.*.shift_type' => 'required|string|in:JOURNEE,NUIT,DIMANCHE',
            'agents.*.is_replacement' => 'nullable|boolean',
            'agents.*.replaced_permanent_id' => 'nullable|exists:users,id',
        ]);

        $chef = $request->user();
        $date = $request->date;
        $chantierId = $request->chantier_id;

        // Upload photo if provided
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('pointage_proofs', 'public');
        }

        $grid = PricingGrid::first();
        $rates = [
            'JOURNEE' => $grid->standard_day_rate ?? 2500.00,
            'NUIT' => $grid->night_rate ?? 4500.00,
            'DIMANCHE' => $grid->sunday_rate ?? 5000.00,
        ];

        // Replace existing pointages for this site & date
        Pointage::where('chantier_id', $chantierId)->where('date', $date)->delete();

        $createdPointages = [];
        foreach ($request->agents as $agentData) {
            $shiftType = $agentData['shift_type'];
            $rateAmount = $rates[$shiftType] ?? 2500.00;

            $pointage = Pointage::create([
                'date' => $date,
                'chantier_id' => $chantierId,
                'agent_id' => $agentData['agent_id'],
                'validated_by_chef_id' => $chef->id,
                'shift_type' => $shiftType,
                'rate_amount' => $rateAmount,
                'photo_path' => $photoPath,
                'is_replacement' => $agentData['is_replacement'] ?? false,
                'replaced_permanent_id' => $agentData['replaced_permanent_id'] ?? null,
            ]);

            $createdPointages[] = $pointage;
        }

        return response()->json([
            'message' => 'Pointage matinal enregistré et validé avec succès.',
            'count' => count($createdPointages),
            'photo_url' => $photoPath ? Storage::disk('public')->url($photoPath) : null,
            'pointages' => Pointage::with(['agent', 'replacedPermanent'])->where('chantier_id', $chantierId)->where('date', $date)->get()
        ], 201);
    }
}
