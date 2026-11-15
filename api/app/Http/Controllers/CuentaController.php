<?php

namespace App\Http\Controllers;

use App\Models\PerfilVendedor;
use App\Models\Usuario;
use App\Support\AccesoInstitucional;
use App\Support\BorradoCuenta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
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
            $usuario = Usuario::where('correo', $correo)->first();
            if (! $usuario || ($usuario->estado === 'activa' && $usuario->contrasena_hash === null)) {
                $this->acceso->enviar($correo, 'acceso');
            }
        });

        return response()->noContent();
    }

    public function verificar(Request $request)
    {
        $correo = $this->correo($request);
        $codigo = $this->codigo($request);
        $datos = $request->validate([
            'dispositivo' => ['required', 'string', 'max:120'],
            'contrasena' => ['required', 'string', 'min:12', 'max:128', 'confirmed'],
        ], [
            'contrasena.required' => 'Elige una contraseña para PuntoKampus.',
            'contrasena.min' => 'Usa al menos 12 caracteres.',
            'contrasena.max' => 'Usa hasta 128 caracteres.',
            'contrasena.confirmed' => 'Las contraseñas no coinciden.',
        ]);
        $resultado = $this->acceso->porCorreo($correo, function () use ($correo, $codigo, $datos) {
            $previo = Usuario::where('correo', $correo)->first();
            abort_if($previo && ($previo->estado !== 'activa' || $previo->contrasena_hash !== null),
                422, 'No pudimos verificar el registro. Si ya tienes cuenta, inicia sesión.');
            $id = $this->acceso->verificar($correo, 'acceso', $codigo);

            return DB::transaction(function () use ($id, $correo, $datos) {
                $usuario = Usuario::firstOrCreate(['correo' => $correo]);
                abort_unless($usuario->estado === null || $usuario->estado === 'activa', 403, 'Esta cuenta está desactivada.');
                $nueva = $usuario->wasRecentlyCreated;
                $usuario->forceFill(['contrasena_hash' => Hash::driver('argon2id')->make($datos['contrasena'])])->save();
                DB::table('codigos_acceso')->where('id', $id)->update(['usado_en' => now()]);

                return $this->abrirSesion($usuario, $datos['dispositivo'], $nueva);
            });
        });

        return response()->json($resultado)->header('Cache-Control', 'no-store');
    }

    public function entrar(Request $request)
    {
        $correo = $this->correo($request);
        $datos = $request->validate([
            'dispositivo' => ['required', 'string', 'max:120'],
            'contrasena' => ['required', 'string', 'max:128'],
        ]);
        $resultado = $this->acceso->porCorreo($correo, function () use ($correo, $datos) {
            $usuario = Usuario::where('correo', $correo)->first();
            $hash = Hash::driver('argon2id');
            $valida = false;
            if ($usuario?->contrasena_hash === null) {
                // Mantiene un costo comparable cuando no hay credencial.
                $hash->make($datos['contrasena']);
            } else {
                $valida = $hash->check($datos['contrasena'], $usuario->contrasena_hash);
            }
            abort_unless($valida && $usuario->estado === 'activa', 422,
                'El correo o la contraseña son incorrectos.');

            return $this->abrirSesion($usuario, $datos['dispositivo']);
        });

        return response()->json($resultado)->header('Cache-Control', 'no-store');
    }

    private function abrirSesion(Usuario $usuario, string $dispositivo, bool $nueva = false): array
    {
        $token = bin2hex(random_bytes(32));
        DB::table('sesiones_acceso')->insert([
            'usuario_id' => $usuario->id,
            'nombre_dispositivo' => $dispositivo,
            'token_hash' => hash('sha256', $token),
            'expira_en' => $this->acceso->vencimientoSesion(),
        ]);

        return ['token' => $token, 'usuario' => $this->datos($usuario), 'es_nuevo' => $nueva];
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
