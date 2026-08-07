<?php

namespace App\Http\Controllers;

use App\Models\Availability;
use App\Models\User;
use Illuminate\Http\Request;

class AvailabilityController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $agentId = $user->role === 'agent_cleaning' ? $user->id : $request->query('agent_id', $user->id);

        $availabilities = Availability::where('agent_id', $agentId)
            ->where('date', '>=', now()->startOfMonth()->toDateString())
            ->get();

        return response()->json($availabilities);
    }

    public function toggleAvailability(Request $request)
    {
        $validated = $request->validate([
            'date' => 'required|date',
            'is_available' => 'required|boolean',
        ]);

        $user = $request->user();

        $availability = Availability::updateOrCreate(
            ['agent_id' => $user->id, 'date' => $validated['date']],
            ['is_available' => $validated['is_available']]
        );

        return response()->json([
            'message' => 'Disponibilité mise à jour.',
            'availability' => $availability
        ]);
    }

    public function availableAgentsForDate(Request $request)
    {
        $date = $request->query('date', now()->addDay()->toDateString());

        // Get all active agents who are either declared available for this date or have not declared unavailable
        $availableAgentIds = Availability::where('date', $date)
            ->where('is_available', true)
            ->pluck('agent_id');

        $agents = User::where('role', 'agent_cleaning')
            ->where('is_suspended', false)
            ->whereIn('id', $availableAgentIds)
            ->get();

        return response()->json([
            'date' => $date,
            'available_agents' => $agents
        ]);
    }
}
