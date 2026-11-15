<?php

namespace App\Support;

use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

class VencimientoPedidos
{
    public static function limite(CarbonImmutable $ahora): CarbonImmutable
    {
        return $ahora->subHours(24);
    }

    public function ejecutar(): int
    {
        $ahora = CarbonImmutable::now('UTC');

        return DB::table('pedidos')->where('estado', 'pendiente')
            ->where('hora_entrega', '<=', self::limite($ahora)->format('Y-m-d H:i:s.u'))
            ->update(['estado' => 'vencido', 'estado_cambiado_en' => $ahora->format('Y-m-d H:i:s.u')]);
    }
}
