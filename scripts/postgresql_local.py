"""Gestiona PostgreSQL portátil en el puerto 5433, sin instalar un servicio."""
import argparse
import json
import os
from pathlib import Path
import secrets
import subprocess

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / '.local' / 'postgresql'
BIN = ROOT / '.tools' / 'postgresql' / 'pgsql' / 'bin'
DATA = LOCAL / 'datos'
SETTINGS = LOCAL / 'conexion.json'
PORT = '5433'
HOST = '127.0.0.1'
DATABASES = ('puntokampus', 'puntokampus_pruebas')


def run(program, *args, sql=None, password=None, capture=True):
    environment = os.environ.copy()
    if password is not None:
        environment['PGPASSWORD'] = password
    output = {} if capture else {'stdout': subprocess.DEVNULL, 'stderr': subprocess.DEVNULL}
    return subprocess.run(
        [str(BIN / f'{program}.exe'), *args],
        input=sql, encoding='utf-8', capture_output=capture, env=environment,
        creationflags=subprocess.CREATE_NO_WINDOW, timeout=60, **output,
    )


def psql(config, sql):
    result = run('psql', '-Xw', '-h', HOST, '-p', PORT, '-U', 'postgres', '-d', 'postgres',
                 '-q', '-v', 'ON_ERROR_STOP=1', sql=sql, password=config['postgres'])
    if result.returncode:
        raise SystemExit('No se pudo preparar la base PostgreSQL local. Revisa .local/postgresql/servidor.log.')


def setup():
    LOCAL.mkdir(parents=True, exist_ok=True)
    if not SETTINGS.exists():
        if (DATA / 'PG_VERSION').exists():
            raise SystemExit('Falta la configuración de acceso de la instancia PostgreSQL existente.')
        SETTINGS.write_text(json.dumps({
            name: secrets.token_hex(32) for name in ('postgres', *DATABASES)
        }), encoding='utf-8')
    config = json.loads(SETTINGS.read_text(encoding='utf-8'))
    if not (DATA / 'PG_VERSION').exists():
        password_file = LOCAL / 'initdb.tmp'
        password_file.write_text(config['postgres'] + '\n', encoding='ascii')
        try:
            result = run('initdb', '-D', str(DATA), '-U', 'postgres', '--encoding=UTF8',
                         '--locale=C', '--auth=scram-sha-256', '--pwfile', str(password_file))
        finally:
            password_file.unlink(missing_ok=True)
        if result.returncode:
            raise SystemExit('No se pudo inicializar PostgreSQL. ' + result.stderr.strip())
    return config


def ready():
    return run('pg_ctl', '-D', str(DATA), 'status').returncode == 0


def start():
    config = setup()
    if not ready():
        result = run('pg_ctl', '-D', str(DATA), '-l', str(LOCAL / 'servidor.log'),
                     '-o', f'-h {HOST} -p {PORT}', '-w', '-t', '30', 'start', capture=False)
        if result.returncode:
            raise SystemExit('No se pudo iniciar PostgreSQL. Revisa .local/postgresql/servidor.log.')
    for name in DATABASES:
        password = config[name]
        psql(config, rf"""
SELECT 'CREATE ROLE {name} LOGIN PASSWORD ''{password}'''
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{name}')
\gexec
SELECT 'CREATE DATABASE {name} OWNER {name}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{name}')
\gexec
REVOKE CONNECT ON DATABASE {name} FROM PUBLIC;
""")
    print(f'PostgreSQL local activo en {HOST}:{PORT}.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('accion', choices=('iniciar', 'estado', 'detener'))
    args = parser.parse_args()
    if os.name != 'nt' or not (BIN / 'pg_ctl.exe').exists():
        raise SystemExit('Instala los binarios PostgreSQL en .tools/postgresql/pgsql o usa un servidor propio.')
    if args.accion == 'iniciar':
        start()
    elif args.accion == 'detener' and ready():
        if run('pg_ctl', '-D', str(DATA), '-m', 'fast', '-w', 'stop').returncode:
            raise SystemExit('No se pudo detener PostgreSQL local.')
        print('PostgreSQL local detenido.')
    else:
        status = 'activo' if ready() else 'detenido'
        print(f'PostgreSQL local {status} en {HOST}:{PORT}.')


if __name__ == '__main__':
    main()
