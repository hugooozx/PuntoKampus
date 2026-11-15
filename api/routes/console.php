<?php

use App\Support\BorradoCuenta;
use App\Support\VencimientoPedidos;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('cuentas:limpiar-archivos', function () {
    app(BorradoCuenta::class)->limpiarArchivos();
})->purpose('Reintentar el borrado de archivos de cuentas eliminadas');

Schedule::command('cuentas:limpiar-archivos')->everyFiveMinutes()->withoutOverlapping();

Artisan::command('pedidos:vencer', function () {
    $cantidad = app(VencimientoPedidos::class)->ejecutar();
    $this->info("Pedidos vencidos: $cantidad");
})->purpose('Vencer pedidos pendientes 24 horas después de la entrega programada');

Schedule::command('pedidos:vencer')->hourly()->withoutOverlapping();

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');
