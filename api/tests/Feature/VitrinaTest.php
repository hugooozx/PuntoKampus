<?php

namespace Tests\Feature;

use App\Models\Producto;
use App\Models\Tienda;
use App\Models\Usuario;
use Database\Seeders\CatalogosInicialesSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VitrinaTest extends TestCase
{
    use RefreshDatabase;

    public function test_busqueda_por_producto_e_incluso_categoria_secundaria(): void
    {
        $this->seed(CatalogosInicialesSeeder::class);
        $tienda = $this->tienda('dulces-de-ana', 2, 1);
        Producto::create([
            'tienda_id' => $tienda->id, 'nombre' => 'Galleta de avena',
            'descripcion' => 'Con azúcar morena', 'precio' => '0.75', 'disponible' => false,
        ]);

        $this->getJson('/api/v1/tiendas?buscar=AZUCAR&categoria=1')
            ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.slug', 'dulces-de-ana');
        $this->getJson('/api/v1/productos?buscar=GALLÉTA')
            ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.disponible', false);
        $this->getJson('/api/v1/productos?buscar=%25')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_bajas_y_productos_eliminados_no_aparecen_y_premium_conserva_posicion(): void
    {
        $this->seed(CatalogosInicialesSeeder::class);
        $gratis = $this->tienda('gratis', 1);
        $premium = $this->tienda('premium', 1);
        $premium->forceFill(['plan' => 'premium', 'premium_hasta' => now()->addDay()])->save();
        $baja = $this->tienda('baja', 1);
        $baja->forceFill(['estado' => 'dada_de_baja'])->save();
        Producto::create(['tienda_id' => $baja->id, 'nombre' => 'No visible', 'precio' => '1.00']);
        Producto::create(['tienda_id' => $gratis->id, 'nombre' => 'Eliminado', 'precio' => '1.00'])->delete();

        $this->getJson('/api/v1/tiendas')->assertOk()->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.slug', 'gratis')->assertJsonPath('data.1.plan', 'premium');
        $this->getJson('/api/v1/tiendas/baja')->assertNotFound();
        $this->getJson('/api/v1/productos')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/tiendas/gratis')->assertOk()
            ->assertJsonMissingPath('data.whatsapp')->assertJsonCount(0, 'data.productos');
    }

    public function test_paginacion_estable_y_validacion(): void
    {
        $this->seed(CatalogosInicialesSeeder::class);
        for ($i = 1; $i <= 21; $i++) {
            $this->tienda("tienda-$i", 1);
        }

        $this->getJson('/api/v1/tiendas')->assertOk()->assertJsonCount(20, 'data');
        $this->getJson('/api/v1/tiendas?pagina=2')->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.slug', 'tienda-21');
        $this->getJson('/api/v1/tiendas?pagina=0')->assertUnprocessable()->assertJsonValidationErrors('pagina');
    }

    private function tienda(string $slug, int $categoria, ?int $segunda = null): Tienda
    {
        $usuario = Usuario::create([
            'correo' => "$slug@utb.edu.ec", 'nombres' => 'Vendedor de prueba',
            'acepto_privacidad_en' => now(),
        ]);

        return Tienda::create([
            'usuario_id' => $usuario->id, 'nombre' => $slug, 'slug' => $slug,
            'categoria_1_id' => $categoria, 'categoria_2_id' => $segunda, 'punto_entrega_id' => 1,
        ]);
    }
}
