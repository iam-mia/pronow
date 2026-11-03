# TÀI LIỆU YÊU CẦU SẢN PHẨM (PRODUCT REQUIREMENT DOCUMENT - PRD)

> **Tên sản phẩm:** ProNow  
> **Phiên bản:** 1.2.0  
> **Cập nhật lần cuối:** 2026-11-03  
> **Trạng thái:** Active Development  

---

## 1. TỔNG QUAN SẢN PHẨM (PRODUCT OVERVIEW)

### 1.1. Tầm nhìn (Vision)
ProNow là ứng dụng di động kết hợp giữa **Kỷ luật thói quen hàng ngày (Discipline Engine)** và **hệ thống phân tích phát âm theo âm vị**. Ứng dụng giúp người học tiếng Anh vượt qua hai rào cản lớn nhất: sự thiếu kiên trì bỏ cuộc giữa chừng và việc phát âm sai kinh niên do không nhận biết được âm vị bị sai lệch.

### 1.2. Mục tiêu cốt lõi (Core Objectives)
1. **Duy trì kỷ luật học tập:** Tăng tỷ lệ người dùng quay lại học mỗi ngày thông qua chuỗi streak, streak freeze, thông báo nhắc nhở cục bộ/push và bảng ma trận thói quen trực quan.
2. **Chấm phát âm chính xác từ dữ liệu âm thanh thật:** Thu âm thật từ micro, lọc tạp âm và yên lặng (VAD), phân tích tới cấp độ từ và âm vị (IPA), bóc tách chính xác các âm bị phát âm sai, nuốt âm, thêm âm.
3. **Đưa ra giải pháp khắc phục thực tế:** Không chỉ đưa ra con số điểm chung chung; ứng dụng chỉ rõ vị trí đặt lưỡi/môi/dây thanh và sinh bài tập luyện tập tập trung (Targeted Drills) cho các âm yếu thường gặp.
4. **Trải nghiệm tối giản, hiện đại:** Giao diện theo phong cách Notion Minimalism (tinh tế, sạch sẽ, không quảng cáo gây xao nhãng, tối ưu cả trên Mobile và Web).

---

## 2. CHÂN DUNG NGƯỜI DÙNG & USE CASES

- **Đối tượng chính:** Người học tiếng Anh (học sinh, sinh viên, người đi làm) muốn cải thiện kỹ năng Speaking và Pronunciation nhưng hay bị nản sau 3-5 ngày tự học.
- **Vấn đề thường gặp:**
  - Phát âm sai các phụ âm khó: `/θ/` thành `/s/` hoặc `/t/`, `/ð/` thành `/d/`, nuốt các phụ âm cuối `/t/`, `/d/`, `/s/`, `/z/`, `/k/`.
  - Không biết mình sai ở đâu khi đọc cả câu.
  - Quên luyện tập nếu không có thông báo nhắc nhở đúng giờ.

---

## 3. CHI TIẾT YÊU CẦU TÍNH NĂNG (FUNCTIONAL REQUIREMENTS)

### 3.1. Phân Hệ 1: Thu Âm & Phân Tích Phát Âm AI (Speech & Phoneme Engine)
- **FR-1.1: Thu âm thật từ Micro:**
  - Hỗ trợ thu âm đa nền tảng (Web Browser Audio API, Android/iOS PCM 16kHz WAV).
  - Có hiển thị trạng thái thu âm, thời lượng ghi âm và hiệu ứng phản hồi.
- **FR-1.2: Ô Nhập Tự Do Là Giao Diện Chính (Primary Custom Input Flow):**
  - Người dùng có thể gõ hoặc dán bất kỳ câu tiếng Anh nào vào ô nhập chính.
  - Các câu mẫu được hiển thị dưới dạng gợi ý nhanh (Quick Suggestions) - bấm vào tự động điền vào ô nhập.
  - Nút "Tạo Phiên Âm & Luyện Tập" gọi từ điển động `eng-to-ipa` sinh phiên âm chuẩn quốc tế.
- **FR-1.3: Nghe Phát Âm Mẫu Chuẩn (Free Text-To-Speech):**
  - Tích hợp Text-to-Speech miễn phí bản ngữ (`gTTS`/`edge-tts`) với nút 🔊 "Nghe đọc mẫu" cho mọi câu luyện tập.
- **FR-1.4: Căn Chỉnh Thứ Tự Từ & Chống Bị Lệch Câu (SequenceMatcher Alignment):**
  - Khi người dùng bỏ qua các từ đầu hoặc giữa câu, thuật toán căn chỉnh thông minh đánh dấu các từ bị thiếu là `Omission` mà không làm lệch các từ phát âm sau đó.
- **FR-1.5: Phát Hiện Nuốt Âm Đuôi & Chấm Điểm Độc Lập Từng Âm Vị:**
  - So sánh chi tiết từng âm vị, phát hiện nuốt âm cuối `/k/`, `/t/`, `/d/`, `/s/`, `/z/` và cảnh báo riêng rẽ cho từng âm vị thay vì cào bằng cả từ.
- **FR-1.4: Highlight trực quan kết quả:**
  - Màu Xanh (Green - $\ge 80$đ): Phát âm chuẩn.
  - Màu Vàng (Amber - $50 - 79$đ): Cần cải thiện.
  - Màu Đỏ (Red - $< 50$đ): Phát âm sai âm vị.
- **FR-1.5: Tương tác chạm âm vị (Interactive Phoneme Tap):**
  - Chạm vào từng âm vị hoặc từ để mở Callout Box hướng dẫn chi tiết vị trí lưỡi, môi, dây thanh.
- **FR-1.6: Đề xuất bài tập khắc phục:**
  - Tự động lọc âm vị yếu để đề xuất Targeted Drills và mở bài học tương ứng nếu có trong giáo trình.

### 3.2. Phân Hệ 2: Kỷ Luật & Theo Dõi Tiến Độ (Habit & Discipline Engine)
- **FR-2.1: Quản lý Chuỗi ngày luyện tập (Streak Tracking):**
  - Tự động cộng 1 ngày streak khi hoàn thành bài tập đầu tiên trong ngày.
  - Hỗ trợ tính năng **Streak Freeze (Bảo vệ chuỗi)**: Mặc định cấp 2 ngày đóng băng để bảo vệ chuỗi nếu lỡ quên 1 ngày bận rộn.
  - Tính kỷ lục chuỗi dài nhất (`longest_streak`).
- **FR-2.2: Ma trận thói quen (Notion/GitHub-style Streak Board):**
  - Hiển thị lưới đóng góp theo tuần và tháng với ô vuông kích thước chuẩn (12-14px).
  - Hiển thị ngày đã hoàn thành và ngày chưa hoàn thành rõ ràng trên cả Mobile lẫn Web.
  - Khi mở bảng tiến độ, làm mới cả thống kê ngày và streak từ backend; ngày hoạt động cuối từ streak được dùng làm mốc ngày thật nếu bản tổng hợp ngày chưa có.
- **FR-2.3: Đặt và theo dõi Mục tiêu hàng ngày (Daily Goals):**
  - Cho phép người dùng tùy chỉnh: Số phút luyện tập mục tiêu (5 - 60 phút), Số câu mục tiêu (5 - 50 câu).
  - Cộng thời lượng từ độ dài file thu âm sau lượt chấm có giọng nói; câu phát âm chuẩn chỉ cộng khi điểm tổng đạt từ 80.
  - Lưu số tổng hợp theo ngày, không lưu log từng lượt đọc câu tự do.
- **FR-2.4: Hệ thống thông báo nhắc nhở (Daily Reminders):**
  - Yêu cầu quyền thông báo của hệ điều hành/trình duyệt (`Notification.requestPermission()`).
  - Hẹn giờ gửi thông báo nhắc nhở rèn luyện theo giờ người dùng cài đặt.
  - Bộ đếm thời gian thực tự động kích hoạt thông báo khi đồng hồ thiết bị điểm giờ hẹn.
- **FR-2.5: Biểu Đồ Tiến Độ Theo Ngày:**
  - SQLite (`pronow.db`) chỉ lưu số tổng hợp theo ngày: điểm trung bình, thời lượng thu âm và số câu đạt.
  - Lịch tháng và biểu đồ điểm trung bình 7 ngày sử dụng số liệu tổng hợp; không lưu danh sách mọi lượt đọc câu tự do.
  - Giữ riêng tiến độ bài học và sổ tay câu đã lưu.

### 3.3. Phân Hệ 3: Lộ Trình & Bài Học (Curriculum & Practice Flow)
- **FR-3.1: Danh mục bài học phân theo chủ đề & cấp độ:**
  - Cặp âm tối thiểu (`/θ/` & `/ð/`, `/iː/` vs `/ɪ/`, ...).
  - Âm đuôi và phụ âm bật (`/t/`, `/d/`, `/s/`, `/z/`).
  - Nối âm và ngữ điệu câu.
- **FR-3.2: Luồng học tập hoàn chỉnh:**
  - Người dùng bấm vào bài học $\rightarrow$ Xem danh sách các câu trong bài $\rightarrow$ Chọn câu bất kỳ $\rightarrow$ Chuyển thẳng sang màn hình Luyện Nói với câu mẫu đó để bắt đầu thu âm.

---

## 4. GHI CHÚ TRIỂN KHAI HIỆN TẠI

- **Chấm phát âm:** `SpeechRecognition` gọi Google Web Speech API (`recognize_google`) lấy transcript; `eng-to-ipa` tra IPA; thuật toán căn chỉnh từ và heuristic âm vị/âm cuối tính điểm. Đây chưa phải mô hình AI acoustic chấm từng âm vị trực tiếp; Azure Speech chưa được tích hợp.
- **Điểm:** Overall = 60% accuracy + 30% fluency + 10% completeness. Accuracy chủ yếu dựa trên transcript/IPA và heuristic; kiểm tra âm cuối dùng đặc trưng tín hiệu 200 ms cuối.
- **Streak:** Lượt có điểm > 0 ghi nhận ngày; lượt im lặng/0 điểm không tính. Ngày kế tiếp tăng chuỗi; nghỉ đúng một ngày dùng freeze nếu còn.
- **Mục tiêu hôm nay:** Sau lượt có điểm > 0, cộng độ dài WAV vào phút luyện; câu chỉ tăng khi điểm tổng >= 80. Backend tổng hợp theo ngày, app tải lại sau khi chấm và khi mở dashboard.
- **Lưu trữ:** Không ghi log lượt nói tự do; chỉ lưu thống kê tổng hợp theo ngày, tiến độ câu trong bài học và câu người dùng chủ động lưu.
- **Sơ đồ khẩu hình:** Ảnh tải từ Wikimedia Commons; nếu ảnh trực tuyến lỗi, app hiển thị sơ đồ vector thay thế cùng mô tả.
- **Nền tảng ưu tiên:** Android và Chrome. Android emulator dùng `10.0.2.2`; Android thật cấu hình `PRONOW_API_BASE_URL` theo LAN IP backend. Xem `mobile/README.md`.

## 5. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS)

- **NFR-1 (Độ trễ - Latency):** Thời gian từ khi dừng thu âm đến khi trả kết quả phân tích âm vị $\le 2.0$ giây.
- **NFR-2 (Tính chân thực - Data Integrity):** Tuyệt đối không sinh dữ liệu ngẫu nhiên giả mạo. Phải phân tích dựa trên tín hiệu âm thanh thực.
- **NFR-3 (Thiết kế - UI/UX):** Tuân thủ triệt để ngôn ngữ thiết kế Notion Minimalism:
  - Bảng màu: Nền ngà `#FBFBFA`, viền `#EBEAE8`, chữ than `#37352F`.
  - Bố cục responsive: Giới hạn chiều rộng tối đa (Max-width 720px) căn giữa trên màn hình Web để không bị vỡ bố cục hoặc quá to.
- **NFR-4 (Nền tảng):** Ưu tiên Android và Chrome; iOS/Safari/Edge chưa phải phạm vi kiểm thử chính.

---

## 6. LỊCH SỬ THAY ĐỔI & CẬP NHẬT (CHANGELOG)

- **v1.0.0 (2026-10-31):** Khởi tạo tài liệu PRD, quy định các tiêu chuẩn kỹ thuật không fake dữ liệu và hoàn thiện luồng người dùng.
- **v1.1.0 (2026-11-03):** Làm rõ stack chấm phát âm; biểu đồ tiến bộ, gợi ý bài học, sơ đồ dự phòng và ưu tiên Android/Chrome.
- **v1.2.0 (2026-11-03):** Bỏ log từng lượt đọc tự do; tổng hợp theo ngày và nối số phút thu âm/số câu đạt vào mục tiêu hàng ngày.
- **v1.2.0 (2026-11-03):** Bỏ log từng lượt đọc tự do; chuyển sang tổng hợp ngày, nối số phút thu âm và số câu đạt vào mục tiêu.
