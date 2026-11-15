<?php

namespace Database\Seeders;

use App\Models\Categoria;
use App\Models\PuntoEntrega;
use Illuminate\Database\Seeder;

class CatalogosInicialesSeeder extends Seeder
{
    public function run(): void
    {
        foreach (['Comida', 'Postres y dulces', 'Bebidas', 'Ropa y accesorios', 'Tecnología',
            'Útiles y papelería', 'Servicios', 'Otros'] as $orden => $nombre) {
            Categoria::firstOrCreate(['nombre' => $nombre], ['orden' => $orden + 1]);
        }

        foreach (['Biblioteca', 'Entrada de FAFI', 'Entrada de FACIAG',
            'Entrada de Ciencias de la Salud', 'Entrada de FCJSE'] as $orden => $nombre) {
            PuntoEntrega::firstOrCreate(['nombre' => $nombre], ['orden' => $orden + 1]);
        }
    }
}
