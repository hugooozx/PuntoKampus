<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;

/** Same Spanish accent folding on PostgreSQL and the SQLite test database. */
final class Busqueda
{
    public static function normalizar(string $value): string
    {
        return strtr(mb_strtolower($value), ['á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u', 'ü' => 'u', 'ñ' => 'n']);
    }

    public static function contiene(Builder $query, string $column, string $term, string $boolean = 'and'): void
    {
        // Column names are supplied only by the controller, never request input.
        $connection = $query->getConnection();
        if ($connection->getDriverName() === 'sqlite') {
            $connection->getPdo()->sqliteCreateFunction('pk_normalizar', self::normalizar(...), 1);
            $expression = "pk_normalizar(coalesce($column, ''))";
        } else {
            $expression = "translate(lower(coalesce($column, '')), 'áéíóúüñ', 'aeiouun')";
        }
        $escaped = str_replace(['!', '%', '_'], ['!!', '!%', '!_'], self::normalizar($term));
        $query->whereRaw("$expression LIKE ? ESCAPE '!'", ['%'.$escaped.'%'], $boolean);
    }
}
