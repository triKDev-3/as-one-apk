<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Pointage;
use App\Models\PayrollAdjustment;
use Illuminate\Http\Request;

class PayrollController extends Controller
{
    public function summary(Request $request)
    {
        $period = $request->query('period', now()->format('Y-m') . '-30');
        $users = User::where('is_suspended', false)->get();

        $summary = [];

        foreach ($users as $user) {
            $pointages = Pointage::where('agent_id', $user->id)
                ->where('date', 'like', substr($period, 0, 7) . '%')
                ->get();

            $grossShifts = $pointages->sum('rate_amount');

            $fixedSalary = $user->status === 'permanent' ? (float) $user->fixed_monthly_salary : 0.0;
            $grossTotal = $user->status === 'permanent' ? $fixedSalary : $grossShifts;

            $adjustment = PayrollAdjustment::where('agent_id', $user->id)
                ->where('period', $period)
                ->first();

            $primes = (float) ($adjustment->primes ?? 0);
            $advances = (float) ($adjustment->advances ?? 0);
            $penalties = (float) ($adjustment->penalties ?? 0);

            $netSalary = max(0, $grossTotal + $primes - $advances - $penalties);

            $summary[] = [
                'agent_id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'role' => $user->role,
                'status' => $user->status,
                'payment_operator' => $user->payment_operator,
                'fixed_monthly_salary' => $fixedSalary,
                'shifts_count' => $pointages->count(),
                'gross_shifts' => $grossShifts,
                'gross_total' => $grossTotal,
                'primes' => $primes,
                'advances' => $advances,
                'penalties' => $penalties,
                'net_salary' => $netSalary,
                'notes' => $adjustment->notes ?? '',
            ];
        }

        return response()->json([
            'period' => $period,
            'summary' => $summary
        ]);
    }

    public function saveAdjustment(Request $request)
    {
        $validated = $request->validate([
            'agent_id' => 'required|exists:users,id',
            'period' => 'required|string',
            'primes' => 'nullable|numeric|min:0',
            'advances' => 'nullable|numeric|min:0',
            'penalties' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $adj = PayrollAdjustment::updateOrCreate(
            ['agent_id' => $validated['agent_id'], 'period' => $validated['period']],
            [
                'primes' => $validated['primes'] ?? 0,
                'advances' => $validated['advances'] ?? 0,
                'penalties' => $validated['penalties'] ?? 0,
                'notes' => $validated['notes'] ?? '',
            ]
        );

        return response()->json([
            'message' => 'Ajustement de paie enregistré.',
            'adjustment' => $adj
        ]);
    }
}
