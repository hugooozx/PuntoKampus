<?php

use App\Http\Controllers\MiTiendaController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json(['aplicacion' => 'PuntoKampus']));
Route::get('storage/tiendas/{archivo}', [MiTiendaController::class, 'imagenPublica'])
    ->where('archivo', '[a-zA-Z0-9]{40}\.(jpg|png|webp)');
