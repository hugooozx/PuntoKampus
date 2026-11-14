<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductoFoto extends Model
{
    protected $table = 'producto_fotos';

    public $timestamps = false;

    protected $fillable = ['producto_id', 'url', 'orden'];
}
