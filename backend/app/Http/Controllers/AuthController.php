<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('phone', $request->phone)->first();

        if (!$user || !Hash::check($request->password, $request->password)) {
            throw ValidationException::withMessages([
                'phone' => ['Numéro de téléphone ou mot de passe incorrect.'],
            ]);
        }

        if ($user->is_suspended) {
            return response()->json([
                'message' => 'Ce compte a été suspendu par la Direction Générale.'
            ], 403);
        }

        $token = $user->createToken('as_one_auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Connexion réussie.',
            'token' => $token,
            'user' => $user
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user()
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Déconnexion réussie.'
        ]);
    }
}
