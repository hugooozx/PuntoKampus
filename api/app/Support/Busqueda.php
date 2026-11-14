<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;

final class Busqueda
{
    public static function contiene(Builder $query, string $column, string $term, string $boolean = 'and'): void
    {
        // Columnas elegidas por el controlador; el termino siempre es un parametro.
        // La collation utf8mb4_0900_ai_ci resuelve mayusculas y tildes.
        $wrapped = $query->getQuery()->getGrammar()->wrap($column);
        $escaped = str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $term);
        $query->whereRaw("$wrapped LIKE ? ESCAPE '!'", ['%'.$escaped.'%'], $boolean);
    }
}
