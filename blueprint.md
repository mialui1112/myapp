# Blueprint: Ứng dụng Manga Reader

## Tổng quan

Đây là một ứng dụng đọc truyện tranh (manga) hiện đại được xây dựng bằng Flutter và tích hợp với Firebase. Ứng dụng cho phép người dùng đăng ký, đăng nhập, tìm kiếm, đọc, lưu trữ truyện yêu thích và xem lại lịch sử đọc. Giao diện được thiết kế để mang lại trải nghiệm đọc tốt nhất, đặc biệt là trên các thiết- bị di động.

## Các tính năng chính

*   **Xác thực người dùng (Firebase Auth):** Đăng ký/đăng nhập và quản lý phiên đăng nhập.
*   **Đồng bộ hóa Yêu thích (Cloud Firestore):** Danh sách yêu thích được cập nhật theo thời gian thực với chi phí tối ưu.
*   **Đồng bộ hóa Lịch sử đọc (Cloud Firestore):** Lịch sử đọc được cập nhật tức thì trên các thiết bị, chỉ với một lượt ghi cho mỗi truyện.
*   **Thông báo Chương Mới (Cloud Functions & FCM):** Tự động kiểm tra và gửi thông báo đẩy (push notification) cho người dùng khi có chương mới của truyện họ yêu thích.
*   **Giao diện Người dùng Hiện đại (UI/UX):**
    *   Hiệu ứng động tinh tế trong các danh sách, tạo cảm giác mượt mà.
    *   Chế độ đọc toàn màn hình, không bị xao lãng.
*   **Màn hình chính (Home):** Thanh tìm kiếm và danh sách truyện mới.
*   **Màn hình Đọc truyện Nâng cao:** Chế độ xem ngang, điều khiển tương tác.
*   **Chủ đề Sáng/Tối & Splash Screen.**

## Cấu trúc và Công nghệ

*   **Nền tảng:** Flutter
*   **Backend:** Firebase (Authentication, Cloud Firestore, Cloud Functions, Firebase Cloud Messaging)
*   **Kiến trúc:** Sạch sẽ, dễ bảo trì, tách biệt giao diện người dùng và logic nghiệp vụ.
*   **Quản lý trạng thái:** Provider
*   **API Truyện:** Sử dụng API của bên thứ ba để lấy dữ liệu truyện.
*   **Chất lượng mã nguồn:** Tuân thủ các quy tắc nghiêm ngặt của ESLint và Dart Analyzer.

## Lịch sử Phát triển

1.  **Thiết lập Ban đầu:**
    *   Khởi tạo dự án Flutter.
    *   Cấu hình Firebase (core, auth, firestore).
    *   Thiết lập cấu trúc thư mục và các tệp cơ bản.

2.  **Tối ưu hóa Màn hình Đọc truyện (`ReaderScreen`):**
    *   Triển khai chế độ đọc toàn màn hình (immersive mode).
    *   Bằng cách chạm vào màn hình, người dùng giờ đây có thể ẩn/hiện đồng thời cả giao diện của ứng dụng (thanh `AppBar`, thanh trượt) và các thanh hệ thống (thanh trạng thái, thanh điều hướng).
    *   Sử dụng `SystemChrome` để quản lý việc hiển thị các thanh hệ thống và `AnimatedSwitcher` để tạo hiệu ứng chuyển đổi mượt mà cho các thành phần UI.
    *   Đảm bảo các thanh hệ thống được khôi phục khi người dùng thoát khỏi màn hình đọc.

**Kết quả:** Ứng dụng giờ đây mang lại cảm giác bóng bẩy, chuyên nghiệp hơn rất nhiều. Trải nghiệm đọc truyện đã được nâng lên một tầm cao mới, hoàn toàn không bị phân tâm, trong khi các danh sách chính trở nên hấp dẫn và dễ chịu hơn khi tương tác.