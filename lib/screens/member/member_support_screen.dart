import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';

class MemberSupportScreen extends StatefulWidget {
  const MemberSupportScreen({super.key});

  @override
  State<MemberSupportScreen> createState() => _MemberSupportScreenState();
}

class _MemberSupportScreenState extends State<MemberSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'Lỗi Thanh Toán';
  String _selectedSeverity = 'Trung bình';
  bool _emailNotification = true;
  bool _isSubmitting = false;

  // AI Chat states
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Xin chào! Tôi là Trợ Lý AI GymSync 🤖. Bạn có câu hỏi nào cần tôi giải đáp hôm nay?',
      'time': DateTime.now(),
    }
  ];
  final _chatCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;

  final List<String> _quickQuestions = [
    'Làm thế nào để bảo lưu gói tập?',
    'Chương trình ưu đãi sinh viên thế nào?',
    'Cách đặt lịch tập với PT cá nhân?',
    'Tôi gặp lỗi khi thanh toán gói tập',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _chatCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // AI Chat Logic
  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _chatCtrl.clear();
      _isAiTyping = true;
    });

    _scrollToBottom();

    // Generate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      String response = '';
      final lowercaseText = text.toLowerCase();

      if (lowercaseText.contains('bảo lưu') || lowercaseText.contains('bao luu')) {
        response = 'Hội viên có thể bảo lưu tối đa 30 ngày đối với gói tập 6 tháng trở lên. Vui lòng mang CCCD qua quầy lễ tân chi nhánh gần nhất để được hỗ trợ thủ tục miễn phí nhé! 📄';
      } else if (lowercaseText.contains('sinh viên') || lowercaseText.contains('sinh vien')) {
        response = 'Chúng tôi có ưu đãi giảm ngay 30% cho sinh viên khi mua gói tập! Bạn chỉ cần vào tab "Ưu Đãi", điền thông tin và chụp ảnh Thẻ sinh viên gửi duyệt là sẽ nhận được mã giảm giá STUDENT30 nhé! 🎓';
      } else if (lowercaseText.contains('đặt lịch') || lowercaseText.contains('pt') || lowercaseText.contains('dat lich')) {
        response = 'Để đặt lịch với PT, bạn vào màn hình Lịch Tập từ menu chính, chọn tab PT và tìm kiếm Huấn luyện viên phù hợp để đăng ký khung giờ rảnh mong muốn. 🏋️‍♂️';
      } else if (lowercaseText.contains('thanh toán') || lowercaseText.contains('lỗi') || lowercaseText.contains('thanh toan')) {
        response = 'Tôi rất tiếc về sự cố thanh toán bạn gặp phải. Hãy chuyển qua tab "Báo Lỗi & Phản Hồi" bên cạnh để điền thông tin chi tiết. Hệ thống sẽ tiếp nhận và xử lý ngay lập tức! 💳';
      } else if (lowercaseText.contains('xin chào') || lowercaseText.contains('hello') || lowercaseText.contains('chào')) {
        response = 'Xin chào! GymSync chúc bạn một ngày luyện tập tràn đầy năng lượng! Tôi có thể giúp gì thêm cho bạn? 🌟';
      } else {
        response = 'GymSync ghi nhận câu hỏi của bạn. Hệ thống AI đang phân tích dữ liệu, hoặc bạn có thể liên hệ nhanh qua hotline miễn phí 1900 9999 để gặp tổng đài viên trực tiếp hỗ trợ 24/7! 📞';
      }

      setState(() {
        _messages.add({
          'isUser': false,
          'text': response,
          'time': DateTime.now(),
        });
        _isAiTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Hotline calling action with simulated full screen dial overlay
  void _makeHotlineCall() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Calling',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Simulated call duration
            int seconds = 0;
            final timer = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
            
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: StreamBuilder<int>(
                  stream: timer,
                  builder: (context, snap) {
                    seconds = snap.data ?? 0;
                    final minutesStr = (seconds ~/ 60).toString().padLeft(2, '0');
                    final secondsStr = (seconds % 60).toString().padLeft(2, '0');
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 50),
                        Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.15),
                                border: Border.all(color: AppColors.primary, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: AppColors.primary,
                                  size: 50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'GymSync Hotline 24/7',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1900 9999',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 18,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              seconds == 0 ? 'Đang kết nối...' : 'Cuộc gọi đang diễn ra: $minutesStr:$secondsStr',
                              style: TextStyle(
                                color: seconds == 0 ? AppColors.accent : AppColors.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Dial Actions
                        Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CallActionButton(
                                    icon: Icons.volume_up_rounded,
                                    label: 'Loa Ngoài',
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 40),
                                  _CallActionButton(
                                    icon: Icons.mic_off_rounded,
                                    label: 'Tắt Tiếng',
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 40),
                                  _CallActionButton(
                                    icon: Icons.keyboard_hide_rounded,
                                    label: 'Bàn Phím',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent,
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Bug Report Form Logic
  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final db = FirestoreService();

    // Fetch member ID if possible
    String memberId = '';
    String memberName = user?.name ?? 'Khách';
    String email = user?.email ?? '';

    try {
      final member = await db.getMemberByUserId(user?.uid ?? '');
      if (member != null) {
        memberId = member.id;
        memberName = member.name;
      }
    } catch (_) {}

    try {
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user?.uid ?? '',
        'memberId': memberId,
        'memberName': memberName,
        'email': email,
        'title': _titleCtrl.text.trim(),
        'category': _selectedCategory,
        'severity': _selectedSeverity,
        'description': _descCtrl.text.trim(),
        'status': 'pending', // pending, in-progress, resolved
        'emailNotification': _emailNotification,
        'responseMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Show beautiful automatic email sending animation dialog!
      _showEmailSimulationDialog(email);

      // Reset form
      _titleCtrl.clear();
      _descCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi yêu cầu hỗ trợ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showEmailSimulationDialog(String userEmail) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Emulate status phases
            int phase = 0;
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) setState(() => phase = 1); // Encrypting/Saving
            });
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) setState(() => phase = 2); // Dispatching mail
            });
            Future.delayed(const Duration(milliseconds: 4000), () {
              if (mounted) setState(() => phase = 3); // Success
            });

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phase < 3) ...[
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        phase == 0 
                            ? 'Đang lưu yêu cầu vào hệ thống...' 
                            : 'Đang tạo email gửi tự động đến bộ phận CSKH...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hệ thống tự động đồng bộ Gmail hỗ trợ 24/7',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.success,
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Đã Gửi Yêu Cầu Hỗ Trợ!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Hệ thống đã gửi email tự động tới email cá nhân ',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: userEmail,
                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' kèm mã số ticket để bạn tiện theo dõi tiến độ giải quyết!'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Tuyệt vời',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
        );
      },
    );
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
          'Hỗ Trợ Khách Hàng 24/7',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.success,
          labelColor: AppColors.success,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Trò Chuyện AI & Hotline', icon: Icon(Icons.forum_rounded)),
            Tab(text: 'Báo Lỗi & Phản Hồi', icon: Icon(Icons.bug_report_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: AI Chat & Hotline
          _buildChatTab(),
          
          // TAB 2: Bug Report Form
          _buildFormTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Hotline Banner Card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tổng Đài Khẩn Cấp 24/7',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hỗ trợ khẩn cấp thanh toán & kỹ thuật.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _makeHotlineCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text(
                    '1900 9999',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Quick suggestions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Câu hỏi phổ biến:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickQuestions.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(
                          _quickQuestions[i],
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        onPressed: () => _sendChatMessage(_quickQuestions[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Chat Bubble list
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _isAiTyping) {
                  return _buildTypingIndicator();
                }
                
                final msg = _messages[i];
                final isUser = msg['isUser'] as bool;
                final text = msg['text'] as String;
                
                return _buildChatBubble(isUser, text);
              },
            ),
          ),
        ),

        // Input bottom bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi của bạn...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendChatMessage,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.success,
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () => _sendChatMessage(_chatCtrl.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.success.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser 
                ? AppColors.success.withValues(alpha: 0.4) 
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Trợ lý AI đang gõ',
              style: TextStyle(color: AppColors.textHint, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Yêu cầu báo lỗi sẽ được xử lý tối đa trong 2-4 tiếng. Vui lòng mô tả chi tiết lỗi gặp phải.',
                      style: TextStyle(color: AppColors.accent, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Ticket Title
            const Text(
              'Tiêu Đề Sự Cố',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card,
                hintText: 'VD: Không tải được danh mục bài tập, Lỗi nạp tiền...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.success),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề sự cố' : null,
            ),
            const SizedBox(height: 18),

            // Category & Severity row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh Mục',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: [
                              'Lỗi Thanh Toán',
                              'Lỗi Đăng Nhập',
                              'Lịch Tập / PT',
                              'Lỗi Giao Diện App',
                              'Ý Kiến Đóng Góp',
                            ].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mức Độ Khẩn',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSeverity,
                            dropdownColor: AppColors.surface,
                            style: TextStyle(
                              color: _selectedSeverity == 'Cao' 
                                  ? AppColors.error 
                                  : (_selectedSeverity == 'Trung bình' ? AppColors.warning : AppColors.success),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            items: ['Thấp', 'Trung bình', 'Cao'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedSeverity = v ?? _selectedSeverity),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Description
            const Text(
              'Chi Tiết Vấn Đề',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card,
                hintText: 'Mô tả rõ các bước thực hiện dẫn đến lỗi hoặc ý kiến đóng đóng góp cụ thể của bạn...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.success),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng điền chi tiết mô tả lỗi' : null,
            ),
            const SizedBox(height: 14),

            // Email receipt emulation toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nhận email xác nhận tự động',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: _emailNotification,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) => setState(() => _emailNotification = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                icon: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting ? 'ĐANG GỬI...' : 'GỬI YÊU CẦU HỖ TRỢ',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CallActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
