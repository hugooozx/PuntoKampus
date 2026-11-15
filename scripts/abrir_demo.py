"""Abre en el navegador una compilación web local de PuntoKampus."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit
import webbrowser


WEB = Path(__file__).resolve().parents[1] / "app" / "build" / "web"


class DemoHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        path = urlsplit(self.path).path.rstrip("/")
        if path.startswith("/t/") or path in ("/privacidad", "/borrar-cuenta"):
            self.path = "/index.html"
        return super().send_head()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--puerto", type=int, default=8766)
    parser.add_argument("--sin-navegador", action="store_true")
    args = parser.parse_args()
    if not (WEB / "index.html").exists():
        parser.exit(1, "Primero compila la versión web de Flutter. Consulta README.md.\n")
    with ThreadingHTTPServer(("127.0.0.1", args.puerto), partial(DemoHandler, directory=WEB)) as server:
        url = f"http://127.0.0.1:{server.server_port}/"
        print(f"PuntoKampus disponible en {url}", flush=True)
        if not args.sin_navegador:
            webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
