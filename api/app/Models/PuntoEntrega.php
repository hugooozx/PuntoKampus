<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PuntoEntrega extends Model
{
    protected $table = 'puntos_entrega';

    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['nombre', 'descripcion', 'activa', 'orden'];

    protected function casts(): array
    {
        return ['activa' => 'boolean', 'orden' => 'integer'];
    }
}
