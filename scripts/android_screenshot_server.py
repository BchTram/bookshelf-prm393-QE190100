"""Local test bridge: save actual Android framebuffer PNGs for the report.
Listens only on host loopback; Android Emulator reaches it via 10.0.2.2.
No image synthesis, editing, credentials, or arbitrary commands/paths.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
import subprocess
from urllib.parse import urlparse, parse_qs

ROOT = Path(__file__).resolve().parents[1]
ADB = Path.home() / 'AppData/Local/Android/sdk/platform-tools/adb.exe'


class Capture(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        name = parse_qs(url.query).get('name', [''])[0]
        if url.path != '/capture' or not re.fullmatch(r'[0-9]{2}_[a-z_]+', name):
            self.send_error(400)
            return
        try:
            result = subprocess.run([str(ADB), '-s', 'emulator-5554', 'exec-out', 'screencap', '-p'],
                                    check=True, capture_output=True, timeout=25)
            if not result.stdout.startswith(b'\x89PNG\r\n\x1a\n'):
                raise ValueError('Android did not return a PNG')
            folder = ROOT / 'report_screenshots'
            folder.mkdir(exist_ok=True)
            (folder / f'{name}.png').write_bytes(result.stdout)
            print(f'Actual Android screenshot saved: {name}', flush=True)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'captured')
        except Exception as error:
            self.send_error(500, str(error))


if __name__ == '__main__':
    print('Android screenshot bridge listening on 127.0.0.1:8765', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8765), Capture).serve_forever()
