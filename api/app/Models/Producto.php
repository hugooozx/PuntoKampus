<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Producto extends Model
{
    use SoftDeletes;

    const DELETED_AT = 'eliminado_en';

    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['tienda_id', 'nombre', 'descripcion', 'precio', 'disponible'];

    protected function casts(): array
    {
        return ['precio' => 'decimal:2', 'disponible' => 'boolean'];
    }

    public function tienda(): BelongsTo
    {
        return $this->belongsTo(Tienda::class);
    }

    public function fotos(): HasMany
    {
        return $this->hasMany(ProductoFoto::class)->orderBy('orden')->orderBy('id');
    }
}
