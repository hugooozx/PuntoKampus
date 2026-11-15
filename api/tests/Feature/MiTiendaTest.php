<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MiTiendaTest extends TestCase
{
    use DatabaseTransactions;

    public function test_registro_publicacion_edicion_y_visibilidad_en_vitrina(): void
    {
        $datos = $this->catalogos();
        $correo = 'prueba-tienda@fafi.utb.edu.ec';
        $this->postJson('/api/v1/auth/codigo', compact('correo'))->assertNoContent();
        $correoEnviado = Mail::mailer('array')->getSymfonyTransport()->messages()->last()->getOriginalMessage();
        preg_match('/\b([0-9]{6})\b/', $correoEnviado->getTextBody(), $codigo);
        $token = $this->postJson('/api/v1/auth/verificar', [
            'correo' => $correo, 'codigo' => $codigo[1], 'dispositivo' => 'Prueba tienda',
        ])->assertOk()->json('token');
        $this->withToken($token)->postJson('/api/v1/mi-tienda', $datos)->assertForbidden();
        $this->putJson('/api/v1/yo', ['nombres' => 'Vendedora de prueba', 'acepto_privacidad' => true])->assertOk();
        $this->getJson('/api/v1/mi-tienda')->assertOk()->assertJsonPath('tienda', null);
        $this->postJson('/api/v1/mi-tienda', array_replace($datos, ['categoria_2_id' => $datos['categoria_1_id']]))
            ->assertUnprocessable()->assertJsonValidationErrors('categoria_2_id');
        $this->assertDatabaseCount('perfiles_vendedores', 0);

        $creada = $this->postJson('/api/v1/mi-tienda', $datos)->assertCreated()
            ->assertJsonPath('tienda.plan', 'gratis')->assertJsonPath('mostrar_whatsapp', false);
        $slug = $creada->json('tienda.slug');
        $this->assertDatabaseHas('perfiles_vendedores', ['whatsapp' => '593991234567', 'mostrar_whatsapp' => false]);
        $this->getJson('/api/v1/tiendas?buscar=galletas')->assertOk()->assertJsonPath('data.0.slug', $slug);
        $this->getJson('/api/v1/tiendas/'.$slug)->assertOk()->assertJsonMissingPath('data.whatsapp');
        $this->postJson('/api/v1/mi-tienda', $datos)->assertConflict();

        $editada = array_replace($datos, [
            'nombre' => 'Galletas del campus', 'horario' => 'Lun–vie, 10:00–13:00',
            'categoria_1_id' => $datos['categoria_2_id'], 'categoria_2_id' => $datos['categoria_1_id'],
            'estado' => 'dada_de_baja',
        ]);
        $this->putJson('/api/v1/mi-tienda', $editada)->assertOk()
            ->assertJsonPath('tienda.slug', $slug)->assertJsonPath('tienda.estado', 'activa');
        $this->getJson('/api/v1/tiendas/'.$slug)->assertOk()
            ->assertJsonPath('data.nombre', 'Galletas del campus')
            ->assertJsonPath('data.categoria_1_id', $datos['categoria_2_id']);
        $this->putJson('/api/v1/yo', ['nombres' => 'Vendedora de prueba', 'mostrar_whatsapp' => true])->assertOk();
        $this->getJson('/api/v1/tiendas/'.$slug)->assertOk()->assertJsonPath('data.whatsapp', '593991234567');

        $this->withToken($this->sesion('otro@utb.edu.ec'))->putJson('/api/v1/mi-tienda', $editada)->assertNotFound();
        $this->getJson('/api/v1/mi-tienda')->assertOk()->assertJsonPath('tienda', null);
        $this->withToken($token)->postJson('/api/v1/mi-tienda/portada')->assertForbidden();

        DB::table('tiendas')->where('slug', $slug)->update([
            'estado' => 'dada_de_baja', 'motivo_baja' => 'Revisión de prueba', 'dada_de_baja_en' => now(),
        ]);
        $this->putJson('/api/v1/mi-tienda', $editada)->assertOk()
            ->assertJsonPath('tienda.estado', 'dada_de_baja')->assertJsonPath('tienda.motivo_baja', 'Revisión de prueba');
        $this->getJson('/api/v1/tiendas/'.$slug)->assertNotFound();
    }

    public function test_logo_se_publica_y_al_reemplazar_se_borra_el_anterior(): void
    {
        Storage::fake('public');
        $datos = $this->catalogos();
        $this->withToken($this->sesion('logo@utb.edu.ec'));
        $this->post('/api/v1/mi-tienda', $datos + ['imagen' => UploadedFile::fake()->create('texto.txt')],
            ['Accept' => 'application/json'])->assertUnprocessable()->assertJsonValidationErrors('imagen');
        $this->assertDatabaseCount('tiendas', 0);
        $logo = fn () => UploadedFile::fake()->createWithContent('logo.png', base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=',
        ));
        $creada = $this->post('/api/v1/mi-tienda', $datos + ['imagen' => $logo()], ['Accept' => 'application/json'])
            ->assertCreated();
        $url = $creada->json('tienda.logo_url');
        Storage::disk('public')->assertExists(substr($url, 9));
        $this->get($url, ['Origin' => 'http://127.0.0.1:8766'])->assertOk()
            ->assertHeader('Content-Type', 'image/png')->assertHeader('Access-Control-Allow-Origin', '*');
        $nueva = $this->post('/api/v1/mi-tienda/logo', ['imagen' => $logo()], ['Accept' => 'application/json'])
            ->assertOk()->json('logo_url');
        $this->assertNotEquals($url, $nueva);
        Storage::disk('public')->assertMissing(substr($url, 9));
        $this->get($url)->assertNotFound();
        $this->get($nueva)->assertOk();
    }

    private function sesion(string $correo): string
    {
        $usuario = Usuario::create(['correo' => $correo, 'nombres' => 'Prueba', 'acepto_privacidad_en' => now()]);
        $token = bin2hex(random_bytes(32));
        DB::table('sesiones_acceso')->insert([
            'usuario_id' => $usuario->id, 'nombre_dispositivo' => 'Pruebas',
            'token_hash' => hash('sha256', $token), 'expira_en' => now()->addHour(),
        ]);

        return $token;
    }

    private function catalogos(): array
    {
        $facultad = DB::table('facultades')->insertGetId(['nombre' => 'Facultad de prueba']);
        $carrera = DB::table('carreras')->insertGetId(['facultad_id' => $facultad, 'nombre' => 'Carrera de prueba']);
        $primera = DB::table('categorias')->insertGetId(['nombre' => 'Dulces']);
        $segunda = DB::table('categorias')->insertGetId(['nombre' => 'Comida']);
        $punto = DB::table('puntos_entrega')->insertGetId(['nombre' => 'Biblioteca']);

        return [
            'nombre' => 'Galletas UTB', 'descripcion' => 'Galletas caseras', 'horario' => '10:00–15:00',
            'categoria_1_id' => $primera, 'categoria_2_id' => $segunda, 'punto_entrega_id' => $punto,
            'codigo_estudiante' => 'PRUEBA01', 'carrera_id' => $carrera, 'semestre' => 5, 'whatsapp' => '0991234567',
        ];
    }
}
