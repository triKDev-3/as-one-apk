<?php

namespace App\Http\Controllers;

use App\Models\Equipment;
use App\Models\EquipmentTransaction;
use App\Models\Pointage;
use App\Models\PayrollAdjustment;
use Illuminate\Http\Request;

class EquipmentController extends Controller
{
    public function index()
    {
        return response()->json(Equipment::orderBy('name')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'required|string|in:TRACEABLE,CONSUMABLE',
            'total_quantity' => 'required|integer|min:1',
            'unit_value' => 'required|numeric|min:0',
        ]);

        $validated['available_quantity'] = $validated['total_quantity'];
        $equipment = Equipment::create($validated);

        return response()->json([
            'message' => 'Équipement ajouté à l\'inventaire.',
            'equipment' => $equipment
        ], 201);
    }

    public function recordReturn(Request $request)
    {
        $validated = $request->validate([
            'equipment_id' => 'required|exists:equipment,id',
            'chantier_id' => 'required|exists:chantiers,id',
            'agent_or_chef_id' => 'required|exists:users,id',
            'quantity_returned' => 'required|integer|min:1',
            'condition' => 'required|string|in:BON,DEGRADE,MANQUANT',
            'is_indulgence_granted' => 'required|boolean',
            'sanction_type' => 'required|string|in:NONE,INDIVIDUAL,COLLECTIVE',
            'date' => 'required|date',
        ]);

        $equipment = Equipment::findOrFail($validated['equipment_id']);
        $penaltyAmount = 0.0;

        // Calculate penalty if not indulgence
        if (in_array($validated['condition'], ['DEGRADE', 'MANQUANT']) && !$validated['is_indulgence_granted']) {
            $penaltyAmount = (float) $equipment->unit_value;
        }

        // Update available quantity
        $newAvailable = min($equipment->total_quantity, $equipment->available_quantity + $validated['quantity_returned']);
        $equipment->update(['available_quantity' => $newAvailable]);

        $transaction = EquipmentTransaction::create([
            'equipment_id' => $equipment->id,
            'chantier_id' => $validated['chantier_id'],
            'agent_or_chef_id' => $validated['agent_or_chef_id'],
            'transaction_type' => 'RETURN',
            'condition' => $validated['condition'],
            'is_indulgence_granted' => $validated['is_indulgence_granted'],
            'sanction_type' => $validated['sanction_type'],
            'penalty_amount' => $penaltyAmount,
            'date' => $validated['date'],
        ]);

        // Process Sanction if penalty > 0
        if ($penaltyAmount > 0) {
            $period = substr($validated['date'], 0, 7) . '-30';

            if ($validated['sanction_type'] === 'INDIVIDUAL') {
                // Apply penalty directly to responsible agent
                $adj = PayrollAdjustment::firstOrCreate(
                    ['agent_id' => $validated['agent_or_chef_id'], 'period' => $period],
                    ['primes' => 0, 'advances' => 0, 'penalties' => 0, 'notes' => '']
                );
                $adj->penalties += $penaltyAmount;
                $adj->notes .= " | Retenue Individuelle ({$equipment->name}): {$penaltyAmount} FCFA";
                $adj->save();
            } elseif ($validated['sanction_type'] === 'COLLECTIVE') {
                // Divide penalty equally among all agents on site for that date
                $onSiteAgentIds = Pointage::where('chantier_id', $validated['chantier_id'])
                    ->where('date', $validated['date'])
                    ->pluck('agent_id')
                    ->unique();

                if ($onSiteAgentIds->count() > 0) {
                    $splitPenalty = round($penaltyAmount / $onSiteAgentIds->count(), 2);
                    foreach ($onSiteAgentIds as $agId) {
                        $adj = PayrollAdjustment::firstOrCreate(
                            ['agent_id' => $agId, 'period' => $period],
                            ['primes' => 0, 'advances' => 0, 'penalties' => 0, 'notes' => '']
                        );
                        $adj->penalties += $splitPenalty;
                        $adj->notes .= " | Retenue Collective ({$equipment->name}): {$splitPenalty} FCFA";
                        $adj->save();
                    }
                }
            }
        }

        return response()->json([
            'message' => 'Retour de matériel enregistré avec succès.',
            'transaction' => $transaction,
            'equipment' => $equipment
        ]);
    }
}
