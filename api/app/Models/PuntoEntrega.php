<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PuntoEntrega extends Model
{
    protected $table = 'puntos_entrega';

    public $timestamps = false;

    protected $fillable = ['nombre', 'descripcion', 'activa', 'orden'];

    protected function casts(): array
    {
        return ['activa' => 'boolean', 'orden' => 'integer'];
    }
}
