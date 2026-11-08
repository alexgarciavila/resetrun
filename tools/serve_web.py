"""Serve the exported game locally and open it in the default browser."""

from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import threading
import webbrowser


class GameRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Always fetch matching HTML, scripts, WASM and data after a new export.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1] / "build" / "web"
    if not (root / "index.html").is_file():
        parser.exit(1, "No es troba el joc a build/web.\n")
    handler = partial(GameRequestHandler, directory=str(root))
    try:
        server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    except OSError as error:
        if getattr(error, "winerror", None) == 10048 or error.errno == 98:
            server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        else:
            parser.exit(1, f"No es pot iniciar el servidor: {error}\n")
    url = f"http://127.0.0.1:{server.server_port}/"
    print(f"Reset Run: {url}\nMantén aquesta finestra oberta. Ctrl+C per tancar.", flush=True)
    if not args.no_browser:
        threading.Timer(0.5, webbrowser.open, args=(url,)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
