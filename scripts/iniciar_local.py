"""Abre la compilacion real de Flutter y prepara su API local si es necesario."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
PHP = ROOT / '.tools/composer/php/php.exe'
FLAGS = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def api_ready():
    try:
        with urlopen('http://127.0.0.1:8000/api/v1/categorias', timeout=2) as response:
            return isinstance(json.load(response).get('data'), list)
    except (OSError, ValueError):
        return False


def main():
    if not (ROOT / 'app/build/web/index.html').exists():
        raise SystemExit('Primero compila Flutter web; consulta app/README.md.')
    subprocess.run([sys.executable, str(ROOT / 'scripts/mysql_local.py'), 'iniciar'], check=True, cwd=ROOT)
    subprocess.run([str(PHP), 'artisan', 'migrate', '--force'], check=True, cwd=ROOT / 'api', creationflags=FLAGS)
    if not api_ready():
        log_dir = ROOT / '.local/api'
        log_dir.mkdir(parents=True, exist_ok=True)
        with (log_dir / 'lanzador.log').open('ab') as log:
            process = subprocess.Popen([str(PHP), 'artisan', 'serve', '--host=127.0.0.1', '--port=8000'],
                cwd=ROOT / 'api', stdout=log, stderr=log, creationflags=FLAGS)
        for _ in range(30):
            if api_ready():
                break
            if process.poll() is not None:
                raise SystemExit('La API no inicio; consulta .local/api/lanzador.log.')
            time.sleep(.5)
        else:
            process.terminate()
            raise SystemExit('La API no respondio a tiempo.')
    subprocess.run([sys.executable, str(ROOT / 'scripts/abrir_demo.py')], cwd=ROOT, check=True)


if __name__ == '__main__':
    main()
