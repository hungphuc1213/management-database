# Quản trị cơ sở dữ liệu trên trang web tuyển dụng

## 1. Thu thập dữ liệu

### a. Nguồn dữ liệu
- **Website**: Dữ liệu được thu thập từ trang web **Career Việt**: [https://careerviet.vn/viec-lam/ha-noi-ho-chi-minh-da-nang-l4,8,511-vi.html](https://careerviet.vn/viec-lam/ha-noi-ho-chi-minh-da-nang-l4,8,511-vi.html)
- **Mô tả**: Career Việt là nền tảng trực tuyến cung cấp thông tin tuyển dụng và việc làm tại Việt Nam, kết nối nhà tuyển dụng với ứng viên hiệu quả. Website hỗ trợ tìm kiếm việc làm đa dạng theo ngành nghề, vị trí địa lý, cấp bậc và mức lương, đồng thời cập nhật cơ hội mới nhất từ nhiều doanh nghiệp.

### b. Công cụ thu thập dữ liệu
- **Thư viện sử dụng**: Selenium

### c. Quy trình thực hiện
1. **Phân tích cấu trúc HTML của trang web**
   - Kiểm tra các thành phần HTML chứa thông tin cần thu thập.
   - Sử dụng công cụ như Developer Tools của trình duyệt (Chrome DevTools) để tìm các CSS selector phù hợp.
   
2. **Tự động hóa việc duyệt trang**
   - Selenium được cấu hình để tự động mở trình duyệt, truy cập các trang công việc theo từng số trang (pagination).
   - Sau khi tải trang, Selenium chờ các thành phần dữ liệu được hiển thị (sử dụng hàm WebDriverWait) trước khi thu thập thông tin.

3. **Thu thập dữ liệu chi tiết**
   - Từng thông tin cần thiết được lấy từ các thành phần HTML tương ứng bằng cách sử dụng phương pháp `find_elements` với CSS selector hoặc XPath.
   - Thông tin chi tiết công việc (nếu có) được truy cập từ link cụ thể và thu thập thêm thông tin về ngành nghề (major).
   
4. **Tạo bảng và nhập dữ liệu lên Azure Server**
   
5. **Xử lý lỗi**
   - Trong trường hợp xảy ra lỗi, chương trình sẽ chuyển sang trang tiếp theo hoặc ghi nhận lỗi để kiểm tra sau.

---

## 2. Tiền xử lý dữ liệu
- Dữ liệu thu thập được không sạch, cần thực hiện tiền xử lý để chuẩn hóa.
- Tạo các feature mới và chia dữ liệu thành những bảng phù hợp.
- Tạo các bảng liên kết với nhau (mối quan hệ nhiều - nhiều).
- Biểu diễn các bảng và mối quan hệ giữa chúng qua Diagram để xem sự liên kết và ý nghĩa của từng bảng.

---

## 3. Tạo cơ sở dữ liệu tạm thời
- Trong trường hợp có sự cố về hệ thống hay thay đổi trong cấu trúc bảng dữ liệu, cần tạo cơ sở dữ liệu tạm thời và đặt lịch trình backup định kỳ.

---

## 4. Phân quyền cho người dùng
- Xác định quyền hạn cụ thể cho từng người trong dự án.
- Sau khi phân quyền xong, cần xóa quyền không cần thiết để thực hiện các dự án tiếp theo.

---

## 5. Trực quan hóa dữ liệu
- Sau khi xử lý dữ liệu, tiến hành trực quan hóa để tìm kiếm các insight phục vụ cho mục đích kinh doanh.
- Công cụ sử dụng: **PowerBI** và **Python**.

---
