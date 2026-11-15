<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;

final class Busqueda
{
    public static function contiene(Builder $query, string $column, string $term, string $boolean = 'and'): void
    {
        // Columnas elegidas por el controlador; el termino siempre es un parametro.
        // Se normalizan mayúsculas y tildes en ambos lados de la comparación.
        $wrapped = $query->getQuery()->getGrammar()->wrap($column);
        $escaped = str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $term);
        $query->whereRaw("lower(public.unaccent($wrapped COLLATE \"default\")) LIKE lower(public.unaccent(?)) ESCAPE '!'", ['%'.$escaped.'%'], $boolean);
    }
}
