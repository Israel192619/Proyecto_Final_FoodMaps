<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class IsOwnerMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        //dd(auth()->user());
        $user = auth()->user();
        if (!$user) {
            return response()->json(['message' => 'No autenticado.'], 401);
        }
        if ($user->role_id !== 2) {
            return response()->json(['message' => 'Solo los dueños pueden acceder.'], 403);
        }
        return $next($request);
    }
}
