<?php

use App\Support\BorradoCuenta;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('cuentas:limpiar-archivos', function () {
    app(BorradoCuenta::class)->limpiarArchivos();
})->purpose('Reintentar el borrado de archivos de cuentas eliminadas');

Schedule::command('cuentas:limpiar-archivos')->everyFiveMinutes()->withoutOverlapping();

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');
