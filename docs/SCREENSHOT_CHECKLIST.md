# Screenshot checklist

Chỉ dùng ảnh từ phiên chạy thật; app dùng tài khoản test của bạn. Giữ đúng thứ tự và caption sau trong báo cáo. Chụp toàn bộ nội dung cần chấm, có thể dùng nhiều ảnh khi form dài. Không dùng ảnh widget test hay mockup thay cho Android.

- [ ] Firebase console — Authentication: Users có tài khoản chấm.
- [ ] Firebase console — Firestore data: books có ít nhất 3 documents của tài khoản chấm.
- [ ] Firebase console — Security Rules: Rules đã Publish.
- [ ] Register screen — validation: submit trống.
- [ ] Register screen — success: Registration successful.
- [ ] Login screen: form trống.
- [ ] List screen — after login: email, Logout, ít nhất 3 sách.
- [ ] Add Book form — validation: các lỗi dưới field.
- [ ] Add Book form — success: Book added và sách mới trong List.
- [ ] Filters and search — genre filter.
- [ ] Filters and search — status filter.
- [ ] Filters and search — favorites-only switch.
- [ ] Filters and search — search box.
- [ ] Summary: Books, Favorites và nhiều hơn một status.
- [ ] Detail screen — view mode: title, author, genre, status, rating, notes.
- [ ] Detail screen — edit mode, validation: submit dữ liệu sai.
- [ ] Detail screen — after Save: giá trị đã đổi.
- [ ] Favorite toggle and Delete — before favorite toggle.
- [ ] Favorite toggle and Delete — after favorite toggle.
- [ ] Favorite toggle and Delete — before Delete.
- [ ] Favorite toggle and Delete — after Delete: sách biến mất.
- [ ] Empty state: No books found, dùng account mới hoặc filter không khớp.

Lưu ảnh thật vào report_screenshots/. Cần ít nhất 5 sách, ít nhất 2 statuses để tự kiểm tra kết hợp filter trước khi chụp. Khởi động lại app để kiểm tra persist, đăng nhập account khác để kiểm tra cách ly dữ liệu. Không có ảnh thật nào được tạo tự động trong giai đoạn viết code.
