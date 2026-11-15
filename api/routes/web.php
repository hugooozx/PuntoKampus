<?php

use App\Http\Controllers\AccesoAdministracionController;
use App\Http\Controllers\MisProductosController;
use App\Http\Controllers\MiTiendaController;
use App\Http\Controllers\PremiumController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json(['aplicacion' => 'PuntoKampus']));
Route::get('admin/comprobantes/{id}', [PremiumController::class, 'fotoAdmin'])->whereNumber('id')->name('admin.comprobantes');
Route::prefix('admin/acceso')->middleware('throttle:30,1')->group(function () {
    Route::post('codigo', [AccesoAdministracionController::class, 'enviar'])->name('admin.codigo');
    Route::post('verificar', [AccesoAdministracionController::class, 'verificar'])->name('admin.verificar');
});
Route::get('storage/tiendas/{archivo}', [MiTiendaController::class, 'imagenPublica'])
    ->where('archivo', '[a-zA-Z0-9]{40}\.(jpg|png|webp)');
Route::get('storage/productos/{archivo}', [MisProductosController::class, 'fotoPublica'])
    ->where('archivo', '[a-z0-9]{40}\.webp');
