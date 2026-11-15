<?php

namespace Tests\Feature;

use App\Models\PerfilVendedor;
use App\Models\Tienda;
use App\Models\Usuario;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CuentaTest extends TestCase
{
    use DatabaseTransactions;

    private function ultimoCodigo(): string
    {
        $mensaje = Mail::mailer('array')->getSymfonyTransport()->messages()->last()->getOriginalMessage();
        $this->assertMatchesRegularExpression('/\b\d{6}\b/', $mensaje->getTextBody());
        preg_match('/\b\d{6}\b/', $mensaje->getTextBody(), $codigo);
        $this->assertStringContainsString($codigo[0], $mensaje->getHtmlBody());
        $this->assertStringContainsString('Vence en 10 minutos.', $mensaje->getHtmlBody());

        return $codigo[0];
    }

    private function entrar(string $correo): string
    {
        $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertNoContent();

        return $this->postJson('/api/v1/auth/verificar', [
            'correo' => $correo, 'codigo' => $this->ultimoCodigo(), 'dispositivo' => 'Prueba',
        ])->assertOk()->json('token');
    }

    public function test_privacidad_publica_devuelve_la_fecha_configurada(): void
    {
        config(['puntokampus.privacidad_actualizada_en' => null]);
        $this->getJson('/api/v1/privacidad')->assertOk()->assertJsonPath('actualizada_en', null);

        config(['puntokampus.privacidad_actualizada_en' => '2026-11-15']);
        $this->getJson('/api/v1/privacidad')->assertOk()->assertJsonPath('actualizada_en', '2026-11-15');
    }

    public function test_alta_exige_consentimiento_guarda_cambios_y_revoca_sesion(): void
    {
        $this->postJson('/api/v1/auth/codigo', ['correo' => 'ana@utb.edu.ec.example.com'])
            ->assertUnprocessable()->assertJsonValidationErrors('correo');
        $this->assertCount(0, Mail::mailer('array')->getSymfonyTransport()->messages());
        $correo = 'Ana@FAFI.utb.edu.ec';
        $token = $this->entrar($correo);
        $this->assertDatabaseHas('sesiones_acceso', ['token_hash' => hash('sha256', $token)]);
        $this->postJson('/api/v1/auth/verificar', [
            'correo' => $correo, 'codigo' => $this->ultimoCodigo(), 'dispositivo' => 'Prueba',
        ])->assertUnprocessable();
        $this->withToken($token);
        $this->getJson('/api/v1/yo')->assertOk()->assertJsonPath('correo', strtolower($correo))
            ->assertJsonPath('acepto_privacidad_en', null)->assertJsonMissingPath('es_admin');
        $this->putJson('/api/v1/yo', ['nombres' => 'Ana'])->assertUnprocessable()->assertJsonValidationErrors('acepto_privacidad');
        $primero = $this->putJson('/api/v1/yo', ['nombres' => 'Ana', 'acepto_privacidad' => true])->assertOk();
        $this->putJson('/api/v1/yo', ['nombres' => 'Ana María', 'es_admin' => true])->assertOk()
            ->assertJsonPath('nombres', 'Ana María')->assertJsonPath('acepto_privacidad_en', $primero->json('acepto_privacidad_en'));
        $this->assertDatabaseHas('usuarios', ['correo' => strtolower($correo), 'es_admin' => false]);
        $this->postJson('/api/v1/auth/salir')->assertNoContent();
        $this->getJson('/api/v1/yo')->assertUnauthorized();
    }

    public function test_limite_de_envios_intentos_y_vencimiento(): void
    {
        $correo = 'intentos@utb.edu.ec';
        $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertNoContent();
        $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertTooManyRequests()->assertHeader('Retry-After');
        $correcto = $this->ultimoCodigo();
        $codigo = $correcto === '000000' ? '111111' : '000000';
        $dispositivo = 'Prueba';
        for ($intento = 1; $intento <= 5; $intento++) {
            $this->postJson('/api/v1/auth/verificar', compact('correo', 'codigo', 'dispositivo'))
                ->assertStatus($intento === 5 ? 429 : 422);
        }
        $this->postJson('/api/v1/auth/verificar', ['codigo' => $correcto, 'correo' => $correo, 'dispositivo' => $dispositivo])
            ->assertTooManyRequests();
        $this->travel(10)->minutes();
        $this->postJson('/api/v1/auth/verificar', ['codigo' => $correcto, 'correo' => $correo, 'dispositivo' => $dispositivo])
            ->assertUnprocessable();
        for ($envio = 2; $envio <= 5; $envio++) {
            $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertNoContent();
            $this->travel(61)->seconds();
        }
        $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertTooManyRequests();
        $this->travelBack();
    }

    public function test_borrado_de_vendedor_preserva_pedido_ajeno_y_elimina_archivos(): void
    {
        Storage::fake('public');
        Storage::fake('local');
        Storage::disk('public')->put('tiendas/logo.jpg', 'ejemplo');
        Storage::disk('local')->put('premium/archivo.jpg', 'ejemplo');
        $token = $this->entrar('vendedor@utb.edu.ec');
        $this->withToken($token)->putJson('/api/v1/yo', ['nombres' => 'Vendedor', 'acepto_privacidad' => true])->assertOk();
        $id = Usuario::where('correo', 'vendedor@utb.edu.ec')->value('id');
        $facultad = DB::table('facultades')->insertGetId(['nombre' => 'Pruebas']);
        $carrera = DB::table('carreras')->insertGetId(['nombre' => 'Pruebas', 'facultad_id' => $facultad]);
        $punto = DB::table('puntos_entrega')->insertGetId(['nombre' => 'Biblioteca']);
        PerfilVendedor::create(['usuario_id' => $id, 'carrera_id' => $carrera, 'codigo_estudiante' => 'PRUEBA',
            'semestre' => 1, 'whatsapp' => '593991234567']);
        $tienda = Tienda::create(['usuario_id' => $id, 'nombre' => 'Prueba', 'slug' => 'prueba',
            'punto_entrega_id' => $punto, 'logo_url' => '/storage/tiendas/logo.jpg']);
        $this->putJson('/api/v1/yo', ['nombres' => 'Vendedor', 'mostrar_whatsapp' => true])->assertOk()
            ->assertJsonPath('mostrar_whatsapp', true)->assertJsonPath('tienda.slug', 'prueba');
        $cliente = Usuario::create(['correo' => 'cliente@utb.edu.ec']);
        $pedido = DB::table('pedidos')->insertGetId([
            'codigo' => 'PK-123456', 'comprador_id' => $cliente->id, 'tienda_id' => $tienda->id,
            'punto_entrega_id' => $punto, 'forma_pago' => 'efectivo', 'nota' => 'Datos de prueba',
            'creado_en' => now(), 'hora_entrega' => now()->addHour(),
        ]);
        DB::table('solicitudes_premium')->insert([
            'tienda_id' => $tienda->id, 'numero_comprobante' => 'PRUEBA-BORRADO', 'monto' => '5.00',
            'foto_comprobante' => 'premium/archivo.jpg', 'estado' => 'pendiente',
        ]);
        $this->deleteJson('/api/v1/yo', ['codigo' => $this->ultimoCodigo()])->assertUnprocessable();
        $this->travel(61)->seconds();
        $this->postJson('/api/v1/yo/codigo-borrado')->assertNoContent();
        $this->deleteJson('/api/v1/yo', ['codigo' => $this->ultimoCodigo()])->assertNoContent();
        $this->getJson('/api/v1/yo')->assertUnauthorized();
        $this->assertDatabaseMissing('usuarios', ['id' => $id]);
        $this->assertDatabaseMissing('tiendas', ['id' => $tienda->id]);
        $this->assertDatabaseMissing('codigos_acceso', ['correo' => 'vendedor@utb.edu.ec']);
        $this->assertDatabaseHas('pedidos', [
            'id' => $pedido, 'tienda_id' => null, 'comprador_id' => $cliente->id,
            'nota' => null, 'estado' => 'cancelado', 'cancelado_por' => 'sistema',
        ]);
        Storage::disk('public')->assertMissing('tiendas/logo.jpg');
        Storage::disk('local')->assertMissing('premium/archivo.jpg');
        $this->travelBack();
    }

    public function test_borrado_web_funciona_con_cuenta_desactivada(): void
    {
        $correo = 'inactiva@utb.edu.ec';
        Usuario::create(compact('correo'))->forceFill(['estado' => 'desactivada'])->save();
        $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertForbidden();
        $this->postJson('/api/v1/cuentas/codigo-borrado', compact('correo'))->assertNoContent();
        $this->deleteJson('/api/v1/cuentas', ['correo' => $correo, 'codigo' => $this->ultimoCodigo()])->assertNoContent();
        $this->assertDatabaseMissing('usuarios', compact('correo'));
    }
}
