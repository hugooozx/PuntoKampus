<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return ['id' => $this->id, 'tienda_id' => $this->tienda_id, 'nombre' => $this->nombre, 'descripcion' => $this->descripcion, 'precio' => $this->precio, 'disponible' => $this->disponible,
            'fotos' => $this->whenLoaded('fotos', fn () => $this->fotos->map(fn ($foto) => ['id' => $foto->id, 'url' => $foto->url, 'orden' => $foto->orden])),
            'tienda' => new TiendaResource($this->whenLoaded('tienda'))];
    }
}
