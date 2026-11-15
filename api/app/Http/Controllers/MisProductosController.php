<?php

namespace App\Http\Controllers;

use App\Http\Resources\ProductoResource;
use App\Models\Producto;
use App\Models\Tienda;
use App\Support\BorradoCuenta;
use App\Support\FotosProducto;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Throwable;

class MisProductosController extends Controller
{
    public function __construct(private FotosProducto $imagenes) {}

    public function indice(Request $request)
    {
        $productos = $this->productos($request)->with('fotos')->orderByDesc('id')->get();

        return ProductoResource::collection($productos);
    }

    public function crear(Request $request)
    {
        $productos = $this->productos($request);
        $datos = $request->validate($this->reglas('required'), $this->mensajes());

        return (new ProductoResource($this->guardar($productos, null, $datos)))->response()->setStatusCode(201);
    }

    public function actualizar(Request $request, int $producto)
    {
        $productos = $this->productos($request);
        $datos = $request->validate($this->reglas('sometimes') + [
            'fotos_eliminar' => ['sometimes', 'array', 'max:3'],
            'fotos_eliminar.*' => ['required', 'integer', 'distinct'],
        ], $this->mensajes());

        return new ProductoResource($this->guardar($productos, $producto, $datos));
    }

    public function borrar(Request $request, int $producto)
    {
        $productos = $this->productos($request);
        DB::transaction(function () use ($productos, $producto) {
            $entidad = $productos->lockForUpdate()->findOrFail($producto);
            foreach ($entidad->fotos()->get() as $foto) {
                $this->imagenes->encolarBorrado($foto->url);
            }
            $entidad->fotos()->delete();
            $entidad->delete();
        });
        $this->limpiarArchivos();

        return response()->noContent();
    }

    public function agregarFoto(Request $request, int $producto)
    {
        $productos = $this->productos($request);
        $datos = $request->validate(['imagen' => $this->reglasFoto()], $this->mensajes());
        $guardado = $this->guardar($productos, $producto, ['fotos' => [$datos['imagen']]]);
        $foto = $guardado->fotos->last();

        return response()->json(['data' => $foto->only('id', 'url', 'orden')], 201);
    }

    public function quitarFoto(Request $request, int $producto, int $foto)
    {
        $this->guardar($this->productos($request), $producto, ['fotos_eliminar' => [$foto]]);

        return response()->noContent();
    }

    public function fotoPublica(string $archivo)
    {
        abort_unless(Producto::whereHas('tienda', fn ($tienda) => $tienda->activas())
            ->whereHas('fotos', fn ($foto) => $foto->where('url', FotosProducto::PREFIJO.$archivo))->exists(), 404);

        $disco = Storage::disk('public');
        abort_unless($disco->exists('productos/'.$archivo), 404);

        return $disco->response('productos/'.$archivo, $archivo, [
            'Content-Type' => 'image/webp', 'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'public, max-age=300',
        ]);
    }

    private function productos(Request $request): HasMany
    {
        abort_if($request->user()->es_admin, 403, 'Las cuentas de administración no publican productos.');
        $tienda = Tienda::where('usuario_id', $request->user()->id)->first();
        abort_unless($tienda, 404, 'Crea una tienda para gestionar tus productos.');

        return $tienda->productos();
    }

    private function reglas(string $presencia): array
    {
        return [
            'nombre' => [$presencia, 'required', 'string', 'min:3', 'max:60'],
            'descripcion' => ['nullable', 'string', 'max:300'],
            'precio' => [$presencia, 'required', 'numeric', 'decimal:0,2', 'gt:0', 'max:500'],
            'disponible' => ['sometimes', 'boolean'],
            'fotos' => ['sometimes', 'array', 'max:3'],
            'fotos.*' => $this->reglasFoto(),
        ];
    }

    private function reglasFoto(): array
    {
        return ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048', 'dimensions:max_width=6000,max_height=6000'];
    }

    private function mensajes(): array
    {
        return [
            'nombre.*' => 'Escribe un nombre de 3 a 60 caracteres.',
            'descripcion.*' => 'Escribe una descripción de hasta 300 caracteres.',
            'precio.*' => 'Escribe un precio entre $0.01 y $500.00, con hasta dos decimales.',
            'fotos.max' => 'Cada producto puede tener hasta 3 fotos.',
            'fotos.*.*' => 'Elige una foto JPG, PNG o WebP de hasta 2 MB.',
            'imagen.*' => 'Elige una foto JPG, PNG o WebP de hasta 2 MB.',
        ];
    }

    private function guardar(HasMany $productos, ?int $id, array $datos): Producto
    {
        $nuevas = $datos['fotos'] ?? [];
        $eliminar = $datos['fotos_eliminar'] ?? [];
        $campos = Arr::only($datos, ['nombre', 'descripcion', 'precio', 'disponible']);
        $subidas = [];
        try {
            $producto = DB::transaction(function () use ($productos, $id, $campos, $eliminar, $nuevas, &$subidas) {
                $producto = $id === null ? $productos->create($campos) : $productos->lockForUpdate()->findOrFail($id);
                $actuales = $producto->fotos()->get();
                $quitar = $actuales->whereIn('id', $eliminar);
                abort_unless($quitar->count() === count($eliminar), 404, 'La foto ya no está en este producto.');
                $restantes = $actuales->diff($quitar)->values();
                if ($restantes->count() + count($nuevas) > 3) {
                    throw ValidationException::withMessages(['fotos' => 'Cada producto puede tener hasta 3 fotos.']);
                }
                if ($id !== null) {
                    $producto->update($campos);
                }
                foreach ($quitar as $foto) {
                    $this->imagenes->encolarBorrado($foto->url);
                    $foto->delete();
                }
                foreach ($restantes as $indice => $foto) {
                    if ($foto->orden !== $indice + 1) {
                        $foto->update(['orden' => $indice + 1]);
                    }
                }
                $orden = $restantes->count();
                foreach ($nuevas as $imagen) {
                    $url = $this->imagenes->guardar($imagen);
                    $subidas[] = $url;
                    $producto->fotos()->create(['url' => $url, 'orden' => ++$orden]);
                }

                return $producto;
            });
        } catch (Throwable $error) {
            foreach ($subidas as $url) {
                $this->imagenes->descartarCarga($url);
            }
            throw $error;
        }
        if ($eliminar !== []) {
            $this->limpiarArchivos();
        }

        return $producto->refresh()->load('fotos');
    }

    private function limpiarArchivos(): void
    {
        try {
            app(BorradoCuenta::class)->limpiarArchivos();
        } catch (Throwable $error) {
            report($error);
        }
    }
}
