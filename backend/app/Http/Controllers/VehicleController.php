<?php

namespace App\Http\Controllers;

use App\Models\Vehicle;
use Illuminate\Http\Request;

class VehicleController extends Controller
{
    public function index()
    {
        $vehicles = Vehicle::orderBy('immatriculation')->get();

        // Calculate days remaining & alert status (< 7 days)
        $vehiclesWithAlerts = $vehicles->map(function ($vehicle) {
            $data = $vehicle->toArray();
            $data['assurance_days_remaining'] = $vehicle->assurance_days_remaining;
            $data['vidange_days_remaining'] = $vehicle->vidange_days_remaining;
            $data['has_assurance_alert'] = $vehicle->assurance_days_remaining <= 7;
            $data['has_vidange_alert'] = $vehicle->vidange_days_remaining <= 7;
            return $data;
        });

        return response()->json($vehiclesWithAlerts);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'immatriculation' => 'required|string|unique:vehicles,immatriculation',
            'model_name' => 'required|string|max:255',
            'last_assurance_date' => 'required|date',
            'assurance_validity_days' => 'required|integer|min:1',
            'last_vidange_date' => 'required|date',
            'vidange_validity_days' => 'required|integer|min:1',
        ]);

        $vehicle = Vehicle::create($validated);

        return response()->json([
            'message' => 'Véhicule enregistré.',
            'vehicle' => $vehicle
        ], 201);
    }

    public function alerts()
    {
        $vehicles = Vehicle::all()->filter(function ($vehicle) {
            return $vehicle->assurance_days_remaining <= 7 || $vehicle->vidange_days_remaining <= 7;
        })->values();

        return response()->json([
            'alert_count' => $vehicles->count(),
            'vehicles' => $vehicles->map(function ($v) {
                return [
                    'id' => $v->id,
                    'immatriculation' => $v->immatriculation,
                    'model_name' => $v->model_name,
                    'assurance_days_remaining' => $v->assurance_days_remaining,
                    'vidange_days_remaining' => $v->vidange_days_remaining,
                ];
            })
        ]);
    }
}
