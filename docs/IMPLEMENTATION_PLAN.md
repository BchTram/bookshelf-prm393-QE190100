# BookShelf implementation progress

Official source: requirements_extracted.md (complete paragraphs, including table cells in document order).
Existing Flutter project retained in bookshelf/. No requirement conflicts found; identity enforcement is an additional implementation constraint from the Markdown prompt.

| Phase | Requirements / files | Verification | Status |
|---|---|---|---|
| 0 | Read DOCX and Markdown; environment inventory | Flutter 3.47.8, Dart 3.13.7, doctor clean, Pixel_7_2 available | DONE |
| 1 | lib/{models,data,screens,widgets,utilities}, Firebase initialization, Android | FlutterFire Android config generated in user's real project | DONE |
| 2 | Home, Register, Login, auth-state routing implemented | auth validators and widget tests pass; live Firebase pending | DOING |
| 3 | books model, deterministic identity, atomic rename, firestore.rules | 109/109 direct SDK tests PASS; rules compiled/deployed to production | DONE |
| 4 | List, Add Book, all filters, search, summary implemented | sorting/filter/summary/validation widget tests pass | DONE (code/tests) |
| 5 | Detail, Edit, Cancel, favorite, confirmed Delete implemented | analyzer clean; Android live workflow pending | DOING |
| 6 | format/analyze/test/emulator/Android APK, screenshots checklist | 11 Flutter tests PASS, analyzer clean; Android build/runtime in progress | DOING |
| 7 | submission guide, screenshot checklist, guarded ZIP packaging script | identity, real screenshots and public URLs still needed | DOING |

Firebase project: bookshelf-prm393-7135b. FlutterFire CLI 1.4.1 installed; authorized CLI login verified; Android app registered and both client config files generated. Rules and indexes deployed successfully. Real grader account authenticated and six books seeded through client APIs, including a Vietnamese title/author. Private generated password is in .private/grader_account.json, excluded from Git/source ZIP. Student identity supplied: QE190100 — Pham Ngo Bich Tram. Public repository/APK URLs not supplied.

Implementation notes: preserve title/author whitespace and original display text; Unicode simple folding for uniqueness; escape percent, backslash, slash and separator before joining components. Canonical guard + literal Unicode RE2 matching enforces identity in Rules, with tested compatibility for nine Cyrillic variants. UID remains case-sensitive. Only top-level books holds book data. Transactions reject existing destinations and rename atomically, retaining timestamp/latest favorite. Optional rating and notes may be omitted by direct writes; app writes null/empty string.

27 Oct 2026 verification: formatting, dart fix, analyzer clean; flutter test 11 PASS; Rules 109 PASS, 0 FAIL. Initial Unicode/RE2 issues were fixed and the full suite rerun. Android NDK 28.2.13676358 installed using new Android CLI syntax ndk/28.2.13676358. Build exposed Kotlin cache cross-drive paths (C: Pub cache / D: project); incremental compilation disabled and memory limited for this 8 GB machine. Build/runtime verification remains in progress.

Computer Use stopped automatically because it could not determine Chrome's current URL with sufficient confidence. No further browser input issued. Firebase Console screenshots must be captured by the user unless a future browser session becomes available. No fake screenshots or public links were created.
