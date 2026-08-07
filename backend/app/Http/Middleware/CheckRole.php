<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        $user = $request->user();

        if (!$user || $user->is_suspended) {
            return response()->json([
                'message' => 'Accès refusé ou compte suspendu.'
            ], 403);
        }

        if (!empty($roles) && !in_array($user->role, $roles)) {
            return response()->json([
                'message' => "Rôle insuffisant pour cette action. Rôles requis: " . implode(', ', $roles)
            ], 403);
        }

        return $next($request);
    }
}
