<?php

use App\Http\Controllers\VitrinaController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('categorias', [VitrinaController::class, 'categorias']);
    Route::get('puntos-entrega', [VitrinaController::class, 'puntosEntrega']);
    Route::get('tiendas', [VitrinaController::class, 'tiendas']);
    Route::get('tiendas/{slug}', [VitrinaController::class, 'tienda']);
    Route::get('productos', [VitrinaController::class, 'productos']);
});
