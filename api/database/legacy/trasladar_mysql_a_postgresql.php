<?php

// Ejecutar con los dos archivos de entorno locales. Solo escribe en el destino vacío.
use Dotenv\Dotenv;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Database\Connection;
use Illuminate\Support\Facades\DB;

require __DIR__.'/../../vendor/autoload.php';
$app = require __DIR__.'/../../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

if ($argc !== 3) {
    fwrite(STDERR, "Uso: php trasladar_mysql_a_postgresql.php origen.env destino.env\n");
    exit(1);
}

function conexionDesde(string $archivo, string $driver, string $nombre): Connection
{
    $entorno = Dotenv::parse(file_get_contents($archivo));
    if (($entorno['DB_CONNECTION'] ?? null) !== $driver || ! in_array($entorno['DB_HOST'] ?? '', ['127.0.0.1', 'localhost'], true)
        || ($entorno['DB_DATABASE'] ?? null) !== 'puntokampus') {
        throw new RuntimeException('El traslado requiere dos bases locales puntokampus, una en cada motor.');
    }
    config(["database.connections.$nombre" => array_replace(config("database.connections.$driver"), [
        'url' => null, 'host' => $entorno['DB_HOST'], 'port' => $entorno['DB_PORT'],
        'database' => $entorno['DB_DATABASE'], 'username' => $entorno['DB_USERNAME'], 'password' => $entorno['DB_PASSWORD'],
    ])]);

    return DB::connection($nombre);
}

function normalizarFila(object $registro): array
{
    $fila = (array) $registro;
    foreach ($fila as $campo => &$valor) {
        if ($valor === null) {
            continue;
        }
        if (in_array($campo, ['activa', 'es_admin', 'mostrar_whatsapp', 'disponible'], true)) {
            $valor = in_array($valor, [true, 1, '1', 't', 'true'], true) ? 'true' : 'false';
        } elseif (str_ends_with($campo, '_en') || $campo === 'hora_entrega') {
            $valor = (new DateTimeImmutable($valor, new DateTimeZone('UTC')))->format('Y-m-d H:i:s.u');
        } else {
            $valor = (string) $valor;
        }
    }
    ksort($fila);

    return $fila;
}

function filas(Connection $db, string $tabla): iterable
{
    $consulta = $db->table($tabla);
    $orden = match ($tabla) {
        'perfiles_vendedores' => ['usuario_id'],
        'tiendas_categorias' => ['tienda_id', 'categoria_id'],
        default => ['id'],
    };
    foreach ($orden as $campo) {
        $consulta->orderBy($campo);
    }

    return $consulta->cursor();
}

$actual = null;
try {
    $origen = conexionDesde($argv[1], 'mysql', 'traslado_mysql');
    $destino = conexionDesde($argv[2], 'pgsql', 'traslado_postgresql');
    $baseline = json_decode(file_get_contents(database_path('baselines/mysql_v1.json')), true, flags: JSON_THROW_ON_ERROR);
    $tablas = [...array_keys($baseline['tablas']), 'borrados_archivos'];
    $origen->statement('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
    $origen->beginTransaction();
    $conteos = $destino->transaction(function () use ($origen, $destino, $tablas, &$actual) {
        foreach ($tablas as $actual) {
            $destino->statement("LOCK TABLE \"$actual\" IN EXCLUSIVE MODE");
            if ($destino->table($actual)->exists()) {
                throw new RuntimeException('El destino debe estar vacío.');
            }
        }

        $conteos = [];
        foreach ($tablas as $actual) {
            $lote = [];
            $origenHash = hash_init('sha256');
            $conteos[$actual] = 0;
            foreach (filas($origen, $actual) as $registro) {
                $fila = normalizarFila($registro);
                hash_update($origenHash, json_encode($fila, JSON_THROW_ON_ERROR)."\n");
                $lote[] = $fila;
                $conteos[$actual]++;
                if (count($lote) === 250) {
                    $destino->table($actual)->insert($lote);
                    $lote = [];
                }
            }
            if ($lote !== []) {
                $destino->table($actual)->insert($lote);
            }

            $destinoHash = hash_init('sha256');
            foreach (filas($destino, $actual) as $registro) {
                hash_update($destinoHash, json_encode(normalizarFila($registro), JSON_THROW_ON_ERROR)."\n");
            }
            if (! hash_equals(hash_final($origenHash), hash_final($destinoHash))) {
                throw new RuntimeException('Las filas no coinciden con el origen.');
            }
            if (! in_array($actual, ['perfiles_vendedores', 'tiendas_categorias'], true)) {
                $secuencia = $destino->selectOne("SELECT pg_get_serial_sequence(?, 'id') AS nombre", [$actual])->nombre;
                if ($secuencia && $conteos[$actual] > 0) {
                    $destino->selectOne('SELECT setval(CAST(? AS regclass), ?, true)', [$secuencia, $destino->table($actual)->max('id')]);
                }
            }
        }

        return $conteos;
    });
    $origen->rollBack();
    foreach (array_filter($conteos) as $tabla => $n) {
        echo "$tabla: $n filas copiadas y verificadas.\n";
    }
    echo 'Traslado verificado sobre '.count($conteos)." tablas.\n";
} catch (Throwable $error) {
    $codigo = $error instanceof PDOException ? ' SQLSTATE '.$error->getCode().'.' : '';
    fwrite(STDERR, 'No se completó el traslado'.($actual ? " en $actual" : '').'.'.$codigo."\n");
    exit(1);
}
