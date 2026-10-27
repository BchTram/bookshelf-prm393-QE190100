# Submission guide

Hai file trong cùng một folder: `QE190100.docx` và `QE190100.zip`. Sinh viên: QE190100 — Pham Ngo Bich Tram.

## Word report

Copy đúng bảy dòng bên dưới vào Word, điền các placeholder bằng dữ liệu thật; URL phải hiện rõ https://. Tiếp theo chèn ảnh thật theo SCREENSHOT_CHECKLIST.md và caption từng ảnh. Chỉ hoàn tất report khi đã có danh tính, link công khai, tài khoản thật và screenshots. Không đưa password vào source/GitHub; chỉ điền password account chấm trong báo cáo riêng.

```text
Student Code: QE190100
Full Name: Pham Ngo Bich Tram
GitHub Repository URL: https://github.com/BchTram/bookshelf-prm393-QE190100
APK Download Link: https://github.com/BchTram/bookshelf-prm393-QE190100/releases/download/v1.0/app-release.apk
Firebase Project ID: bookshelf-prm393-7135b
Test account email: grader.qe190100.bookshelf@example.com
Test account password: <copy from local .private/grader_account.json>
```

## Source ZIP

Trong PowerShell tại bookshelf/ chạy `./scripts/package_submission.ps1 -StudentCode YOUR_CODE` sau khi cấu hình Firebase và kiểm tra release APK. Script đặt pubspec.yaml ngay top-level, gồm pubspec.lock, lib/, android/, rules, config client, tests/docs/scripts. Không gồm cache/build/.git/node_modules hoặc private keys. Giải nén sang thư mục sạch, chạy flutter pub get và flutter build apk --release; thử cài APK.

## GitHub và APK public

Repository public và Release v1.0 đã được tạo và xác minh bằng GitHub API. APK trên GitHub có SHA-256 `94cecc56e500ad0b82def22538c8b035d2af469530c52e19b8a8d04bf0b65029`, khớp APK local (52,289,723 bytes). Không chạy lại lệnh tạo repository đã tồn tại bên dưới; đây chỉ là tham khảo cho một repository mới.

```powershell
git init
git add .
git commit -m "Implement BookShelf PRM393"
gh repo create YOUR_REPO --public --source . --push
flutter build apk --release
gh release create v1.0 build/app/outputs/flutter-apk/app-release.apk --title "BookShelf 1.0" --notes "Android APK for PRM393"
```

Source public phải giống source ZIP. Không commit tài khoản/password chấm. Script `scripts/publish_github.ps1` tạo repository từ source ZIP đã lọc, tải APK và lưu URL trong metadata riêng.

## Trước khi nộp

- [ ] Firebase Email/Password bật, rules đã deploy, account chấm đăng nhập được.
- [ ] Ít nhất 3 sách test thật; dùng >=5 sách và >=2 statuses để test filters.
- [ ] Register duplicate email hiển thị lỗi Firebase dưới nút.
- [ ] Auth routing, logout, Android Back, restart persistence và account isolation chạy thật.
- [ ] Mọi ảnh đúng caption, không mockup; report là DOCX thật.
- [ ] Fresh ZIP build thành công; public APK cài/mở được.
- [ ] Hai file đặt đúng tên và cùng thư mục.
