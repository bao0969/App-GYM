# 📊 Nghiên Cứu Nghiệp Vụ: California Fitness & Yoga Vietnam

## 🎯 Tổng Quan

California Fitness & Yoga là chuỗi phòng gym quốc tế lớn nhất tại Việt Nam, ra đời từ năm 2007 với hơn 55 chi nhánh. Họ phục vụ hơn 500,000 hội viên và tập trung vào cách tiếp cận toàn diện về sức khỏe và thể chất.

## 🏋️ Các Dịch Vụ Chính

### 1. **Thẻ Hội Viên (Membership)**
- Gói tập theo thời gian (1 tháng, 3 tháng, 6 tháng, 1 năm)
- Truy cập không giới hạn vào phòng gym
- Tham gia các lớp GroupX (Yoga, Zumba, Kickfit, Boxing)
- Sử dụng thiết bị Technogym cao cấp
- Tích hợp iCloud để theo dõi tiến độ

### 2. **Huấn Luyện Viên Cá Nhân (Personal Training - PT)**
- Chương trình tập cá nhân hóa
- Theo dõi tiến độ chi tiết
- Tư vấn dinh dưỡng
- Gói PT theo số buổi (10, 20, 30 buổi)
- Hoa hồng cho PT khi hoàn thành buổi tập

### 3. **Lớp Nhóm (Group Classes)**
- **Yoga**: Sunrise Yoga, Power Yoga, Hatha Yoga
- **Kickfit**: Kết hợp kickboxing và fitness
- **Zumba**: Nhảy aerobic Latin
- **Spinning**: Đạp xe trong nhà
- **Boxing**: Quyền Anh thể dục

### 4. **Dịch Vụ Bổ Sung**
- **Califresh**: Quầy nước ép trái cây và đồ uống healthy
- **Ca Republik**: Cửa hàng đồ thể thao
- **HYPOXI**: Công nghệ giảm mỡ định vị
- **Inbody**: Đo lường thành phần cơ thể

### 5. **Chương Trình Thử Thách (Challenges)**
- **CTC (California Transformation Challenge)**: Thử thách giảm cân/tăng cơ
- **California Kickfit Challenge**: Thi đấu kickfit
- **California Sunrise Yoga**: Thi yoga buổi sáng
- Giải thưởng và động lực cho hội viên

## 💡 Các Tính Năng Đã Áp Dụng Vào GymSync

### ✅ Đã Có
1. **Quản lý hội viên** với các trạng thái (active, expired, paused)
2. **Gói tập** theo thời gian với các tính năng khác nhau
3. **Check-in** bằng QR code hoặc thủ công
4. **Huấn luyện viên** với thông tin chuyên môn
5. **Theo dõi Inbody** (cân nặng, body fat, số đo)
6. **POS** bán đồ uống, supplement, quần áo
7. **Voucher/Coupon** giảm giá
8. **Quản lý tủ đồ** (Locker)
9. **Lịch đặt** (Booking) cho lớp nhóm

### 🚀 Cần Nâng Cấp Thêm

#### 1. **Hệ Thống PT Sessions (Đã có model, cần UI)**
```dart
// Đã có model: pt_session_model.dart
// Cần thêm:
- Màn hình đặt lịch PT cho hội viên
- Màn hình quản lý lịch PT cho trainer
- Tính hoa hồng tự động cho PT
- Đánh giá PT sau buổi tập
```

#### 2. **Group Classes (Lớp Nhóm)**
```dart
// Cần tạo:
- Model: group_class_model.dart
- Lịch lớp học theo tuần
- Đăng ký tham gia lớp
- Giới hạn số người (capacity)
- Điểm danh lớp học
```

#### 3. **Challenges & Competitions**
```dart
// Cần tạo:
- Model: challenge_model.dart
- Thử thách giảm cân/tăng cơ
- Bảng xếp hạng (leaderboard)
- Theo dõi tiến độ challenge
- Giải thưởng và badges
```

#### 4. **Nutrition Tracking**
```dart
// Đã có màn hình member_nutrition_screen.dart
// Cần nâng cấp:
- Ghi nhận bữa ăn hàng ngày
- Tính calories
- Gợi ý thực đơn
- Tích hợp với Califresh (đồ uống)
```

#### 5. **Workout Library**
```dart
// Đã có màn hình member_workout_library_screen.dart
// Cần nâng cấp:
- Video hướng dẫn bài tập
- Chương trình tập theo mục tiêu
- Lưu bài tập yêu thích
- Theo dõi số set/rep đã tập
```

#### 6. **Multi-Branch Support**
```dart
// Đã có field branchId trong models
// Cần thêm:
- Chọn chi nhánh khi đăng ký
- Check-in tại chi nhánh khác
- Xem lịch lớp theo chi nhánh
- Báo cáo theo chi nhánh
```

#### 7. **Referral Program (Giới Thiệu Bạn Bè)**
```dart
// Cần tạo:
- Mã giới thiệu cá nhân
- Ưu đãi cho người giới thiệu
- Theo dõi số người đã giới thiệu
- Hoa hồng/quà tặng
```

#### 8. **Freeze Membership (Tạm Dừng Gói Tập)**
```dart
// Cần thêm:
- Yêu cầu tạm dừng gói tập
- Gia hạn thời gian tương ứng
- Lý do tạm dừng
- Giới hạn số lần freeze
```

## 📱 Banner Carousel Đã Thêm

### Admin Dashboard
- 6 banner về thiết bị, HLV, không gian, lớp nhóm, inbody, 24/7

### Staff Dashboard  
- 4 banner về chào đón, check-in, hỗ trợ, vệ sinh

### Trainer Dashboard
- 4 banner về truyền cảm hứng, kỹ thuật, chương trình, theo dõi

### Member Dashboard
- 5 banner động lực: "Không có gì là không thể", "Cơ bắp được tạo ở gym", "Đau hôm nay mạnh ngày mai"

## 🎨 Đặc Điểm Thiết Kế California Fitness

1. **Sang Trọng & Hiện Đại**: Thiết kế 5 sao, không gian rộng rãi
2. **Công Nghệ Cao**: Technogym, iCloud tracking, app mobile
3. **Toàn Diện**: Không chỉ gym mà còn yoga, kickfit, dinh dưỡng
4. **Cộng Đồng**: Challenges, events, kết nối hội viên
5. **Chuyên Nghiệp**: Đội ngũ PT có chứng chỉ quốc tế

## 📊 Mô Hình Kinh Doanh

### Nguồn Thu Chính
1. **Thẻ hội viên** (70-80% doanh thu)
2. **PT sessions** (15-20% doanh thu)
3. **Califresh & Ca Republik** (5-10% doanh thu)
4. **HYPOXI & dịch vụ đặc biệt** (bổ sung)

### Chiến Lược Giữ Chân Khách Hàng
1. Challenges & competitions
2. Theo dõi tiến độ chi tiết
3. Cộng đồng hội viên mạnh
4. Dịch vụ khách hàng xuất sắc
5. Không gian sang trọng

## 🔄 Roadmap Phát Triển GymSync

### Phase 1: Hoàn Thiện Core (✅ Đã Xong)
- ✅ Quản lý hội viên, gói tập
- ✅ Check-in QR code
- ✅ Dashboard cho 4 roles
- ✅ POS, Inventory, Lockers
- ✅ Inbody tracking
- ✅ Banner carousel

### Phase 2: PT & Group Classes (🔄 Đang Làm)
- 🔄 UI cho PT sessions
- 🔄 Group classes management
- 🔄 Booking system nâng cao
- 🔄 Rating & reviews

### Phase 3: Engagement & Retention
- ⏳ Challenges & competitions
- ⏳ Leaderboards
- ⏳ Badges & achievements
- ⏳ Referral program

### Phase 4: Advanced Features
- ⏳ Multi-branch support
- ⏳ Mobile app
- ⏳ Workout videos
- ⏳ Nutrition tracking chi tiết
- ⏳ Integration với wearables

## 💼 Nghiệp Vụ Quan Trọng Cần Lưu Ý

### 1. **Gia Hạn Gói Tập**
- Nhắc nhở trước 7 ngày hết hạn
- Ưu đãi cho gia hạn sớm
- Tự động chuyển sang expired nếu không gia hạn

### 2. **PT Commission**
- Tính hoa hồng theo buổi hoàn thành
- Bonus khi đạt target tháng
- Đánh giá từ hội viên ảnh hưởng thu nhập

### 3. **Check-in Rules**
- Chỉ check-in khi gói còn hạn
- Cảnh báo nếu check-in 2 lần/ngày
- Theo dõi tần suất tập để tư vấn

### 4. **Inventory Management**
- Cảnh báo sắp hết hàng
- Tự động trừ khi bán (POS)
- Báo cáo tồn kho định kỳ

### 5. **Locker Management**
- Thuê theo tháng
- Cảnh báo trước 7 ngày hết hạn
- Tự động release nếu không gia hạn

---

**Nguồn tham khảo**: https://cali.vn/
**Ngày nghiên cứu**: 22/05/2026
**Phiên bản GymSync**: 2.0
