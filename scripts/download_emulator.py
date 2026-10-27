"""Download the official emulator in bounded ranges; verify before executing."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib
import urllib.request
import time

URL = 'https://storage.googleapis.com/firebase-preview-drop/emulator/cloud-firestore-emulator-v1.22.0.jar'
SIZE = 136707194
SHA256 = '9b6498b7f62714d67f48f59b3818883cd682dbcd46b9f59511de81c97bb5166c'
root = Path(__file__).resolve().parents[1] / '.firebase'
root.mkdir(exist_ok=True)
chunk_size = 1024 * 1024


def download(index):
    start = index * chunk_size
    end = min(SIZE - 1, start + chunk_size - 1)
    target = root / f'emulator-part-{index:03d}'
    if target.exists() and target.stat().st_size == end - start + 1:
        return target
    for attempt in range(4):
        try:
            request = urllib.request.Request(URL, headers={'Range': f'bytes={start}-{end}'})
            with urllib.request.urlopen(request, timeout=45) as response:
                if response.status != 206 or not response.headers.get('Content-Range', '').startswith(f'bytes {start}-{end}/'):
                    raise ValueError('Server did not honor byte range')
                data = response.read()
            if len(data) != end - start + 1:
                raise ValueError('Incomplete range')
            target.write_bytes(data)
            return target
        except Exception:
            if attempt == 3:
                raise
            time.sleep(1)


if __name__ == '__main__':
    with ThreadPoolExecutor(max_workers=12) as pool:
        parts = list(pool.map(download, range((SIZE + chunk_size - 1) // chunk_size)))
    result = root / 'cloud-firestore-emulator-v1.22.0.jar'
    with result.open('wb') as output:
        for part in parts:
            output.write(part.read_bytes())
    digest = hashlib.sha256(result.read_bytes()).hexdigest()
    if digest != SHA256:
        raise ValueError(f'Emulator checksum mismatch: {digest}')
    print(f'Official emulator verified: {result} SHA256={digest}', flush=True)
