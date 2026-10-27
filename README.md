# BookShelf PRM393

Ứng dụng Flutter Android quản lý sách riêng theo tài khoản Firebase. Yêu cầu chính thức được trích đầy đủ trong docs/requirements_extracted.md. Project hiện ở thư mục bookshelf/ vì workspace đã có Flutter project tại đây.

## Cấu trúc

- lib/models: Book, identity, sorting/filter/summary.
- lib/data: Firestore repository, transaction create/edit/rename, favorite/delete.
- lib/screens: Home, Register/Login, List và Detail.
- lib/widgets: form Add/Edit dùng chung, validation dưới từng input.
- lib/utilities: exact validation messages.
- firestore.rules: ownership, schema validation và deterministic document identity.
- test/: unit/widget tests. rules_test/: direct Firestore SDK tests.
- docs/: tiến độ, test results và checklist submission/screenshot.

## Firebase thật

Project người dùng chọn: `bookshelf-prm393-7135b`. FlutterFire đã tạo lib/firebase_options.dart và android/app/google-services.json thật; Rules đã deploy thành công. Email/Password đã được kiểm chứng bằng tài khoản chấm đăng nhập thật, với 6 sách mẫu tạo qua client API. Không cần cấu hình lại khi build fresh copy cho cùng project.

1. Firebase Console: chọn project trên → Authentication → Get started → Sign-in method → Email/Password → Enable → Save.
2. Firestore Database → Create database → chọn region → Production mode. Không dùng rules mở public.
3. Trong PowerShell tại thư mục này:

```powershell
npm ci
./node_modules/.bin/firebase.cmd login
dart pub global activate flutterfire_cli
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin;$PWD\node_modules\.bin"
flutterfire configure --project=bookshelf-prm393-7135b --platforms=android --android-package-name=com.example.bookshelf
./node_modules/.bin/firebase.cmd deploy --only firestore:rules,firestore:indexes --project bookshelf-prm393-7135b
flutter pub get
flutter run
```

FlutterFire tạo lib/firebase_options.dart và cấu hình Android client phù hợp. Đây là quy trình chính thức: https://firebase.google.com/docs/flutter/setup. Không đưa service-account/private key vào app. Test account được tạo bằng Register trong app (hoặc Console → Users), đăng nhập và thêm ít nhất 5 sách ở ít nhất 2 statuses. Không hardcode password.

## Kiểm thử

```powershell
dart format lib test
flutter analyze
flutter test
# Firebase Emulator cần Java >=21, dùng JDK Android Studio đã được doctor nhận diện:
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
npm ci
npm run test:rules
```

Rules tests dùng project `demo-bookshelf`, không đọc/ghi Firebase production và không cần Google login. SDK writes thực sự chạy dưới Security Rules; emulator seed không bypass rules. Xem kết quả thực tế trong docs/FIRESTORE_RULES_TESTS.md.

Kiểm thử Android và chụp ảnh production, dùng credentials riêng tại .private/grader_account.json (không đưa file này vào source ZIP). Terminal thứ nhất chạy cầu nối localhost để lưu ảnh framebuffer thật từ adb:

```powershell
python scripts/android_screenshot_server.py
```

Terminal thứ hai chạy test:

```powershell
$env:DEBUG = ''
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/submission_capture_test.dart -d emulator-5554 --dart-define-from-file=.private/grader_account.json
```

Test đăng ký một account mới để chụp Register/empty state, đăng nhập tài khoản chấm, tạo một sách QA rồi Edit/Favorite/Delete sách đó. Ảnh thật lưu tại report_screenshots/. Chỉ upload app-release.apk build từ lib/main.dart, không upload APK debug của bộ test. Ba ảnh Firebase Console cần chụp từ Console.

## Android và APK

```powershell
flutter emulators
flutter emulators --launch Pixel_7_2
flutter devices
flutter run -d emulator-5554
flutter build apk --release
```

APK chuẩn: `build/app/outputs/flutter-apk/app-release.apk`. Không nộp bản bootstrap thiếu Firebase config. Release build mặc định dùng debug signing từ Flutter scaffold cho bài thi; nếu phát hành lâu dài hãy cấu hình release keystore riêng, không commit private key.

## Identity và chống trùng

Document ID = escape(uid) + `|` + escape(simpleFold(title)) + `|` + escape(simpleFold(author)). Escape `%` → `%25`, backslash → `%5c`, `/` → `%2f`, `|` → `%7c` theo đúng thứ tự. UID giữ nguyên case. Unicode simple-fold table được sinh sẵn để client không phụ thuộc locale/khác biệt lowercase. Rules bắt buộc từng thành phần canonical và khớp literal qua RE2 Unicode case-insensitive matching. Có xử lý 9 Cyrillic variants gây lỗi RE2/JDK; 109 direct-write tests đã PASS, bao phủ toàn bộ 1481 folds. Không trim/normalize dấu, Unicode composed/decomposed hay expand một ký tự thành nhiều ký tự. Mọi query List giới hạn `userId`; rules không hoạt động như bộ lọc query.

Firestore set vào ID đã tồn tại là update một hàng, không tạo sách thứ hai; update hợp lệ được phép để đáp ứng Edit. App dùng transaction đọc destination trước, báo duplicate và giữ dữ liệu form khi đã tồn tại. Rename thay identity dùng transaction create destination + delete source; đụng destination thì rollback toàn bộ, giữ source.

## Nộp bài

Đọc docs/SUBMISSION_GUIDE.md và docs/SCREENSHOT_CHECKLIST.md. Sinh viên: QE190100, Pham Ngo Bich Tram. Credentials chấm chỉ lưu tại .private/grader_account.json, được loại khỏi Git/source ZIP; dùng để điền vào báo cáo riêng. Ảnh Firebase Console và kiểm tra bố cục Word cần hoàn tất trước khi nộp.

Source public: https://github.com/BchTram/bookshelf-prm393-QE190100

APK release: https://github.com/BchTram/bookshelf-prm393-QE190100/releases/download/v1.0/app-release.apk
