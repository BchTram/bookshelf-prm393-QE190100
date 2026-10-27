# Firestore Security Rules verification

Date: 27 October 2026. Project tested locally: demo-bookshelf. Firebase CLI 15.34.1; Firestore Emulator 1.22.0; Java 25.0.2; Node 24.21.0; Firebase JS SDK 13.1.0. Actual result: **109 tests PASS, 0 FAIL** (9.44 seconds). See rules-verified-run.log for the complete captured run.

Command (PowerShell from project root):

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
# Optional local cache after python scripts/download_emulator.py:
$env:FIREBASE_EMULATORS_PATH = "$PWD/.firebase"
dart run scripts/identity_vectors.dart
npm run test:rules
```

| Test group | Actual result |
|---|---|
| Anonymous get/create/update/delete | PASS: denied |
| Own CRUD; query constrained to own userId | PASS |
| Unscoped query; A reading/updating/deleting B; spoofed ownership | PASS: denied |
| Required schema; unknown fields; wrong types | PASS: denied |
| Blank/too-long title and author; invalid genre/status | PASS: denied |
| Rating negative, >5, decimal, string, bool | PASS: denied |
| Notes >300 or wrong type; invalid favorite/timestamp | PASS: denied |
| Optional notes/rating absent; exact length boundaries; rating 0/5 | PASS: accepted |
| Random/noncanonical document IDs; alternate case identity | PASS: denied |
| Same book for two different users, including UID case distinction | PASS: accepted |
| Two concurrent create transactions | PASS: exactly one creates a row |
| Immutable id/userId/createdAt; invalid updates | PASS: denied |
| Atomic rename, preserved favorite/time, duplicate target rollback | PASS |
| Percent, slash, separator, backslash, regex operators and quote terminators | PASS |
| Dart-generated IDs for Vietnamese, Greek, Turkish, sharp-s, Deseret, emoji and whitespace | PASS |
| All 1481 single-codepoint Unicode 16 folds, grouped into 50 direct-write tests | PASS |

## Unicode issue found and fixed

The first run passed 43/58 tests; Rules lower() converted ASCII only and rejected valid Unicode client identities. A second approach uses Unicode simple case folding in Dart, a generated canonical-character guard in Rules, and RE2 Unicode case-insensitive literal matching. Escaping backslash prevents injection of a regex quote terminator. UID is kept case-sensitive.

Extended testing exposed an emulator RE2/JDK loop for 9 Cyrillic variants U+1C80..U+1C88. scripts/ProbeUnicode.java confirmed the exact incompatible mappings. Rules normalize these variants before compiling the quoted regex. The final full suite passed all 109 tests. The generator and compatibility table are committed to keep behavior reproducible.

Identity does not normalize whitespace, accents, composed/decomposed Unicode, or expand multi-character folds such as sharp-s into ss. These are distinct titles, rather than alternative letter cases under Unicode simple folding. Set/update of an existing canonical document is one row; app transactions explicitly reject duplicate Add and duplicate rename targets.

## Production

Rules compiled and were successfully released to cloud.firestore for bookshelf-prm393-7135b with Firebase CLI; indexes deployed successfully. This is an actual deployment, not only a local rules file. The grader account and sample-data client writes are validated separately; screenshots and Android runtime checks are recorded in the implementation plan. Local emulator results alone do not assert every production UI workflow has been tested.
