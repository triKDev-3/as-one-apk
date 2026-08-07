<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PricingGridController;
use App\Http\Controllers\ChantierController;
use App\Http\Controllers\PointageController;
use App\Http\Controllers\AvailabilityController;
use App\Http\Controllers\EquipmentController;
use App\Http\Controllers\PayrollController;
use App\Http\Controllers\VehicleController;
use App\Http\Middleware\CheckRole;

// Public Auth routes
Route::post('/auth/login', [AuthController::class, 'login']);

// Protected routes (Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Current user & profile
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::put('/users/profile', [UserController::class, 'updateSelfProfile']);

    // Admin Direction routes
    Route::middleware(CheckRole::class . ':admin_direction')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::post('/users', [UserController::class, 'store']);
        Route::patch('/users/{user}/suspend', [UserController::class, 'toggleSuspension']);
        Route::put('/pricing-grid', [PricingGridController::class, 'update']);
        Route::post('/chantiers', [ChantierController::class, 'store']);
    });

    // Pricing grid (Viewable by all auth users)
    Route::get('/pricing-grid', [PricingGridController::class, 'show']);

    // Chantiers (Viewable by chefs & admin)
    Route::get('/chantiers', [ChantierController::class, 'index']);

    // Pointage Matinal (Chef & Direction)
    Route::get('/pointages', [PointageController::class, 'index']);
    Route::post('/pointages', [PointageController::class, 'store'])->middleware(CheckRole::class . ':chef_chantier,admin_direction');

    // Availabilities
    Route::get('/availabilities', [AvailabilityController::class, 'index']);
    Route::post('/availabilities', [AvailabilityController::class, 'toggleAvailability']);
    Route::get('/availabilities/available-agents', [AvailabilityController::class, 'availableAgentsForDate']);

    // Equipment & Stock (Magasinier & Direction)
    Route::get('/equipment', [EquipmentController::class, 'index']);
    Route::post('/equipment', [EquipmentController::class, 'store'])->middleware(CheckRole::class . ':magasinier,admin_direction');
    Route::post('/equipment/return', [EquipmentController::class, 'recordReturn'])->middleware(CheckRole::class . ':magasinier,admin_direction');

    // Payroll (Comptable & Direction)
    Route::middleware(CheckRole::class . ':comptable,admin_direction')->group(function () {
        Route::get('/payroll/summary', [PayrollController::class, 'summary']);
        Route::post('/payroll/adjustments', [PayrollController::class, 'saveAdjustment']);
    });

    // Vehicles & Maintenance Alerts (Magasinier & Direction)
    Route::get('/vehicles', [VehicleController::class, 'index']);
    Route::get('/vehicles/alerts', [VehicleController::class, 'alerts']);
    Route::post('/vehicles', [VehicleController::class, 'store'])->middleware(CheckRole::class . ':magasinier,admin_direction');
});
