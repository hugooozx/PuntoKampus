<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $unidades = $this->unidadesDisponibles();
        $esGestion = $request->is('api/v1/mi-tienda/productos*');

        return ['id' => $this->id, 'tienda_id' => $this->tienda_id, 'nombre' => $this->nombre, 'descripcion' => $this->descripcion, 'precio' => $this->precio,
            'disponible' => $this->disponible && $unidades !== 0,
            'unidades_disponibles' => $unidades,
            'disponible_manual' => $this->when($esGestion, fn () => $this->disponible),
            'existencias' => $this->when($esGestion, fn () => $this->existencias),
            'reservadas' => $this->when($esGestion, fn () => $this->reservadas()),
            'fotos' => $this->whenLoaded('fotos', fn () => $this->fotos->map(fn ($foto) => ['id' => $foto->id, 'url' => $foto->url, 'orden' => $foto->orden])),
            'tienda' => new TiendaResource($this->whenLoaded('tienda'))];
    }
}
