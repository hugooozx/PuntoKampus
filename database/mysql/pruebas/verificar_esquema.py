"""Verifica el DDL con MySQL real, sin tocar servidores ni bases existentes.

Solo usa la biblioteca estandar de Python. Crea una instancia aislada,
contrasena aleatoria y puerto local libre; la apaga incluso ante un fallo.
"""

import argparse
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bin', required=True, type=Path, help='Directorio bin de MySQL 8.4')
    parser.add_argument('--trabajo', required=True, type=Path, help='Directorio local ignorado por Git')
    args = parser.parse_args()
    binaries = args.bin.resolve()
    args.trabajo.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix='verificacion-', dir=args.trabajo.resolve()))
    data_dir = run_dir / 'datos'
    extension = '.exe' if os.name == 'nt' else ''
    server_bin = str(binaries / ('mysqld' + extension))
    client_bin = str(binaries / ('mysql' + extension))
    admin_bin = str(binaries / ('mysqladmin' + extension))
    flags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    ddl = (Path(__file__).resolve().parents[1] / 'puntokampus.sql').read_text(encoding='utf-8-sig')
    results = []
    server = None
    credentials = run_dir / 'cliente.cnf'
    client_options = []
    port = None

    def execute(sql, expected_error=None, database=None):
        command = [client_bin, *client_options, '--no-login-paths', '--protocol=TCP',
                   '--host=127.0.0.1', f'--port={port}', '--user=root',
                   '--connect-timeout=2', '--batch', '--raw', '--skip-column-names',
                   '--default-character-set=utf8mb4']
        if database:
            command.append('--database=' + database)
        result = subprocess.run(command, input=sql.encode('utf-8'), capture_output=True,
                                timeout=60, creationflags=flags)
        output = result.stdout.decode('utf-8', errors='replace').strip()
        error = result.stderr.decode('utf-8', errors='replace').strip()
        if expected_error:
            assert result.returncode != 0 and f'ERROR {expected_error} ' in error, (output, error)
        else:
            assert result.returncode == 0, error
        return output

    def test(name, action):
        action()
        results.append(name)
        print('OK:', name, flush=True)

    def equal(query, value):
        result = execute(query, database='puntokampus_pruebas')
        assert result == value, (query, result, value)

    def reject(name, sql, code=3819):
        test(name, lambda: execute(sql, expected_error=code, database='puntokampus_pruebas'))

    try:
        initialized = subprocess.run(
            [server_bin, '--no-defaults', '--initialize-insecure',
             '--basedir=' + str(binaries.parent), '--datadir=' + str(data_dir)],
            capture_output=True, timeout=180, creationflags=flags)
        assert initialized.returncode == 0, initialized.stderr.decode(errors='replace')
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        server = subprocess.Popen(
            [server_bin, '--no-defaults', '--basedir=' + str(binaries.parent),
             '--datadir=' + str(data_dir), '--bind-address=127.0.0.1',
             f'--port={port}', '--mysqlx=OFF', '--skip-log-bin',
             '--log-error=' + str(run_dir / 'servidor.log'),
             '--default-time-zone=+00:00', '--innodb-buffer-pool-size=64M'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=flags)
        client_options = ['--no-defaults']
        for _ in range(90):
            if server.poll() is not None:
                raise RuntimeError((run_dir / 'servidor.log').read_text(errors='replace'))
            try:
                execute('SELECT 1;')
                break
            except (AssertionError, subprocess.TimeoutExpired):
                time.sleep(0.5)
        else:
            raise RuntimeError('MySQL no inicio dentro del plazo.')
        # Esta cuenta pertenece exclusivamente a la instancia recien inicializada.
        password = secrets.token_hex(32)
        execute("ALTER USER 'root'@'localhost' IDENTIFIED BY '" + password + "';")
        credentials.write_text('[client]\npassword=' + password + '\n', encoding='ascii')
        client_options = ['--defaults-file=' + str(credentials)]
        version = execute('SELECT VERSION();')
        print('Motor:', version, flush=True)

        test('Bloque completo en base nueva', lambda: execute(ddl))
        test('Segundo bloque completo sin errores', lambda: execute(ddl))
        table_names = execute("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='puntokampus' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;").splitlines()
        assert len(table_names) == 19, table_names
        for name in table_names:
            assert execute(f'SELECT COUNT(*) FROM puntokampus.`{name}`;') == '0', name
        results.append('Las 19 tablas de entrega estan completamente vacias')
        print('OK: 19 tablas vacias', flush=True)

        fixture_ddl = ddl.replace('puntokampus', 'puntokampus_pruebas')
        execute(fixture_ddl)
        execute("""
INSERT INTO facultades(id,nombre) VALUES (1,'Facultad de prueba');
INSERT INTO carreras(id,facultad_id,nombre) VALUES (1,1,'Carrera de prueba');
INSERT INTO periodos_academicos(id,nombre,fecha_inicio,fecha_fin) VALUES
 (1,'Vigente',CURRENT_DATE - INTERVAL 30 DAY,CURRENT_DATE + INTERVAL 30 DAY),
 (2,'Anterior',CURRENT_DATE - INTERVAL 90 DAY,CURRENT_DATE - INTERVAL 30 DAY);
INSERT INTO usuarios(id,correo,nombres,acepto_privacidad_en,es_admin) VALUES
 (1,'comprador@utb.edu.ec','Comprador',UTC_TIMESTAMP(6),0),
 (2,'vendedor@fafi.utb.edu.ec','Vendedor',UTC_TIMESTAMP(6),0),
 (3,'administrador@utb.edu.ec','Administrador',UTC_TIMESTAMP(6),1),
 (4,'vendedor2@utb.edu.ec','Otro vendedor',UTC_TIMESTAMP(6),0);
INSERT INTO perfiles_vendedores(usuario_id,carrera_id,codigo_estudiante,semestre,whatsapp) VALUES
 (2,1,'A-2',4,'593991234567'), (4,1,'A-4',5,'593991234568');
INSERT INTO categorias(id,nombre) VALUES (1,'Comida'),(2,'Bebidas'),(3,'Servicios');
INSERT INTO puntos_entrega(id,nombre) VALUES (1,'Punto de prueba');
INSERT INTO tiendas(id,usuario_id,nombre,slug,punto_entrega_id) VALUES
 (1,2,'Tienda uno','tienda-uno',1),(2,4,'Tienda dos','tienda-dos',1);
INSERT INTO tiendas_categorias(tienda_id,categoria_id,orden) VALUES (1,1,1),(1,2,2),(2,1,1);
INSERT INTO productos(id,tienda_id,nombre,precio) VALUES
 (1,1,'Empanada',1.50),(2,1,'Jugo natural',1.00),(3,2,'Cuaderno',3.00);
INSERT INTO fotos_productos(producto_id,url,orden) VALUES (1,'prueba/1.jpg',1),(1,'prueba/2.jpg',2),(1,'prueba/3.jpg',3);
INSERT INTO pedidos(id,codigo,comprador_id,tienda_id,punto_entrega_id,hora_entrega,forma_pago,creado_en,estado_cambiado_en) VALUES
 (1,'PK-000001',1,1,1,'2026-11-14 14:00:00','efectivo','2026-11-14 12:00:00','2026-11-14 12:00:00');
INSERT INTO detalles_pedidos(pedido_id,producto_id,nombre_producto,precio_unitario,cantidad) VALUES
 (1,1,'Empanada',1.50,2),(1,2,'Jugo natural',1.00,1);
INSERT INTO cuentas_bancarias(id,banco,tipo_cuenta,numero,titular) VALUES (1,'Banco de prueba','ahorros','001','Plataforma');
INSERT INTO configuraciones(precio_premium,cuenta_bancaria_id,periodo_actual_id,dias_conservacion_comprobantes) VALUES (5.00,1,1,30);
INSERT INTO solicitudes_premium(id,tienda_id,numero_comprobante,monto,foto_comprobante) VALUES (1,1,'PRUEBA-001',5.00,'privado/1.jpg');
""", database='puntokampus_pruebas')

        test('Reejecucion con datos conserva los registros', lambda: execute(fixture_ddl))
        test('Reejecucion conserva los importes', lambda: equal('SELECT total FROM vistas_totales_pedidos WHERE pedido_id=1;', '4.00'))
        reject('Correo ajeno a UTB', "INSERT INTO usuarios(correo) VALUES ('alumno@gmail.com');")
        reject('Dominio suplantado', "INSERT INTO usuarios(correo) VALUES ('alumno@falso-utb.edu.ec');")
        reject('Correo en mayusculas sin normalizar', "INSERT INTO usuarios(correo) VALUES ('ALUMNO@utb.edu.ec');")
        reject('Correo repetido', "INSERT INTO usuarios(correo) VALUES ('comprador@utb.edu.ec');", 1062)
        reject('Alta incompleta no puede mezclar nombre sin consentimiento', "INSERT INTO usuarios(correo,nombres) VALUES ('nuevo@utb.edu.ec','Nuevo');")
        reject('Carrera huerfana', "INSERT INTO carreras(facultad_id,nombre) VALUES (999,'Inexistente');", 1452)
        reject('Semestre fuera de rango', 'UPDATE perfiles_vendedores SET semestre=11 WHERE usuario_id=2;')
        reject('Telefono local sin normalizar', "UPDATE perfiles_vendedores SET whatsapp='0991234567' WHERE usuario_id=2;")
        reject('Una tienda por cuenta', "INSERT INTO tiendas(usuario_id,nombre,slug,punto_entrega_id) VALUES(2,'Otra tienda','otra-tienda',1);", 1062)
        reject('Tienda requiere perfil vendedor', "INSERT INTO tiendas(usuario_id,nombre,slug,punto_entrega_id) VALUES(1,'Otra tienda','otra-tienda',1);", 1452)
        reject('Baja requiere motivo y fecha', "UPDATE tiendas SET estado='dada_de_baja' WHERE id=1;")
        reject('Categoria no repetible', 'INSERT INTO tiendas_categorias VALUES(1,1,2);', 1062)
        reject('Maximo dos categorias', 'INSERT INTO tiendas_categorias VALUES(1,3,3);')
        reject('Precio mayor que cero', 'UPDATE productos SET precio=0 WHERE id=1;')
        reject('Precio maximo de 500', 'UPDATE productos SET precio=500.01 WHERE id=1;')
        reject('Maximo tres fotos', "INSERT INTO fotos_productos(producto_id,url,orden) VALUES(1,'prueba/4.jpg',4);")
        reject('Posicion de foto no repetida', "INSERT INTO fotos_productos(producto_id,url,orden) VALUES(1,'prueba/otra.jpg',1);", 1062)
        reject('Cantidad maxima de 20', 'UPDATE detalles_pedidos SET cantidad=21 WHERE id=1;')
        reject('Cantidad positiva', 'UPDATE detalles_pedidos SET cantidad=0 WHERE id=1;')
        reject('Entrega demasiado pronto', "UPDATE pedidos SET hora_entrega='2026-11-14 12:29:59' WHERE id=1;")
        reject('Entrega posterior a siete dias', "UPDATE pedidos SET hora_entrega='2026-11-21 12:00:01' WHERE id=1;")
        reject('Cancelacion requiere actor', "UPDATE pedidos SET estado='cancelado' WHERE id=1;")
        reject('Reporte otro requiere detalle', "INSERT INTO reportes(tienda_id,reportado_por,motivo) VALUES(1,1,'otro');")
        reject('Reporte cerrado requiere nota', "INSERT INTO reportes(tienda_id,reportado_por,motivo,estado,revisado_en) VALUES(1,1,'no_entrego','sin_accion',UTC_TIMESTAMP(6));")
        reject('Configuracion admite solo una fila', 'INSERT INTO configuraciones(id,precio_premium,cuenta_bancaria_id,periodo_actual_id,dias_conservacion_comprobantes) VALUES(2,5,1,1,30);')
        reject('Sin limite de pedidos en tramo 1', 'UPDATE configuraciones SET limite_pedidos_gratis=10;')
        reject('Una solicitud Premium pendiente', "INSERT INTO solicitudes_premium(tienda_id,numero_comprobante,monto,foto_comprobante) VALUES(1,'PRUEBA-002',5,'privado/2.jpg');", 1062)
        reject('Rechazo requiere motivo', "UPDATE solicitudes_premium SET estado='rechazada',revisado_en=UTC_TIMESTAMP(6),revisado_por=3 WHERE id=1;")
        reject('Aprobacion requiere periodo', "UPDATE solicitudes_premium SET estado='aprobada',revisado_en=UTC_TIMESTAMP(6),revisado_por=3 WHERE id=1;")
        execute("UPDATE solicitudes_premium SET estado='aprobada',revisado_en=UTC_TIMESTAMP(6),revisado_por=3,periodo_academico_id=1 WHERE id=1;", database='puntokampus_pruebas')
        test('Plan Premium calculado desde aprobacion', lambda: equal('SELECT plan FROM vistas_planes_tiendas WHERE tienda_id=1;', 'premium'))
        execute("INSERT INTO solicitudes_premium(id,tienda_id,numero_comprobante,monto,foto_comprobante) VALUES(2,2,'prueba-001',5,'privado/2.jpg');", database='puntokampus_pruebas')
        reject('Comprobante aprobado no reutilizable incluso con distinta caja', "UPDATE solicitudes_premium SET estado='aprobada',periodo_academico_id=1,revisado_en=UTC_TIMESTAMP(6),revisado_por=3 WHERE id=2;", 1062)
        execute("UPDATE solicitudes_premium SET numero_comprobante='PRUEBA-002',estado='aprobada',periodo_academico_id=2,revisado_en=UTC_TIMESTAMP(6),revisado_por=3 WHERE id=2;", database='puntokampus_pruebas')
        test('Periodo vencido produce plan gratis', lambda: equal('SELECT plan FROM vistas_planes_tiendas WHERE tienda_id=2;', 'gratis'))
        execute("UPDATE productos SET precio=7.00,nombre='Nombre nuevo',eliminado_en=UTC_TIMESTAMP(6) WHERE id=1;", database='puntokampus_pruebas')
        test('Precio historico independiente del catalogo', lambda: equal('SELECT total FROM vistas_totales_pedidos WHERE pedido_id=1;', '4.00'))
        test('Nombre historico independiente del catalogo', lambda: equal('SELECT nombre_producto FROM detalles_pedidos WHERE id=1;', 'Empanada'))
        execute("INSERT INTO codigos_acceso(correo,codigo_hash,creado_en,expira_en) VALUES('nuevo@utb.edu.ec',REPEAT('x',60),'2026-11-14 12:00:00','2026-11-14 12:10:00');", database='puntokampus_pruebas')
        reject('Codigo no admite sexto intento', 'UPDATE codigos_acceso SET intentos=6;')
        reject('Codigo no guardado en claro', "UPDATE codigos_acceso SET codigo_hash='123456';")
        reject('Codigo vence en diez minutos', "UPDATE codigos_acceso SET expira_en='2026-11-14 12:11:00';")
        reject('Codigo agotado no puede usarse', "UPDATE codigos_acceso SET intentos=5,usado_en='2026-11-14 12:05:00';")
        execute("INSERT INTO sesiones_acceso(usuario_id,nombre_dispositivo,token_hash,expira_en) VALUES(1,'Dispositivo',REPEAT('a',64),UTC_TIMESTAMP(6) + INTERVAL 1 DAY);", database='puntokampus_pruebas')
        reject('Token de sesion solo hash hexadecimal', "UPDATE sesiones_acceso SET token_hash='token-en-claro';")
        execute('DELETE FROM usuarios WHERE id=1;', database='puntokampus_pruebas')
        test('Borrado de comprador conserva pedido anonimizado', lambda: equal('SELECT comprador_id IS NULL FROM pedidos WHERE id=1;', '1'))
        test('Borrado de comprador revoca sesiones', lambda: equal('SELECT COUNT(*) FROM sesiones_acceso;', '0'))
        execute('DELETE FROM usuarios WHERE id=2;', database='puntokampus_pruebas')
        test('Borrado de vendedor conserva pedido de contraparte', lambda: equal('SELECT tienda_id IS NULL FROM pedidos WHERE id=1;', '1'))
        test('Borrado de productos conserva detalles', lambda: equal('SELECT COUNT(*) FROM detalles_pedidos WHERE pedido_id=1 AND producto_id IS NULL;', '2'))
        test('Borrado de productos conserva total historico', lambda: equal('SELECT total FROM vistas_totales_pedidos WHERE pedido_id=1;', '4.00'))
        test('Registro aprobado conserva unicidad tras borrar tienda', lambda: equal('SELECT tienda_id IS NULL FROM solicitudes_premium WHERE id=1;', '1'))
        reject('Comprobante de tienda eliminada tampoco reutilizable', "UPDATE solicitudes_premium SET numero_comprobante='PRUEBA-001' WHERE id=2;", 1062)

        # La base del archivo entregable sigue vacia; las pruebas usan otra base.
        for name in table_names:
            assert execute(f'SELECT COUNT(*) FROM puntokampus.`{name}`;') == '0', name
        report = {'motor': version, 'pruebas_aprobadas': len(results), 'tablas_vacias': len(table_names),
                  'pruebas': results, 'resultado': 'correcto'}
        (args.trabajo / 'resultado.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
        print(json.dumps(report, ensure_ascii=False), flush=True)
    finally:
        if server is not None and server.poll() is None:
            subprocess.run([admin_bin, *client_options, '--no-login-paths', '--protocol=TCP',
                            '--host=127.0.0.1', f'--port={port}', '--user=root', 'shutdown'],
                           capture_output=True, timeout=30, creationflags=flags)
            try:
                server.wait(timeout=30)
            except subprocess.TimeoutExpired:
                server.terminate()
                server.wait(timeout=15)
        credentials.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
