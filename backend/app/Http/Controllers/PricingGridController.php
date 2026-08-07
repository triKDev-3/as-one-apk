<?php

namespace App\Http\Controllers;

use App\Models\PricingGrid;
use Illuminate\Http\Request;

class PricingGridController extends Controller
{
    public function show()
    {
        $grid = PricingGrid::firstOrCreate(
            ['id' => 1],
            [
                'standard_day_rate' => 2500.00,
                'night_rate' => 4500.00,
                'sunday_rate' => 5000.00,
            ]
        );

        return response()->json($grid);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'standard_day_rate' => 'required|numeric|min:0',
            'night_rate' => 'required|numeric|min:0',
            'sunday_rate' => 'required|numeric|min:0',
        ]);

        $grid = PricingGrid::firstOrCreate(['id' => 1]);
        $grid->update($validated);

        return response()->json([
            'message' => 'Grille tarifaire mise à jour avec succès.',
            'pricing_grid' => $grid
        ]);
    }
}
