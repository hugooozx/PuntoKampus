<?php

namespace Tests\Feature;

use App\Models\PerfilVendedor;
use App\Models\Producto;
use App\Models\Tienda;
use App\Models\Usuario;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class VitrinaTest extends TestCase
{
    use DatabaseTransactions;

    public function test_busqueda_por_producto_e_incluso_categoria_secundaria(): void
    {
        $this->catalogos();
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
        $this->catalogos();
        $gratis = $this->tienda('gratis', 1);
        $premium = $this->tienda('premium', 1);
        $this->premium($premium);
        $baja = $this->tienda('baja', 1);
        $baja->forceFill(['estado' => 'dada_de_baja', 'motivo_baja' => 'Prueba', 'dada_de_baja_en' => now()])->save();
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
        $this->catalogos();
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

        PerfilVendedor::create(['usuario_id' => $usuario->id, 'carrera_id' => 1, 'codigo_estudiante' => $slug,
            'semestre' => 1, 'whatsapp' => '593991234567']);
        $tienda = Tienda::create([
            'usuario_id' => $usuario->id, 'nombre' => $slug, 'slug' => $slug,
            'punto_entrega_id' => 1,
        ]);
        $tienda->categorias()->attach($categoria, ['orden' => 1]);
        if ($segunda !== null) {
            $tienda->categorias()->attach($segunda, ['orden' => 2]);
        }

        return $tienda;
    }

    private function catalogos(): void
    {
        DB::table('categorias')->insert([['id' => 1, 'nombre' => 'Comida', 'orden' => 1], ['id' => 2, 'nombre' => 'Bebidas', 'orden' => 2]]);
        DB::table('puntos_entrega')->insert(['id' => 1, 'nombre' => 'Biblioteca']);
        DB::table('facultades')->insert(['id' => 1, 'nombre' => 'Facultad de pruebas']);
        DB::table('carreras')->insert(['id' => 1, 'facultad_id' => 1, 'nombre' => 'Carrera de pruebas']);
    }

    private function premium(Tienda $tienda, bool $vencido = false): void
    {
        $periodo = DB::table('periodos_academicos')->insertGetId([
            'nombre' => 'Periodo '.$tienda->id, 'fecha_inicio' => now()->subDays(60)->toDateString(),
            'fecha_fin' => ($vencido ? now()->subDays(2) : now()->addDays(30))->toDateString(),
        ]);
        DB::table('solicitudes_premium')->insert([
            'tienda_id' => $tienda->id, 'numero_comprobante' => 'PRUEBA-'.$tienda->id, 'monto' => '5.00',
            'foto_comprobante' => 'privado/prueba.jpg', 'estado' => 'aprobada', 'periodo_academico_id' => $periodo,
            'creado_en' => now()->subMinute(), 'revisado_en' => now()->subSeconds(30), 'revisado_por' => $tienda->usuario_id,
        ]);
    }

    public function test_base_vacia_y_seed_por_defecto_no_crean_datos(): void
    {
        $this->seed();
        foreach (['categorias', 'puntos-entrega', 'tiendas', 'productos'] as $ruta) {
            $this->getJson('/api/v1/'.$ruta)->assertOk()->assertJsonCount(0, 'data');
        }
        $this->getJson('/api/v1/tiendas/inexistente')->assertNotFound();
    }

    public function test_contrato_categorias_fotos_precios_y_privacidad(): void
    {
        $this->catalogos();
        $tienda = $this->tienda('mi-tienda', 2, 1);
        $producto = Producto::create(['tienda_id' => $tienda->id, 'nombre' => 'Producto', 'precio' => '1.50']);
        $producto->fotos()->create(['url' => 'https://ejemplo.test/segunda.jpg', 'orden' => 2]);
        $producto->fotos()->create(['url' => 'https://ejemplo.test/primera.jpg', 'orden' => 1]);
        $this->getJson('/api/v1/tiendas/mi-tienda')->assertOk()
            ->assertJsonPath('data.categoria_1_id', 2)->assertJsonPath('data.categoria_2_id', 1)
            ->assertJsonPath('data.productos.0.precio', '1.50')->assertJsonPath('data.productos.0.fotos.0.orden', 1)
            ->assertJsonMissingPath('data.whatsapp')->assertJsonMissingPath('data.usuario')->assertJsonMissingPath('data.perfil_vendedor');
        PerfilVendedor::where('usuario_id', $tienda->usuario_id)->update(['mostrar_whatsapp' => true]);
        $this->getJson('/api/v1/tiendas/mi-tienda')->assertOk()->assertJsonPath('data.whatsapp', '593991234567');
        $this->getJson('/api/v1/productos')->assertOk()->assertJsonPath('data.0.tienda.categoria_1_id', 2);
    }

    public function test_portada_y_vencimiento_premium(): void
    {
        $this->catalogos();
        foreach (['gratis', 'premium', 'vencido'] as $slug) {
            $tienda = $this->tienda($slug, 1);
            $tienda->update(['portada_url' => 'https://ejemplo.test/portada.jpg']);
            if ($slug !== 'gratis') {
                $this->premium($tienda, $slug === 'vencido');
            }
        }
        $this->getJson('/api/v1/tiendas')->assertOk()
            ->assertJsonPath('data.0.portada_url', null)->assertJsonPath('data.1.plan', 'premium')
            ->assertJsonPath('data.1.portada_url', 'https://ejemplo.test/portada.jpg')
            ->assertJsonPath('data.2.plan', 'gratis')->assertJsonPath('data.2.premium_hasta', null)
            ->assertJsonPath('data.2.portada_url', null);
    }

    public function test_busqueda_literal_no_interpreta_comodines_ni_sql(): void
    {
        $this->catalogos();
        $tienda = $this->tienda('ofertas', 1);
        Producto::create(['tienda_id' => $tienda->id, 'nombre' => 'Promo 10%_!', 'precio' => '2.00']);
        Producto::create(['tienda_id' => $tienda->id, 'nombre' => 'Otro producto', 'precio' => '3.00']);
        foreach (['%', '_', '!', '10%_!'] as $term) {
            $this->getJson('/api/v1/productos?'.http_build_query(['buscar' => $term]))->assertOk()->assertJsonCount(1, 'data');
        }
        $this->getJson('/api/v1/productos?'.http_build_query(['buscar' => "' OR 1=1 --"]))->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/productos?buscar=OFÉRTAS')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_catalogos_desactivados_y_categoria_sin_resultados(): void
    {
        $this->catalogos();
        DB::table('categorias')->where('id', 2)->update(['activa' => false]);
        DB::table('puntos_entrega')->where('id', 1)->update(['activa' => false]);
        $this->getJson('/api/v1/categorias')->assertOk()->assertJsonCount(1, 'data')->assertJsonMissingPath('data.0.creado_en');
        $this->getJson('/api/v1/puntos-entrega')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/productos?categoria=999')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/productos?categoria=abc')->assertUnprocessable()->assertJsonValidationErrors('categoria');
        $this->getJson('/api/v1/tiendas?buscar='.str_repeat('a', 101))->assertUnprocessable()->assertJsonValidationErrors('buscar');
    }
}
