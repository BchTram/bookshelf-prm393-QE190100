# BookShelf implementation progress

Official source: requirements_extracted.md (complete paragraphs, including table cells in document order).
Existing Flutter project retained in bookshelf/. No requirement conflicts found; identity enforcement is an additional implementation constraint from the Markdown prompt.

| Phase | Requirements / files | Verification | Status |
|---|---|---|---|
| 0 | Read DOCX and Markdown; environment inventory | Flutter 3.47.8, Dart 3.13.7, doctor clean, Pixel_7_2 available | DONE |
| 1 | lib/{models,data,screens,widgets,utilities}, Firebase initialization, Android | FlutterFire Android config generated in user's real project | DONE |
| 2 | Home, Register, Login, auth-state routing implemented | real Android registration/login/logout and account isolation PASS | DONE |
| 3 | books model, deterministic identity, atomic rename, firestore.rules | 109/109 direct SDK tests PASS; rules compiled/deployed to production | DONE |
| 4 | List, Add Book, all filters, search, summary implemented | sorting/filter/summary/validation widget tests pass | DONE (code/tests) |
| 5 | Detail, Edit, Cancel, favorite, confirmed Delete implemented | real Android edit/favorite/delete workflow PASS | DONE |
| 6 | format/analyze/test/emulator/Android APK, screenshots checklist | 11 Flutter tests, analyzer, Android UI, process restart and fresh ZIP release build PASS | DONE |
| 7 | submission guide, screenshot checklist, guarded ZIP packaging script | public repository and APK published; 20 app screenshots in DOCX; 3 Console screenshots and Word render missing | DOING |

Firebase project: bookshelf-prm393-7135b. FlutterFire CLI 1.4.1 installed; authorized CLI login verified; Android app registered and both client config files generated. Rules and indexes deployed successfully. Real grader account authenticated and six books seeded through client APIs, including a Vietnamese title/author. Private generated password is in .private/grader_account.json, excluded from Git/source ZIP. Student identity supplied: QE190100 — Pham Ngo Bich Tram. Public repository and APK: https://github.com/BchTram/bookshelf-prm393-QE190100/releases/tag/v1.0 (verified public, unauthenticated APK HTTP 200).

Implementation notes: preserve title/author whitespace and original display text; Unicode simple folding for uniqueness; escape percent, backslash, slash and separator before joining components. Canonical guard + literal Unicode RE2 matching enforces identity in Rules, with tested compatibility for nine Cyrillic variants. UID remains case-sensitive. Only top-level books holds book data. Transactions reject existing destinations and rename atomically, retaining timestamp/latest favorite. Optional rating and notes may be omitted by direct writes; app writes null/empty string.

27 Oct 2026 verification: formatting, dart fix, analyzer clean; flutter test 11 PASS; Rules 109 PASS, 0 FAIL. Initial Unicode/RE2 issues were fixed and the full suite rerun. Android NDK 28.2.13676358 installed using new Android CLI syntax ndk/28.2.13676358. Build exposed Kotlin cache cross-drive paths (C: Pub cache / D: project); incremental compilation disabled and memory limited for this 8 GB machine. Build/runtime verification remains in progress.

Computer Use stopped automatically because it could not determine Chrome's current URL with sufficient confidence. No further browser input issued. Firebase Console screenshots must be captured by the user unless a future browser session becomes available. No fake screenshots or public links were created.

Latest verification: production Android capture suite All tests passed. Real Logout, second-account isolation, sign-in data restoration, and deleted-book absence verified. GitHub Release digest matches local APK. Fresh ZIP release build PASS (140.0s, 49.9MB); process restart auth/books/favorite restore PASS.
