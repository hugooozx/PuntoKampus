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
            'categoria_1_id' => $this->resource->categoriaId(1), 'categoria_2_id' => $this->resource->categoriaId(2),
            'horario' => $this->horario, 'punto_entrega_id' => $this->punto_entrega_id,
            'punto_entrega_nombre' => $this->whenLoaded('puntoEntrega', fn () => $this->puntoEntrega->nombre),
            'categorias_nombres' => $this->when($this->relationLoaded('puntoEntrega'),
                fn () => $this->categorias->where('activa', true)->pluck('nombre')->values()),
            'plan' => $this->resource->tienePremium() ? 'premium' : 'gratis',
            'premium_hasta' => $this->vigencia?->premium_hasta?->toDateString(),
            'estado' => $this->estado,
            'whatsapp' => $this->when($this->relationLoaded('perfilVendedor') && $this->perfilVendedor?->mostrar_whatsapp, fn () => $this->perfilVendedor->whatsapp),
            'productos' => ProductoResource::collection($this->whenLoaded('productos')),
        ];
    }
}
