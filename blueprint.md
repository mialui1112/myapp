# Blueprint: Ứng dụng Giải trí 18+

## Tổng quan

Đây là một ứng dụng Flutter được thiết kế để cung cấp trải nghiệm đọc truyện tranh, manga và xem phim dành cho người lớn. Ứng dụng sẽ có giao diện người dùng tối màu, kín đáo và cao cấp, với điều hướng rõ ràng giữa các phần chính: Truyện tranh, Manga và Phim.

## Thiết kế và Giao diện

*   **Chủ đề:** Tối (Dark theme) làm chủ đạo để tạo cảm giác cao cấp và riêng tư.
*   **Màu sắc:** Sử dụng bảng màu tối với các màu nhấn mạnh như đỏ đậm, tím hoặc vàng để tạo điểm nhấn.
*   **Typography:** Sử dụng phông chữ `google_fonts` để có kiểu chữ đẹp và dễ đọc.
*   **Bố cục:** Rõ ràng, trực quan với các thẻ và danh sách để duyệt nội dung.

## Cấu trúc ứng dụng

*   **Điều hướng chính:** `BottomNavigationBar` với ba tab: "Truyện Tranh", "Manga", và "Phim".
*   **Thư mục:**
    *   `lib/screens`: Chứa các màn hình chính của ứng dụng.
    *   `lib/widgets`: Chứa các widget có thể tái sử dụng.
    *   `lib/models`: Chứa các mô hình dữ liệu (ví dụ: `ComicSource`, `Movie`).
    *   `lib/theme`: Chứa các tệp cấu hình chủ đề.

---

## Lịch sử thay đổi

### Giai đoạn 1: Cài đặt và Cấu trúc cơ bản

*   **Tạo tệp `blueprint.md`:** (Đã hoàn thành)
*   **Thêm các dependency cần thiết:** `provider` để quản lý trạng thái (chuyển đổi theme) và `google_fonts` cho phông chữ.
*   **Cấu trúc thư mục:** Tạo các thư mục cần thiết (`screens`, `widgets`, `models`, `theme`).
*   **Thiết lập Theme:**
    *   Tạo một `ThemeProvider` để cho phép chuyển đổi giữa chế độ sáng và tối.
    *   Định nghĩa `darkTheme` và `lightTheme` trong một tệp riêng.
*   **Cập nhật `main.dart`:**
    *   Sử dụng `ChangeNotifierProvider` để cung cấp `ThemeProvider`.
    *   Thiết lập `MaterialApp` để sử dụng theme.
    *   Tạo `HomePage` với `BottomNavigationBar`.

### Giai đoạn 2: Xây dựng màn hình "Truyện Tranh"

*   **Tạo `comics_screen.dart`:**
    *   Hiển thị một danh sách **cuộn ngang** các "Nguồn" truyện (sử dụng dữ liệu giả lập).
    *   Mỗi nguồn sẽ là một `Card` có thể nhấp vào.
*   **Tạo màn hình chi tiết nguồn:**
    *   Khi nhấp vào một nguồn, điều hướng đến một màn hình mới.
    *   Màn hình này sẽ hiển thị danh sách các truyện tranh từ nguồn đó (dữ liệu giả lập).

### Giai đoạn 3: Xây dựng màn hình "Phim"

*   **Tạo `movies_screen.dart`:**
    *   Hiển thị một danh sách tổng hợp các bộ phim.
    *   Thêm các `FilterChip` ở đầu màn hình để lọc phim theo: "Mới nhất", "Yêu thích nhất", "Phổ biến".
    *   Mỗi bộ phim sẽ được hiển thị trong một `Card` với hình ảnh và tiêu đề.

---

## Kế hoạch hiện tại (Đã hoàn thành)

**Yêu cầu:** Thêm màn hình "Manga", chuyển danh sách "Comics" sang chiều ngang, và thêm thanh tìm kiếm.

1.  **Cập nhật màn hình "Comics":**
    *   Thay đổi `ListView` thành `ListView.builder` với `scrollDirection: Axis.horizontal`.
    *   Thêm một `TextField` để làm thanh tìm kiếm, cho phép lọc danh sách các nguồn truyện.
2.  **Tạo màn hình "Manga":**
    *   Tạo tệp mới `lib/screens/manga_screen.dart`.
    *   Triển khai bố cục tương tự màn hình "Comics" với danh sách nguồn cuộn ngang và thanh tìm kiếm.
3.  **Tích hợp màn hình "Manga":**
    *   Import `manga_screen.dart` vào `lib/main.dart`.
    *   Thêm "Manga" vào `BottomNavigationBar` và danh sách các widget/tiêu đề tương ứng.
4.  **Cập nhật `blueprint.md`:** Phản ánh các thay đổi trên trong tài liệu này.
