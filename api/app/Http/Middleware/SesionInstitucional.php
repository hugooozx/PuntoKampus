<?php

namespace App\Http\Middleware;

use App\Models\Usuario;
use App\Support\AccesoInstitucional;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class SesionInstitucional
{
    public function handle(Request $request, Closure $next, string $perfil = 'completo'): Response
    {
        $token = $request->bearerToken();
        abort_unless($token && preg_match('/^[0-9a-f]{64}$/D', $token), 401, 'Tu sesión no está activa.');
        $consulta = DB::table('sesiones_acceso')->where('token_hash', hash('sha256', $token));
        $sesion = (clone $consulta)->first();
        $correo = $sesion ? Usuario::find($sesion->usuario_id)?->correo : null;
        abort_unless($correo, 401, 'Tu sesión no está activa.');

        return app(AccesoInstitucional::class)->porCorreo($correo, function () use ($request, $next, $perfil, $consulta) {
            $sesion = (clone $consulta)->where('expira_en', '>', now())->first();
            $usuario = $sesion ? Usuario::find($sesion->usuario_id) : null;
            abort_unless($usuario?->estado === 'activa', 401, 'Tu sesión no está activa.');
            abort_if($perfil === 'completo' && ! $usuario->acepto_privacidad_en, 403, 'Primero completa tu perfil.');
            $request->setUserResolver(fn () => $usuario);
            $request->attributes->set('sesion_acceso_id', $sesion->id);

            $respuesta = $next($request);
            $respuesta->headers->set('Cache-Control', 'no-store');

            return $respuesta;
        });
    }
}
