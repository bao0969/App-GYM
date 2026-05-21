# 📋 TÀI LIỆU LOGIC NGHIỆP VỤ - GYMSYNC APP

## 🎯 TỔNG QUAN HỆ THỐNG

GymSync là hệ thống quản lý phòng gym toàn diện, được thiết kế dựa trên mô hình kinh doanh của California Fitness & Yoga - chuỗi phòng gym hàng đầu Việt Nam. Hệ thống hỗ trợ 4 vai trò chính với các chức năng đặc thù.

---

## 👥 CÁC VAI TRÒ VÀ QUYỀN HẠN

### 🔴 ADMIN (Quản lý cấp cao)
**Mục tiêu**: Quản lý toàn bộ hoạt động kinh doanh, theo dõi doanh thu và hiệu suất

**Chức năng chính**:
- **Dashboard tổng quan**: Doanh thu, số lượng hội viên, check-in hôm nay
- **Quản lý gói tập**: Tạo/sửa/xóa các gói membership
- **Quản lý hội viên**: Xem danh sách, gia hạn, tạm dừng, kích hoạt
- **Quản lý nhân viên**: Thêm staff, trainer, phân quyền
- **Báo cáo tài chính**: Doanh thu theo ngày/tháng/năm
- **Quản lý voucher**: Tạo mã giảm giá, theo dõi sử dụng
- **POS System**: Bán hàng tại quầy (nước, supplement, phụ kiện)
- **Quản lý kho**: Theo dõi tồn kho, nhập hàng
- **Quản lý tủ đồ**: Phân bổ, thu phí hàng tháng
- **Inbody tracking**: Theo dõi chỉ số cơ thể hội viên
- **QR Generator**: Tạo mã QR cho hội viên mới

### 🟡 STAFF (Nhân viên lễ tân)
**Mục tiêu**: Hỗ trợ hội viên, xử lý giao dịch hàng ngày

**Chức năng chính**:
- **Check-in hội viên**: Quét QR, kiểm tra hạn membership
- **Đăng ký hội viên mới**: Thu thập thông tin, chọn gói
- **Gia hạn membership**: Xử lý thanh toán, cập nhật hạn sử dụng
- **Bán hàng POS**: Bán nước, supplement tại quầy
- **Hỗ trợ khách hàng**: Giải đáp thắc mắc, xử lý khiếu nại
- **Quản lý tủ đồ**: Phân bổ tủ cho hội viên
- **Báo cáo ca làm**: Tổng kết doanh thu, số lượng giao dịch

### 🟢 TRAINER (Huấn luyện viên)
**Mục tiêu**: Hướng dẫn tập luyện, tư vấn chuyên môn

**Chức năng chính**:
- **Quản lý lịch PT**: Xem lịch cá nhân, đặt lịch với hội viên
- **Theo dõi tiến độ**: Ghi nhận kết quả tập của học viên
- **Inbody tracking**: Đo và phân tích chỉ số cơ thể
- **Tư vấn dinh dưỡng**: Đưa ra lời khuyên về chế độ ăn
- **Gamification**: Ghi nhận workout, trao badges
- **Báo cáo hiệu suất**: Số buổi PT, đánh giá từ học viên

### 🔵 MEMBER (Hội viên)
**Mục tiêu**: Tập luyện hiệu quả, theo dõi tiến độ cá nhân

**Chức năng chính**:
- **Check-in**: Quét QR để vào phòng gym
- **Xem thông tin cá nhân**: Gói tập, ngày hết hạn, lịch sử
- **Đặt lịch PT**: Chọn trainer, thời gian phù hợp
- **Theo dõi Inbody**: Xem biểu đồ tiến độ cơ thể
- **Gamification**: Xem level, badges, thử thách
- **Lịch sử tập luyện**: Theo dõi số buổi, streak
- **Gia hạn online**: Thanh toán qua app

---

## 💼 CÁC MODULE NGHIỆP VỤ CHÍNH

### 1. 👤 QUẢN LÝ HỘI VIÊN (Member Management)

#### 📊 Trạng thái hội viên:
- **Active**: Đang hoạt động, trong hạn sử dụng
- **Expired**: Hết hạn membership (>0 ngày)
- **Expiring Soon**: Sắp hết hạn (≤7 ngày)
- **Paused**: Tạm dừng (đi công tác, ốm đau)
- **Inactive**: Ngừng hoạt động

#### 🔄 Quy trình đăng ký:
1. **Thu thập thông tin**: Họ tên, SĐT, email, địa chỉ
2. **Chọn gói tập**: Cơ bản/Tiêu chuẩn/VIP/Sinh viên
3. **Áp dụng voucher**: Kiểm tra mã giảm giá (nếu có)
4. **Thanh toán**: Tiền mặt/Chuyển khoản
5. **Tạo QR Code**: Mã định danh duy nhất
6. **Kích hoạt**: Bắt đầu tính thời hạn

#### 📈 Tính toán ngày hết hạn:
```
Ngày hết hạn = Ngày đăng ký + Số ngày của gói
- Gói Cơ bản: 30 ngày
- Gói Tiêu chuẩn: 90 ngày  
- Gói VIP: 365 ngày
- Gói Sinh viên: 30 ngày
```

### 2. 💰 HỆ THỐNG THANH TOÁN & VOUCHER

#### 🎫 Loại voucher:
- **Percent**: Giảm theo phần trăm (có giới hạn tối đa)
- **Fixed**: Giảm số tiền cố định
- **Unlimited**: Không giới hạn số lần sử dụng (-1)
- **Limited**: Giới hạn số lượng

#### 🧮 Công thức tính giảm giá:
```dart
// Voucher phần trăm
double discount = (originalPrice * voucherValue / 100);
if (maxDiscount > 0) {
  discount = min(discount, maxDiscount);
}

// Voucher cố định
double discount = voucherValue;

// Kiểm tra điều kiện
if (originalPrice >= minOrderAmount && 
    usedCount < totalQuantity && 
    isInValidDateRange) {
  finalPrice = originalPrice - discount;
}
```

### 3. 🛒 HỆ THỐNG POS (Point of Sale)

#### 📦 Danh mục sản phẩm:
- **Drink**: Nước uống (Lavie, Pocari, Red Bull)
- **Supplement**: Thực phẩm bổ sung (Whey, BCAA, Creatine)
- **Apparel**: Quần áo tập (Tank top, Shorts)
- **Accessory**: Phụ kiện (Găng tay, Đai lưng, Khăn)

#### 📊 Quản lý tồn kho:
```dart
// Cảnh báo sắp hết hàng
if (currentStock <= lowStockThreshold) {
  showLowStockAlert();
}

// Tính lợi nhuận
double profit = (sellPrice - costPrice) * quantity;
double profitMargin = (profit / sellPrice) * 100;
```

### 4. 🏃‍♂️ HỆ THỐNG CHECK-IN

#### ✅ Quy trình check-in:
1. **Quét QR Code**: Đọc mã từ thẻ hội viên
2. **Kiểm tra trạng thái**: Active/Expired/Paused
3. **Xác thực thời hạn**: So sánh với ngày hiện tại
4. **Ghi nhận**: Lưu thời gian check-in
5. **Cập nhật streak**: Tính chuỗi ngày tập liên tục

#### 📱 Phương thức check-in:
- **QR Scanner**: Quét mã từ app/thẻ vật lý
- **Manual**: Nhân viên nhập thông tin thủ công
- **RFID**: Thẻ từ (tương lai)

### 5. 🎮 HỆ THỐNG GAMIFICATION

#### 🏆 Cơ chế tính điểm:
```dart
// XP từ thời gian tập
int baseXP = durationMinutes * 2; // 2 XP/phút
int bonusXP = 0;

// Bonus cho workout dài
if (durationMinutes >= 60) bonusXP += 50;
if (durationMinutes >= 90) bonusXP += 100;

// Bonus streak
if (currentStreak >= 7) bonusXP += 30;
if (currentStreak >= 30) bonusXP += 100;

int totalXP = baseXP + bonusXP;
```

#### 📊 Hệ thống level:
```dart
// Tính XP cần cho level tiếp theo
int xpForLevel(int level) {
  return (100 * level * 1.5).round();
}

// Rank theo level
String getRank(int level) {
  if (level >= 50) return 'Huyền Thoại';
  if (level >= 40) return 'Đại Sư';
  if (level >= 30) return 'Chuyên Gia';
  if (level >= 20) return 'Cao Thủ';
  if (level >= 10) return 'Trung Cấp';
  return 'Tân Binh';
}
```

#### 🏅 Hệ thống badges:
- **Workout Count**: 1, 10, 50, 100, 365 buổi
- **Streak**: 7, 30, 100 ngày liên tục
- **Special**: Chim sớm, Cú đêm, Chiến binh cuối tuần
- **Social**: Tham gia lớp nhóm

### 6. 🗄️ QUẢN LÝ TỦ ĐỒ (Locker Management)

#### 🏷️ Mã hóa tủ:
- **Khu A (Nam)**: A001-A015
- **Khu B (Nữ)**: B001-B015
- **Phí thuê**: 100,000 VNĐ/tháng

#### 📋 Trạng thái tủ:
- **Available**: Có thể thuê
- **Assigned**: Đã được thuê
- **Maintenance**: Đang bảo trì
- **Reserved**: Đặt trước

### 7. 📊 INBODY TRACKING

#### 📏 Chỉ số theo dõi:
- **Cân nặng** (Weight): kg
- **Chiều cao** (Height): cm  
- **Tỷ lệ mỡ** (Body Fat): %
- **Vòng ngực** (Chest): cm
- **Vòng eo** (Waist): cm
- **Vòng mông** (Hips): cm

#### 📈 Phân tích xu hướng:
```dart
// Tính BMI
double bmi = weight / ((height/100) * (height/100));

// Đánh giá BMI
String getBMICategory(double bmi) {
  if (bmi < 18.5) return 'Thiếu cân';
  if (bmi < 25) return 'Bình thường';
  if (bmi < 30) return 'Thừa cân';
  return 'Béo phì';
}

// Tính % thay đổi
double changePercent = ((current - previous) / previous) * 100;
```

### 8. 💪 QUẢN LÝ PERSONAL TRAINING

#### 📅 Đặt lịch PT:
1. **Chọn trainer**: Xem profile, chuyên môn, đánh giá
2. **Chọn thời gian**: Kiểm tra lịch trống
3. **Xác nhận**: Trainer approve/reject
4. **Thanh toán**: Trước hoặc sau buổi tập
5. **Đánh giá**: Hội viên rate trainer (1-5 sao)

#### 💵 Tính hoa hồng trainer:
```dart
// Hoa hồng cố định mỗi buổi
double commission = 150000; // VNĐ

// Bonus theo rating
if (averageRating >= 4.5) commission *= 1.2;
if (averageRating >= 4.0) commission *= 1.1;
```

---

## 🔄 QUY TRÌNH NGHIỆP VỤ CHÍNH

### 1. 📝 Đăng ký hội viên mới
```
Staff nhập thông tin → Chọn gói → Áp dụng voucher → 
Thanh toán → Tạo QR → Kích hoạt → Gửi thông tin
```

### 2. 🔄 Gia hạn membership
```
Kiểm tra hội viên → Chọn gói mới → Tính toán giá → 
Áp dụng voucher → Thanh toán → Cập nhật hạn sử dụng
```

### 3. ✅ Check-in hàng ngày
```
Quét QR → Kiểm tra trạng thái → Xác thực hạn → 
Ghi nhận check-in → Cập nhật streak → Tính XP
```

### 4. 🛒 Bán hàng POS
```
Quét barcode → Chọn số lượng → Tính tổng tiền → 
Áp dụng giảm giá → Thanh toán → In hóa đơn → Cập nhật kho
```

### 5. 📊 Đo Inbody
```
Chuẩn bị thiết bị → Đo các chỉ số → Nhập vào hệ thống → 
Phân tích xu hướng → Tư vấn → Lưu lịch sử
```

---

## 📊 BÁO CÁO & THỐNG KÊ

### 📈 Dashboard Admin:
- **Doanh thu hôm nay**: Membership + POS + PT
- **Số hội viên mới**: Đăng ký trong ngày
- **Check-in hôm nay**: Lượt vào phòng gym
- **Hội viên sắp hết hạn**: Cần gia hạn trong 7 ngày
- **Sản phẩm sắp hết**: Stock < threshold
- **Top trainer**: Theo số buổi PT và rating

### 📊 Báo cáo tài chính:
- **Doanh thu theo ngày/tháng/năm**
- **Phân tích theo nguồn**: Membership vs POS vs PT
- **Tỷ lệ gia hạn**: Retention rate
- **Chi phí vận hành**: Lương, điện nước, thiết bị
- **Lợi nhuận**: Gross profit, Net profit

### 📋 Báo cáo hoạt động:
- **Tần suất check-in**: Peak hours, busy days
- **Hiệu suất trainer**: Số buổi, rating, doanh thu
- **Sử dụng voucher**: Mã nào được dùng nhiều nhất
- **Phân tích hội viên**: Demographics, behavior patterns

---

## 🔐 BẢO MẬT & PHÂN QUYỀN

### 🛡️ Phân quyền dữ liệu:
- **Admin**: Full access tất cả dữ liệu
- **Staff**: Chỉ xem dữ liệu ca làm việc của mình
- **Trainer**: Chỉ xem học viên được phân công
- **Member**: Chỉ xem dữ liệu cá nhân

### 🔒 Bảo mật:
- **Firebase Authentication**: Xác thực người dùng
- **Firestore Rules**: Kiểm soát truy cập database
- **QR Code Encryption**: Mã hóa thông tin hội viên
- **Audit Log**: Ghi nhận mọi thao tác quan trọng

---

## 🚀 TÍNH NĂNG ĐỘT PHÁ

### 1. 🎮 Gamification System
- **Level & XP**: Tăng động lực tập luyện
- **Badges & Achievements**: Ghi nhận thành tích
- **Challenges**: Thử thách cá nhân và nhóm
- **Leaderboard**: Bảng xếp hạng tháng

### 2. 🤖 AI Recommendations
- **Workout Plans**: Gợi ý bài tập theo mục tiêu
- **Nutrition Advice**: Tư vấn dinh dưỡng cá nhân hóa
- **Schedule Optimization**: Đề xuất thời gian tập tối ưu

### 3. 📱 Social Features
- **Workout Buddy**: Tìm bạn tập cùng
- **Progress Sharing**: Chia sẻ thành tích
- **Group Challenges**: Thử thách nhóm bạn

### 4. 🏆 Loyalty Program
- **Points System**: Tích điểm từ mọi hoạt động
- **Tier Benefits**: VIP perks theo level
- **Referral Rewards**: Thưởng giới thiệu bạn bè

---

## 📱 RESPONSIVE DESIGN

### 💻 Desktop (>720px):
- Layout 2-3 cột
- Sidebar navigation
- Data tables với nhiều cột
- Charts & graphs lớn

### 📱 Mobile (<720px):
- Single column layout
- Bottom navigation
- Card-based UI
- Swipe gestures
- Touch-optimized buttons

---

## 🔮 ROADMAP TƯƠNG LAI

### Phase 2:
- **Multi-branch**: Hỗ trợ nhiều cơ sở
- **Mobile App**: Native iOS/Android
- **Wearable Integration**: Apple Watch, Fitbit
- **Video Streaming**: Lớp tập online

### Phase 3:
- **AI Personal Trainer**: Chatbot tư vấn 24/7
- **AR Workout**: Thực tế ảo tăng cường
- **Blockchain Rewards**: Token economy
- **IoT Integration**: Smart equipment tracking

---

*Tài liệu này được cập nhật liên tục theo sự phát triển của hệ thống. Phiên bản hiện tại: v2.0 - Tháng 5/2026*