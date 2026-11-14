<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Tienda extends Model
{
    public $timestamps = false;

    protected $fillable = ['usuario_id', 'nombre', 'slug', 'descripcion', 'logo_url', 'portada_url', 'categoria_1_id', 'categoria_2_id', 'horario', 'punto_entrega_id'];

    protected function casts(): array
    {
        return ['premium_hasta' => 'date', 'dada_de_baja_en' => 'datetime'];
    }

    public function scopeActivas(Builder $query): void
    {
        $query->where('estado', 'activa');
    }

    public function productos(): HasMany
    {
        return $this->hasMany(Producto::class);
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(Usuario::class);
    }

    public function categoria1(): BelongsTo
    {
        return $this->belongsTo(Categoria::class, 'categoria_1_id');
    }

    public function categoria2(): BelongsTo
    {
        return $this->belongsTo(Categoria::class, 'categoria_2_id');
    }

    public function puntoEntrega(): BelongsTo
    {
        return $this->belongsTo(PuntoEntrega::class);
    }

    public function tienePremium(): bool
    {
        return $this->plan === 'premium' && $this->premium_hasta?->endOfDay()->isFuture();
    }
}
