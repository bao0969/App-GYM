import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
    if (result == RegisterResult.needsOtp) {
      context.go(
        '${AppRouter.otp}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}',
      );
      return;
    }

    if (result == RegisterResult.success) {
      context.go(AppRouter.login);
      return;
    }

    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.login);
            }
          },
        ),
        title: const Text(
          'Tao Tai Khoan',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dang Ky GymSync',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Dang ky tai khoan hoi vien moi',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.memberColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.memberColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.memberColor,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tai khoan dang ky moi se duoc tao voi vai tro Hoi Vien',
                            style: TextStyle(
                              color: AppColors.memberColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Ho va Ten',
                          hint: 'Nguyen Van A',
                          controller: _nameCtrl,
                          prefix: const Icon(
                            Icons.person_outline,
                            color: AppColors.textHint,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Nhap ho va ten' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Email',
                          hint: 'example@email.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefix: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textHint,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Nhap email';
                            }
                            if (!v.contains('@')) {
                              return 'Email khong hop le';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'So Dien Thoai',
                          hint: '0909 xxx xxx',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          prefix: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.textHint,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nhap so dien thoai'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Mat Khau',
                          hint: 'Toi thieu 6 ky tu',
                          controller: _passCtrl,
                          isPassword: true,
                          prefix: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textHint,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Nhap mat khau';
                            }
                            if (v.length < 6) {
                              return 'Toi thieu 6 ky tu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Xac Nhan Mat Khau',
                          hint: 'Nhap lai mat khau',
                          controller: _confirmCtrl,
                          isPassword: true,
                          prefix: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textHint,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v != _passCtrl.text) {
                              return 'Mat khau khong khop';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    text: 'Dang Ky Hoi Vien',
                    onPressed: _register,
                    isLoading: _isLoading,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.memberColor.withValues(alpha: 0.8),
                        AppColors.memberColor,
                      ],
                    ),
                    icon: const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRouter.login),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Da co tai khoan? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Dang Nhap',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
