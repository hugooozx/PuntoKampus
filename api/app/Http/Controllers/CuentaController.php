<?php

namespace App\Http\Controllers;

use App\Models\PerfilVendedor;
use App\Models\Usuario;
use App\Support\AccesoInstitucional;
use App\Support\BorradoCuenta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CuentaController extends Controller
{
    public function __construct(private AccesoInstitucional $acceso) {}

    private function correo(Request $request): string
    {
        $correo = $request->validate(['correo' => ['required', 'string', 'max:254', 'email']])['correo'];
        $correo = strtolower($correo);
        $dominio = substr(strrchr($correo, '@'), 1);
        if (! preg_match('/^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)*utb\.edu\.ec$/D', $dominio)
            || ! preg_match('/^[a-z0-9.!#$%&\x27*+\/=?^_`{|}~@-]+$/D', $correo)) {
            throw ValidationException::withMessages(['correo' => 'Solo se puede entrar con un correo de la UTB o de una de sus facultades.']);
        }

        return $correo;
    }

    private function codigo(Request $request): string
    {
        return $request->validate(['codigo' => ['required', 'string', 'regex:/^[0-9]{6}$/D']])['codigo'];
    }

    public function pedirCodigo(Request $request)
    {
        $correo = $this->correo($request);
        $this->acceso->porCorreo($correo, function () use ($correo) {
            abort_if(Usuario::where('correo', $correo)->where('estado', 'desactivada')->exists(), 403, 'Esta cuenta está desactivada.');
            $this->acceso->enviar($correo, 'acceso');
        });

        return response()->noContent();
    }

    public function verificar(Request $request)
    {
        $correo = $this->correo($request);
        $codigo = $this->codigo($request);
        $dispositivo = $request->validate(['dispositivo' => ['required', 'string', 'max:120']])['dispositivo'];
        $resultado = $this->acceso->porCorreo($correo, function () use ($correo, $codigo, $dispositivo) {
            $id = $this->acceso->verificar($correo, 'acceso', $codigo);

            return DB::transaction(function () use ($id, $correo, $dispositivo) {
                $usuario = Usuario::firstOrCreate(['correo' => $correo]);
                abort_unless($usuario->estado === null || $usuario->estado === 'activa', 403, 'Esta cuenta está desactivada.');
                $token = bin2hex(random_bytes(32));
                DB::table('sesiones_acceso')->insert([
                    'usuario_id' => $usuario->id,
                    'nombre_dispositivo' => $dispositivo,
                    'token_hash' => hash('sha256', $token),
                    'expira_en' => $this->acceso->vencimientoSesion(),
                ]);
                DB::table('codigos_acceso')->where('id', $id)->update(['usado_en' => now()]);

                return ['token' => $token, 'usuario' => $this->datos($usuario), 'es_nuevo' => $usuario->wasRecentlyCreated];
            });
        });

        return response()->json($resultado)->header('Cache-Control', 'no-store');
    }

    public function salir(Request $request)
    {
        DB::table('sesiones_acceso')->where('id', $request->attributes->get('sesion_acceso_id'))->delete();

        return response()->noContent();
    }

    public function ver(Request $request): array
    {
        return $this->datos($request->user());
    }

    public function actualizar(Request $request): array
    {
        $usuario = $request->user();
        if (! $usuario->acepto_privacidad_en && ! app()->environment('local', 'testing')) {
            abort_unless(config('puntokampus.responsable') && config('puntokampus.contacto'),
                503, 'El registro aún no está disponible.');
        }
        $datos = $request->validate([
            'nombres' => ['required', 'string', 'max:150'],
            'acepto_privacidad' => [$usuario->acepto_privacidad_en ? 'sometimes' : 'required', 'accepted'],
            'mostrar_whatsapp' => ['sometimes', 'boolean'],
        ]);

        return DB::transaction(function () use ($usuario, $datos) {
            if (array_key_exists('mostrar_whatsapp', $datos)) {
                $perfil = PerfilVendedor::find($usuario->id);
                if (! $perfil) {
                    throw ValidationException::withMessages(['mostrar_whatsapp' => 'Crea tu perfil de vendedor antes de publicar tu WhatsApp.']);
                }
                $perfil->update(['mostrar_whatsapp' => $datos['mostrar_whatsapp']]);
            }
            $usuario->update([
                'nombres' => $datos['nombres'],
                'acepto_privacidad_en' => $usuario->acepto_privacidad_en ?? now(),
            ]);

            return $this->datos($usuario);
        });
    }

    public function pedirBorrado(Request $request)
    {
        $this->acceso->enviar($request->user()->correo, 'eliminar_cuenta');

        return response()->noContent();
    }

    public function pedirBorradoWeb(Request $request)
    {
        $correo = $this->correo($request);
        $this->acceso->porCorreo($correo, fn () => $this->acceso->enviar($correo, 'eliminar_cuenta'));

        return response()->noContent();
    }

    public function borrar(Request $request, BorradoCuenta $borrado)
    {
        $this->confirmarBorrado($request->user()->correo, $this->codigo($request), $borrado);

        return response()->noContent();
    }

    public function borrarWeb(Request $request, BorradoCuenta $borrado)
    {
        $correo = $this->correo($request);
        $codigo = $this->codigo($request);
        $this->acceso->porCorreo($correo, fn () => $this->confirmarBorrado($correo, $codigo, $borrado));

        return response()->noContent();
    }

    private function confirmarBorrado(string $correo, string $codigo, BorradoCuenta $borrado): void
    {
        $this->acceso->verificar($correo, 'eliminar_cuenta', $codigo);
        DB::transaction(fn () => $borrado->borrar($correo));
        $borrado->limpiarArchivos();
    }

    private function datos(Usuario $usuario): array
    {
        $perfil = PerfilVendedor::find($usuario->id);

        return [
            'id' => $usuario->id,
            'correo' => $usuario->correo,
            'nombres' => $usuario->nombres,
            'acepto_privacidad_en' => $usuario->acepto_privacidad_en?->toISOString(),
            'mostrar_whatsapp' => $perfil?->mostrar_whatsapp,
            'tienda' => DB::table('tiendas')->where('usuario_id', $usuario->id)->first(['id', 'nombre', 'slug', 'estado']),
        ];
    }
}
