<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Tienda extends Model
{
    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['usuario_id', 'nombre', 'slug', 'descripcion', 'logo_url', 'portada_url', 'horario', 'punto_entrega_id'];

    protected $with = ['categorias', 'vigencia', 'perfilVendedor'];

    protected function casts(): array
    {
        return ['dada_de_baja_en' => 'datetime'];
    }

    public function scopeActivas(Builder $query): void
    {
        $query->where('tiendas.estado', 'activa');
    }

    public function productos(): HasMany
    {
        return $this->hasMany(Producto::class);
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(Usuario::class);
    }

    public function perfilVendedor(): BelongsTo
    {
        return $this->belongsTo(PerfilVendedor::class, 'usuario_id', 'usuario_id');
    }

    public function categorias(): BelongsToMany
    {
        return $this->belongsToMany(Categoria::class, 'tiendas_categorias')->withPivot('orden')->orderByPivot('orden');
    }

    public function vigencia(): HasOne
    {
        return $this->hasOne(VigenciaTienda::class, 'tienda_id');
    }

    public function puntoEntrega(): BelongsTo
    {
        return $this->belongsTo(PuntoEntrega::class);
    }

    public function categoriaId(int $orden): ?int
    {
        return $this->categorias->first(fn ($categoria) => (int) $categoria->pivot->orden === $orden)?->id;
    }

    public function tienePremium(): bool
    {
        return $this->vigencia?->plan === 'premium';
    }
}
