import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class AdminSupportTicketsScreen extends StatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  State<AdminSupportTicketsScreen> createState() => _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState extends State<AdminSupportTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hỗ Trợ & Phê Duyệt',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Yêu Cầu Báo Lỗi', icon: Icon(Icons.bug_report_rounded)),
            Tab(text: 'Duyệt Thẻ Sinh Viên', icon: Icon(Icons.school_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketsTab(),
          _buildStudentVerificationsTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: SUPPORT TICKETS LIST ====================
  Widget _buildTicketsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.check_circle_outline_rounded, 'Chưa có yêu cầu hỗ trợ nào');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final String ticketId = doc.id;
            
            return _TicketItemCard(
              ticketId: ticketId,
              data: data,
            );
          },
        );
      },
    );
  }

  // ==================== TAB 2: STUDENT VERIFICATIONS ====================
  Widget _buildStudentVerificationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_verifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(Icons.school_outlined, 'Chưa có yêu cầu duyệt thẻ sinh viên nào');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final String verificationId = doc.id;

            return _StudentVerificationCard(
              verificationId: verificationId,
              data: data,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: AppColors.textHint, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

class _TicketItemCard extends StatelessWidget {
  final String ticketId;
  final Map<String, dynamic> data;

  const _TicketItemCard({required this.ticketId, required this.data});

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Cao':
        return AppColors.error;
      case 'Trung bình':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'in-progress':
        return AppColors.accent;
      default:
        return AppColors.textHint;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'resolved':
        return 'Đã giải quyết';
      case 'in-progress':
        return 'Đang xử lý';
      default:
        return 'Đang chờ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = data['severity'] ?? 'Thấp';
    final status = data['status'] ?? 'pending';
    final title = data['title'] ?? 'Lỗi không tên';
    final desc = data['description'] ?? '';
    final category = data['category'] ?? 'Lỗi Khác';
    final memberName = data['memberName'] ?? 'Ẩn danh';
    final email = data['email'] ?? '';
    final responseMessage = data['responseMessage'] ?? '';
    
    final createdVal = data['createdAt'];
    final DateTime createdDate = createdVal is Timestamp ? createdVal.toDate() : DateTime.now();
    final dateStr = '${createdDate.hour}:${createdDate.minute.toString().padLeft(2, '0')} ${createdDate.day}/${createdDate.month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSeverityColor(severity).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Severity badge, Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: [
                  // Severity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getSeverityColor(severity).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Khẩn: $severity',
                      style: TextStyle(color: _getSeverityColor(severity), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ticket Title
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          // Ticket Desc
          Text(
            desc,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          // Member Meta & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gửi bởi: $memberName',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$email • $dateStr',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showProcessTicketDialog(context, title, status, responseMessage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 14, color: Colors.white),
                label: const Text(
                  'Xử lý',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          if (responseMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phản hồi từ Admin:',
                    style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    responseMessage,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showProcessTicketDialog(
      BuildContext context, String title, String currentStatus, String currentResponse) {
    final responseCtrl = TextEditingController(text: currentResponse);
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Xử Lý Yêu Cầu Hỗ Trợ',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket: "$title"',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trạng thái xử lý',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Đang chờ')),
                          DropdownMenuItem(value: 'in-progress', child: Text('Đang xử lý')),
                          DropdownMenuItem(value: 'resolved', child: Text('Đã giải quyết')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedStatus = v ?? selectedStatus),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Viết phản hồi giải quyết',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: responseCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: 'VD: Lỗi đã được kỹ thuật sửa. Xin lỗi quý khách...',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).update({
                    'status': selectedStatus,
                    'responseMessage': responseCtrl.text.trim(),
                  });
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật trạng thái xử lý ticket!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _StudentVerificationCard extends StatelessWidget {
  final String verificationId;
  final Map<String, dynamic> data;

  const _StudentVerificationCard({required this.verificationId, required this.data});

  @override
  Widget build(BuildContext context) {
    final String school = data['schoolName'] ?? '';
    final String studentId = data['studentId'] ?? '';
    final String memberName = data['memberName'] ?? 'Hội viên';
    final String email = data['email'] ?? '';
    final String status = data['status'] ?? 'pending';
    
    final createdVal = data['createdAt'];
    final DateTime createdDate = createdVal is Timestamp ? createdVal.toDate() : DateTime.now();
    final dateStr = '${createdDate.day}/${createdDate.month}/${createdDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'approved' 
              ? AppColors.success.withValues(alpha: 0.3) 
              : (status == 'rejected' ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    school,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
              // Status label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? AppColors.success.withValues(alpha: 0.15)
                      : (status == 'rejected' ? AppColors.error.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'approved' ? 'Đã Duyệt' : (status == 'rejected' ? 'Từ Chối' : 'Chờ Duyệt'),
                  style: TextStyle(
                    color: status == 'approved'
                        ? AppColors.success
                        : (status == 'rejected' ? AppColors.error : AppColors.primary),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Member Details
          Text(
            'Họ Tên: $memberName',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            'Mã Số Sinh Viên: $studentId',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 3),
          Text(
            'Email: $email',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            'Ngày gửi: $dateStr',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 14),
          
          // Mimic Student Card Image Box
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_rounded, color: AppColors.textHint, size: 28),
                  SizedBox(height: 6),
                  Text(
                    'Đã tải ảnh Thẻ Sinh Viên ✓',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Từ Chối',
                      style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Phê Duyệt',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('student_verifications')
          .doc(verificationId)
          .update({'status': newStatus});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'approved'
                  ? 'Đã duyệt thẻ sinh viên thành công! Mã giảm giá STUDENT30 đã kích hoạt.'
                  : 'Đã từ chối thẻ sinh viên.',
            ),
            backgroundColor: newStatus == 'approved' ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
