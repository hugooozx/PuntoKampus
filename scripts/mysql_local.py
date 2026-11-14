"""MySQL portable para desarrollo: iniciar, detener o consultar estado.

No instala servicios del sistema. Guarda datos y claves solo en .local/.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / '.local' / 'mysql'
BIN = ROOT / '.tools/mysql-pruebas/mysql-8.4.13-winx64/bin'
FLAGS = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
SUFFIX = '.exe' if os.name == 'nt' else ''


def command(name, arguments, sql=None):
    return subprocess.run([str(BIN / (name + SUFFIX)), *arguments],
                          input=sql, text=True, encoding='utf-8', capture_output=True,
                          timeout=180, creationflags=FLAGS)


def env_file(path, values):
    source = path.read_text(encoding='utf-8-sig') if path.exists() else (ROOT / 'api/.env.example').read_text()
    lines = source.splitlines()
    for key, value in values.items():
        found = False
        for i, line in enumerate(lines):
            if line.startswith(key + '='):
                lines[i] = key + '=' + str(value)
                found = True
        if not found:
            lines.append(key + '=' + str(value))
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('accion', choices=['iniciar', 'detener', 'estado'])
    args = parser.parse_args()
    LOCAL.mkdir(parents=True, exist_ok=True)
    config = LOCAL / 'conexion.json'
    if not config.exists() and args.accion != 'iniciar':
        print('MySQL local aun no esta configurado.')
        return
    first = not config.exists()
    port = 3307 if first else json.loads(config.read_text())['puerto']
    opts = ['--defaults-file=' + str(LOCAL / 'administrador.cnf'), '--no-login-paths',
            '--protocol=TCP', '--host=127.0.0.1', '--port=' + str(port), '--user=root']
    if not first:
        alive = command('mysql', [*opts, '--connect-timeout=2', '--execute=SELECT 1']).returncode == 0
        if args.accion == 'detener':
            if alive:
                result = command('mysqladmin', [*opts, 'shutdown'])
                if result.returncode:
                    raise RuntimeError('No se pudo detener MySQL local.')
            print('MySQL local detenido.')
            return
        if args.accion == 'estado' or alive:
            print('MySQL local ' + ('activo' if alive else 'detenido') + ' en 127.0.0.1:' + str(port))
            return
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', port))  # No ocupar un puerto de otro servidor.
    data = LOCAL / 'datos'
    if first:
        if data.exists():
            raise RuntimeError('Existen datos sin configuracion. Revisarlos antes de continuar; no se sobrescribieron.')
        result = command('mysqld', ['--no-defaults', '--initialize-insecure',
                                    '--basedir=' + str(BIN.parent), '--datadir=' + str(data)])
        if result.returncode:
            raise RuntimeError('Fallo inicializacion: ' + result.stderr)
    process = subprocess.Popen([str(BIN / ('mysqld' + SUFFIX)), '--no-defaults',
                                '--basedir=' + str(BIN.parent), '--datadir=' + str(data),
                                '--bind-address=127.0.0.1', '--port=' + str(port), '--mysqlx=OFF',
                                '--skip-log-bin', '--default-time-zone=+00:00',
                                '--log-error=' + str(LOCAL / 'servidor.log')],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=FLAGS)
    boot = ['--no-defaults', *opts[1:]] if first else opts
    for _ in range(60):
        if process.poll() is not None:
            raise RuntimeError('MySQL no inicio. Consultar .local/mysql/servidor.log.')
        if command('mysql', [*boot, '--connect-timeout=2', '--execute=SELECT 1']).returncode == 0:
            break
        time.sleep(.5)
    else:
        process.terminate()
        raise RuntimeError('MySQL no respondio a tiempo.')
    if first:
        passwords = [secrets.token_hex(32) for _ in range(3)]
        sql = f"""
ALTER USER 'root'@'localhost' IDENTIFIED BY '{passwords[0]}';
CREATE DATABASE puntokampus CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE puntokampus_pruebas CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'puntokampus'@'localhost' IDENTIFIED BY '{passwords[1]}';
CREATE USER 'puntokampus_pruebas'@'localhost' IDENTIFIED BY '{passwords[2]}';
GRANT ALL PRIVILEGES ON puntokampus.* TO 'puntokampus'@'localhost';
GRANT ALL PRIVILEGES ON puntokampus_pruebas.* TO 'puntokampus_pruebas'@'localhost';
"""
        result = command('mysql', boot, sql)
        if result.returncode:
            process.terminate()
            raise RuntimeError('No se pudo terminar la configuracion local; revisar antes de reiniciar.')
        (LOCAL / 'administrador.cnf').write_text('[client]\npassword=' + passwords[0] + '\n', encoding='ascii')
        config.write_text(json.dumps({'puerto': port}), encoding='utf-8')
        for filename in ['.env', '.env.testing']:
            target = ROOT / 'api' / filename
            if target.exists():
                (LOCAL / (filename + '.anterior')).write_bytes(target.read_bytes())
            testing = filename == '.env.testing'
            values = {'APP_ENV': 'testing' if testing else 'local', 'DB_CONNECTION': 'mysql',
                      'DB_HOST': '127.0.0.1', 'DB_PORT': port,
                      'DB_DATABASE': 'puntokampus_pruebas' if testing else 'puntokampus',
                      'DB_USERNAME': 'puntokampus_pruebas' if testing else 'puntokampus',
                      'DB_PASSWORD': passwords[2 if testing else 1], 'DB_COLLATION': 'utf8mb4_0900_ai_ci',
                      'SESSION_DRIVER': 'file', 'QUEUE_CONNECTION': 'sync', 'CACHE_STORE': 'file'}
            old = target.read_text(encoding='utf-8-sig') if target.exists() else ''
            if not any(line.startswith('APP_KEY=base64:') for line in old.splitlines()):
                values['APP_KEY'] = 'base64:' + base64.b64encode(secrets.token_bytes(32)).decode()
            env_file(target, values)
    print('MySQL local activo en 127.0.0.1:' + str(port) + '. Credenciales guardadas fuera de Git.')


if __name__ == '__main__':
    main()
