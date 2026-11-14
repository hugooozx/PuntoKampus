<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use LogicException;

class VigenciaTienda extends Model
{
    protected $table = 'vistas_planes_tiendas';

    protected $primaryKey = 'tienda_id';

    public $incrementing = false;

    public $timestamps = false;

    protected $guarded = ['*'];

    protected function casts(): array
    {
        return ['premium_hasta' => 'date'];
    }

    protected static function booted(): void
    {
        static::saving(fn () => throw new LogicException('La vigencia se calcula; no se edita.'));
        static::deleting(fn () => throw new LogicException('La vigencia es de solo lectura.'));
    }
}
