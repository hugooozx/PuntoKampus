<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Categoria extends Model
{
    public $timestamps = false;

    protected $fillable = ['nombre', 'activa', 'orden'];

    protected function casts(): array
    {
        return ['activa' => 'boolean', 'orden' => 'integer'];
    }
}
