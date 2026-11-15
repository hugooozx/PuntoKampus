<?php

namespace App\Http\Controllers;

use App\Models\Usuario;
use App\Support\AccesoInstitucional;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

class AccesoAdministracionController extends Controller
{
    private const PROPOSITO = 'administracion';

    public function enviar(Request $request, AccesoInstitucional $acceso)
    {
        $correo = strtolower($request->validate(['correo' => 'required|email|max:254'])['correo']);
        $request->session()->put('correo_administracion', $correo);
        try {
            $acceso->porCorreo($correo, function () use ($acceso, $correo) {
                if ($this->administradores($correo)->exists()) {
                    $acceso->enviar($correo, self::PROPOSITO);
                }
            });
        } catch (HttpExceptionInterface $error) {
            if ($error->getStatusCode() === 429) {
                // Mismo mensaje que para un correo no habilitado.
                return redirect()->route('filament.admin.auth.login');
            }
            throw ValidationException::withMessages(['correo' => $error->getMessage()]);
        }

        return redirect()->route('filament.admin.auth.login');
    }

    public function verificar(Request $request, AccesoInstitucional $acceso)
    {
        $codigo = $request->validate(['codigo' => ['required', 'string', 'regex:/^[0-9]{6}$/D']])['codigo'];
        $correo = $request->session()->get('correo_administracion');
        if (! is_string($correo)) {
            throw ValidationException::withMessages(['correo' => 'Pide un código para entrar.']);
        }
        try {
            $usuario = $acceso->porCorreo($correo, function () use ($acceso, $correo, $codigo) {
                abort_unless($this->administradores($correo)->exists(), 422, 'El código no es válido o ya venció.');
                $id = $acceso->verificar($correo, self::PROPOSITO, $codigo);

                return DB::transaction(function () use ($id, $correo) {
                    $usuario = $this->administradores($correo)->lockForUpdate()->first();
                    abort_unless($usuario, 422, 'El código no es válido o ya venció.');
                    DB::table('codigos_acceso')->where('id', $id)->update(['usado_en' => now()]);

                    return $usuario;
                });
            });
        } catch (HttpExceptionInterface $error) {
            if (! in_array($error->getStatusCode(), [422, 429, 503], true)) {
                throw $error;
            }
            throw ValidationException::withMessages(['codigo' => 'El código no es válido o ya venció. Si hiciste varios intentos, pide uno nuevo.']);
        }
        Auth::guard('administracion')->login($usuario);
        $request->session()->regenerate();
        $request->session()->forget('correo_administracion');

        return redirect()->route('filament.admin.resources.reportes.index');
    }

    private function administradores(string $correo)
    {
        return Usuario::where('correo', $correo)->where('es_admin', true)->where('estado', 'activa');
    }
}
