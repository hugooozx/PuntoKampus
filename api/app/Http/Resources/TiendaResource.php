<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TiendaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id, 'nombre' => $this->nombre, 'slug' => $this->slug,
            'descripcion' => $this->descripcion, 'logo_url' => $this->logo_url,
            'portada_url' => $this->resource->tienePremium() ? $this->portada_url : null,
            'categoria_1_id' => $this->categoria_1_id, 'categoria_2_id' => $this->categoria_2_id,
            'horario' => $this->horario, 'punto_entrega_id' => $this->punto_entrega_id,
            'plan' => $this->resource->tienePremium() ? 'premium' : 'gratis',
            'premium_hasta' => $this->premium_hasta?->toDateString(),
            'estado' => $this->estado,
            'whatsapp' => $this->when($this->relationLoaded('usuario') && $this->usuario?->mostrar_whatsapp, fn () => $this->usuario->whatsapp),
            'productos' => ProductoResource::collection($this->whenLoaded('productos')),
        ];
    }
}
