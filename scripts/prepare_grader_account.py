"""Create/sign in a grader through public client Auth; seed through Rules.
No Admin SDK, service account or credentials in tracked source/output logs.
"""
import json
from pathlib import Path
import secrets
import sys
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]


def request(url, data, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(url, json.dumps(data).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=45) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        body = error.read().decode()
        raise RuntimeError(f'Client request failed ({error.code}): {body}') from None


def login():
    config = json.loads((ROOT / 'android/app/google-services.json').read_text())
    key = config['client'][0]['api_key'][0]['current_key']
    project = config['project_info']['project_id']
    private = ROOT / '.private'
    private.mkdir(exist_ok=True)
    credentials_file = private / 'grader_account.json'
    if credentials_file.exists():
        credentials = json.loads(credentials_file.read_text())
        action = 'signInWithPassword'
    else:
        credentials = {'GRADER_EMAIL': 'grader.qe190100.bookshelf@example.com',
                       'GRADER_PASSWORD': secrets.token_urlsafe(24)}
        action = 'signUp'
    result = request(f'https://identitytoolkit.googleapis.com/v1/accounts:{action}?key={key}',
                     {'email': credentials['GRADER_EMAIL'], 'password': credentials['GRADER_PASSWORD'],
                      'returnSecureToken': True})
    credentials_file.write_text(json.dumps(credentials, indent=2), encoding='utf-8')
    return project, result, credentials_file


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    project, auth, path = login()
    folds = json.loads((ROOT / 'rules_test/unicode_fold.json').read_text())
    def escape(value):
        return value.replace('%', '%25').replace('\\', '%5c').replace('/', '%2f').replace('|', '%7c')
    def canonical(value):
        return escape(''.join(chr(folds.get(str(ord(c)), ord(c))) for c in value))
    samples = [
        ('Dune','Frank Herbert','Fiction','To Read',True,5,'A science fiction classic.'),
        ('Clean Code','Robert C. Martin','Academic','Reading',False,4,'Read one chapter each week.'),
        ('Atomic Habits','James Clear','Non-Fiction','Finished',True,5,'Small habits, steady progress.'),
        ('Flutter in Action','Eric Windmill','Academic','Reading',False,None,''),
        ('The Pragmatic Programmer','David Thomas and Andrew Hunt','Other','To Read',False,None,''),
        ('Đường về','Tác giả thử nghiệm','Fiction','Finished',False,3,'Unicode title and author verified.'),
    ]
    for title, author, genre, status, favorite, rating, notes in samples:
        identity = escape(auth['localId']) + '|' + canonical(title) + '|' + canonical(author)
        fields = {'id': {'stringValue': identity}, 'userId': {'stringValue': auth['localId']},
          'title': {'stringValue': title}, 'author': {'stringValue': author},
          'genre': {'stringValue': genre}, 'status': {'stringValue': status},
          'favorite': {'booleanValue': favorite}, 'notes': {'stringValue': notes},
          'rating': {'nullValue': None} if rating is None else {'integerValue': str(rating)},
          'createdAt': {'timestampValue': datetime.now(timezone.utc).isoformat()}}
        endpoint = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents/books?documentId=' + urllib.parse.quote(identity, safe='')
        try:
            request(endpoint, {'fields': fields}, auth['idToken'])
            print('Created sample:', title)
        except RuntimeError as error:
            if '(409)' not in str(error):
                raise
            print('Sample already exists:', title)
    print('Grader account authenticated; private credentials saved locally at', path)
