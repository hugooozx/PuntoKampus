<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductoFoto extends Model
{
    protected $table = 'fotos_productos';

    public $timestamps = false;

    protected $fillable = ['producto_id', 'url', 'orden'];
}
