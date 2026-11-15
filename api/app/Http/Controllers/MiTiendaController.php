<?php

namespace App\Http\Controllers;

use App\Http\Resources\TiendaResource;
use App\Models\PerfilVendedor;
use App\Models\Tienda;
use App\Support\BorradoCuenta;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Throwable;

class MiTiendaController extends Controller
{
    public function facultades(): array
    {
        return ['data' => DB::table('facultades')->where('activa', true)->orderBy('nombre')->get(['id', 'nombre'])];
    }

    public function carreras(Request $request): array
    {
        $input = $request->validate(['facultad_id' => ['required', 'integer', $this->catalogo('facultades')]]);

        return ['data' => DB::table('carreras')->where('activa', true)->where('facultad_id', $input['facultad_id'])
            ->orderBy('nombre')->get(['id', 'facultad_id', 'nombre'])];
    }

    public function ver(Request $request): array
    {
        $tienda = $this->delUsuario($request)->first();

        return $this->respuesta($request, $tienda, $tienda?->perfilVendedor ?? PerfilVendedor::find($request->user()->id));
    }

    public function crear(Request $request)
    {
        $usuario = $request->user();
        abort_if($this->delUsuario($request)->exists(), 409, 'Ya tienes una tienda. Abre «Mi tienda» para editarla.');
        $perfil = PerfilVendedor::find($usuario->id);
        $datos = $request->validate($this->reglasTienda() + $this->reglasImagen() + ($perfil ? [] : [
            'codigo_estudiante' => ['required', 'string', 'max:40'],
            'carrera_id' => ['required', 'integer', Rule::exists('carreras', 'id')->where(fn ($query) => $query->where('activa', true)->whereIn('facultad_id', DB::table('facultades')->where('activa', true)->select('id')))],
            'semestre' => ['required', 'integer', 'between:1,10'],
            'whatsapp' => ['required', 'string', 'max:40'],
            'mostrar_whatsapp' => ['sometimes', 'boolean'],
        ]), $this->mensajes());

        $vendedor = $perfil ? [] : Arr::only($datos, ['codigo_estudiante', 'carrera_id', 'semestre', 'mostrar_whatsapp']);
        if (! $perfil) {
            $vendedor['whatsapp'] = $this->normalizarWhatsapp($datos['whatsapp']);
        }
        $base = Str::slug($datos['nombre']) ?: 'tienda';
        $archivo = $this->guardarImagen($request->file('imagen'));
        try {
            for ($intento = 0; ; $intento++) {
                $slug = $intento === 0 ? $base : $base.'-'.Str::lower(Str::random(8));
                try {
                    $tienda = DB::transaction(function () use ($usuario, $perfil, $vendedor, $datos, $slug, $archivo) {
                        if (! $perfil) {
                            PerfilVendedor::create(['usuario_id' => $usuario->id] + $vendedor);
                        }
                        $tienda = Tienda::create($this->datosTienda($datos) + [
                            'usuario_id' => $usuario->id, 'slug' => $slug,
                            'logo_url' => $archivo ? '/storage/'.$archivo : null,
                        ]);
                        $this->categorias($tienda, $datos);

                        return $tienda;
                    });
                    break;
                } catch (UniqueConstraintViolationException $error) {
                    if ($intento >= 2 || ! str_contains($error->getMessage(), 'uq_tiendas_slug')) {
                        throw $error;
                    }
                }
            }
        } catch (Throwable $error) {
            if ($archivo) {
                Storage::disk('public')->delete($archivo);
            }
            throw $error;
        }
        $tienda->refresh();

        return response()->json($this->respuesta($request, $tienda, $tienda->perfilVendedor), 201);
    }

    public function actualizar(Request $request): array
    {
        $tienda = $this->delUsuario($request)->firstOrFail();
        $datos = $request->validate($this->reglasTienda(), $this->mensajes());
        DB::transaction(function () use ($tienda, $datos) {
            $tienda->update($this->datosTienda($datos));
            $this->categorias($tienda, $datos);
        });

        return $this->respuesta($request, $tienda->refresh(), $tienda->perfilVendedor);
    }

    public function logo(Request $request): array
    {
        $tienda = $this->delUsuario($request)->firstOrFail();
        $request->validate($this->reglasImagen('required'), $this->mensajes());
        $archivo = $this->guardarImagen($request->file('imagen'));
        $urlAnterior = $tienda->logo_url;
        try {
            DB::transaction(function () use ($tienda, $archivo, $urlAnterior) {
                $tienda->update(['logo_url' => '/storage/'.$archivo]);
                if ($urlAnterior && preg_match('~^/storage/(tiendas/[a-z0-9]+\.(jpg|png|webp))$~D', $urlAnterior, $ruta)) {
                    DB::table('borrados_archivos')->insert(['disco' => 'public', 'ruta' => $ruta[1]]);
                }
            });
        } catch (Throwable $error) {
            Storage::disk('public')->delete($archivo);
            throw $error;
        }
        if ($urlAnterior) {
            app(BorradoCuenta::class)->limpiarArchivos();
        }

        return ['logo_url' => $tienda->logo_url];
    }

    public function portada(Request $request)
    {
        $tienda = $this->delUsuario($request)->firstOrFail();
        abort_unless($tienda->tienePremium(), 403, 'La portada está disponible con Premium.');
        abort(501, 'La carga de portadas se habilitará con el flujo Premium.');
    }

    public function imagenPublica(string $archivo)
    {
        abort_unless(Tienda::where('logo_url', '/storage/tiendas/'.$archivo)->exists(), 404);
        $disco = Storage::disk('public');
        abort_unless($disco->exists('tiendas/'.$archivo), 404);

        return $disco->response('tiendas/'.$archivo, $archivo, ['X-Content-Type-Options' => 'nosniff']);
    }

    private function delUsuario(Request $request)
    {
        abort_if($request->user()->es_admin, 403, 'Las cuentas de administración no publican tiendas.');

        return Tienda::where('usuario_id', $request->user()->id);
    }

    private function reglasTienda(): array
    {
        return [
            'nombre' => ['required', 'string', 'min:3', 'max:40'],
            'descripcion' => ['nullable', 'string', 'max:300'],
            'horario' => ['nullable', 'string', 'max:100'],
            'punto_entrega_id' => ['required', 'integer', $this->catalogo('puntos_entrega')],
            'categoria_1_id' => ['required', 'integer', $this->catalogo('categorias')],
            'categoria_2_id' => ['nullable', 'integer', 'different:categoria_1_id', $this->catalogo('categorias')],
        ];
    }

    private function reglasImagen(string $presencia = 'sometimes'): array
    {
        return ['imagen' => [$presencia, 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048', 'dimensions:max_width=2048,max_height=2048']];
    }

    private function catalogo(string $tabla)
    {
        return Rule::exists($tabla, 'id')->where('activa', true);
    }

    private function mensajes(): array
    {
        return [
            'nombre.*' => 'Escribe un nombre de 3 a 40 caracteres.',
            'descripcion.*' => 'Escribe una descripción de hasta 300 caracteres.',
            'horario.*' => 'Escribe un horario de hasta 100 caracteres.',
            'categoria_1_id.*' => 'Elige una categoría principal activa.',
            'categoria_2_id.*' => 'Elige otra categoría activa o deja la segunda vacía.',
            'punto_entrega_id.*' => 'Elige un punto de entrega activo.',
            'carrera_id.*' => 'Elige una carrera activa.',
            'codigo_estudiante.*' => 'Escribe tu código de estudiante (hasta 40 caracteres).',
            'semestre.*' => 'Elige un semestre del 1 al 10.',
            'whatsapp.*' => 'Escribe un número de celular de Ecuador.',
            'imagen.*' => 'Elige un logo JPG, PNG o WebP de hasta 2 MB y 2048 píxeles por lado.',
        ];
    }

    private function normalizarWhatsapp(string $numero): string
    {
        $numero = preg_replace('/[\s().-]+/', '', $numero);
        if (! preg_match('/^(?:0|\+?593)(9[0-9]{8})$/D', $numero, $partes)) {
            throw ValidationException::withMessages(['whatsapp' => 'Escribe un celular válido de Ecuador, por ejemplo 0991234567.']);
        }

        return '593'.$partes[1];
    }

    private function guardarImagen(?UploadedFile $imagen): ?string
    {
        if (! $imagen) {
            return null;
        }
        $extension = match ($imagen->getMimeType()) {
            'image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp',
        };
        $ruta = Storage::disk('public')->putFileAs('tiendas', $imagen, Str::lower(Str::random(40)).'.'.$extension);
        abort_if($ruta === false, 503, 'No pudimos guardar el logo.');

        return $ruta;
    }

    private function datosTienda(array $datos): array
    {
        return Arr::only($datos, ['nombre', 'descripcion', 'horario', 'punto_entrega_id']);
    }

    private function categorias(Tienda $tienda, array $datos): void
    {
        // Reemplazar juntas permite intercambiar las posiciones sin violar la restricción de orden.
        $tienda->categorias()->detach();
        $tienda->categorias()->attach($datos['categoria_1_id'], ['orden' => 1]);
        if (isset($datos['categoria_2_id'])) {
            $tienda->categorias()->attach($datos['categoria_2_id'], ['orden' => 2]);
        }
    }

    private function respuesta(Request $request, ?Tienda $tienda, ?PerfilVendedor $perfil): array
    {
        return [
            'tienda' => $tienda ? (new TiendaResource($tienda))->resolve($request) + ['motivo_baja' => $tienda->motivo_baja] : null,
            'ya_es_vendedor' => $perfil !== null,
            'mostrar_whatsapp' => $perfil?->mostrar_whatsapp,
        ];
    }
}
