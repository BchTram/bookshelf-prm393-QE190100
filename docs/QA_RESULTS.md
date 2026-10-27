# BookShelf verification results

Student: QE190100 — Pham Ngo Bich Tram. Firebase: bookshelf-prm393-7135b.

| Requirement | Evidence | Result |
|---|---|---|
| Flutter Android project and client-only Firebase config | FlutterFire generated Android app/config; no Admin SDK credentials | PASS |
| Firebase Email/Password | Real grader sign-up/sign-in through client Auth API | PASS |
| Top-level books and exact fields | Six production samples created through grader client permissions | PASS |
| Ownership, schema, enums, lengths, optional fields, integer rating | Direct SDK emulator suite | PASS |
| Case-insensitive identity, separator/percent/slash/backslash safety, Unicode | 109 direct-write tests, all 1481 folds covered | PASS |
| Atomic rename, timestamp/favorite preservation, duplicate rollback | Concurrent and rename emulator tests | PASS |
| Rules actually published | Firebase deploy compiled and released rules; indexes deployed | PASS |
| Exact form validation, first-submit behavior, correction clears errors | Unit/widget tests | PASS |
| Sorting, combined filters/search, summary count/order | Unit tests | PASS |
| Form failure preserves input, Cancel does not save, 320px Home/Register | Widget tests | PASS |
| Static analysis | flutter analyze: no issues found | PASS |
| Current unit/widget suite | flutter test: 11 passed, 0 failed | PASS |
| Android release build | flutter build apk --release: exit 0, 52,289,723 bytes | PASS |
| APK install/start | flutter run --release --use-application-binary=build/app/outputs/flutter-apk/app-release.apk --no-resident -d emulator-5554: exit 0 | PASS |
| Complete Android UI workflow and screenshots | Production Android capture integration test: All tests passed; captures include post-delete empty state | PASS |
| Back/logout and account isolation on Android | Real registration, login, no auth route beneath List, Logout to Home, second account empty, grader sign-in restores books and deleted book stays absent | PASS |
| Auth and favorite restore after process restart | Kept APK installed, force-stopped/restarted Android process, attached to existing VM; RESTORE_VERIFIED and All tests passed | PASS |
| Source ZIP layout/cache exclusions | Inspected ZIP integrity and mandatory root entries | PASS |
| Fresh extracted source build | Extracted ZIP: pub get and release build exit 0 (140.0s, 49.9MB); all 13 Dart app files match | PASS |
| Word report | Real DOCX draft has real URLs, private grader credentials and 20 Android captures; 3 Console captures and layout review pending | PARTIAL |
| Report visual render QA | Packaged renderer cannot find LibreOffice soffice.exe, including outside sandbox | BLOCKED |
| Firebase Console screenshots | Browser automation stopped before interaction; user capture required | BLOCKED |
| Public GitHub source and durable public APK URL | BchTram/bookshelf-prm393-QE190100 public; v1.0 APK uploaded; GitHub asset SHA-256 matches local release | PASS |

Release SHA-256: `94cecc56e500ad0b82def22538c8b035d2af469530c52e19b8a8d04bf0b65029`.

The release build uses the Flutter scaffold's debug signing key, suitable for sideloading the exam APK. Production Play Store signing is not configured. The APK contains the normal app entrypoint, without grader-password compile defines; those defines are used only for the separate local screenshot test build.

Build issues fixed: missing NDK 28.2.13676358; new Android CLI uses `ndk/28.2.13676358`; Kotlin incremental cache paths across C: and D:; excessive default JVM memory on an 8 GB machine. KGP compatibility warnings remain warnings on the installed Flutter version; no unsupported-plugin build failure was observed in the successful release build.

Do not treat the DOCX draft or placeholder public URLs as submission-ready. Credentials remain in .private/ and are excluded from source ZIP/Git. Only actual Android/Firebase Console captures may be inserted into the report.

Production UI verification uses `integration_test/submission_capture_test.dart`, the local framebuffer bridge and private compile defines. The completed full capture run passed. A separate `RESTORE_CHECK=true` APK seeds a local marker and sign-in; run it with `--keep-app-running`, force-stop/start with adb, then attach `flutter drive --use-existing-app=<forwarded VM Service URL>`. The second Android process printed `RESTORE_VERIFIED: persisted auth, books and favorite` and passed. Reinstalling or allowing the driver to remove the app is not a valid persistence test.

Published source: https://github.com/BchTram/bookshelf-prm393-QE190100

Public APK: https://github.com/BchTram/bookshelf-prm393-QE190100/releases/download/v1.0/app-release.apk (HTTP 200 without authentication; GitHub asset digest matches the release SHA-256 above).
