<?php

namespace App\Http\Controllers;

use App\Http\Requests\BuscarVitrinaRequest;
use App\Http\Resources\ProductoResource;
use App\Http\Resources\TiendaResource;
use App\Models\Categoria;
use App\Models\Producto;
use App\Models\PuntoEntrega;
use App\Models\Tienda;
use App\Support\Busqueda;
use Illuminate\Database\Eloquent\Builder;

class VitrinaController extends Controller
{
    public function categorias()
    {
        return response()->json(['data' => Categoria::where('activa', true)->orderBy('orden')->orderBy('id')->get(['id', 'nombre', 'activa', 'orden'])]);
    }

    public function puntosEntrega()
    {
        return response()->json(['data' => PuntoEntrega::where('activa', true)->orderBy('orden')->orderBy('id')->get(['id', 'nombre', 'descripcion', 'activa', 'orden'])]);
    }

    private function categoria(Builder $query, BuscarVitrinaRequest $request): void
    {
        if ($request->filled('categoria')) {
            $query->whereHas('categorias', fn (Builder $q) => $q->where('categorias.id', $request->integer('categoria')));
        }
    }

    private function textoTienda(Builder $query, string $term): void
    {
        Busqueda::contiene($query, 'tiendas.nombre', $term);
        Busqueda::contiene($query, 'tiendas.descripcion', $term, 'or');
    }

    private function textoProducto(Builder $query, string $term): void
    {
        Busqueda::contiene($query, 'productos.nombre', $term);
        Busqueda::contiene($query, 'productos.descripcion', $term, 'or');
    }

    public function tiendas(BuscarVitrinaRequest $request)
    {
        $query = Tienda::activas();
        $this->categoria($query, $request);
        $term = trim($request->string('buscar')->toString());
        if ($term !== '') {
            $query->where(function (Builder $q) use ($term) {
                $this->textoTienda($q, $term);
                $q->orWhereHas('productos', fn (Builder $p) => $p->where(fn (Builder $text) => $this->textoProducto($text, $term)));
            });
        }

        // Premium is presentation only. It never changes the stable order.
        return TiendaResource::collection($query->orderBy('id')->paginate(20, ['*'], 'pagina')->withQueryString());
    }

    public function tienda(string $slug)
    {
        return new TiendaResource(Tienda::activas()->where('slug', $slug)->with(['productos' => fn ($q) => $q->conReservas()->orderBy('id'), 'productos.fotos'])->firstOrFail());
    }

    public function productos(BuscarVitrinaRequest $request)
    {
        $query = Producto::whereHas('tienda', function (Builder $q) use ($request) {
            $q->activas();
            $this->categoria($q, $request);
        })->conReservas()->with(['fotos', 'tienda']);
        $term = trim($request->string('buscar')->toString());
        if ($term !== '') {
            $query->where(function (Builder $q) use ($term) {
                $this->textoProducto($q, $term);
                $q->orWhereHas('tienda', fn (Builder $t) => $t->where(fn (Builder $text) => $this->textoTienda($text, $term)));
            });
        }

        return ProductoResource::collection($query->orderBy('id')->paginate(20, ['*'], 'pagina')->withQueryString());
    }
}
