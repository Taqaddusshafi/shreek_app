import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  String _loginMethod = 'password'; // password or otp

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'إغلاق',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && ref.read(authProvider).error != null) {
            ref.read(authProvider.notifier).clearError();
          }
        });
      }
      
      // Navigate on successful login
      if (next.isAuthenticated && (previous?.isAuthenticated != true)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                const Icon(
                  Icons.directions_car,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 20),
                const Text(
                  'مرحباً بك في Halawasl',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'سجل دخولك للمتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Login method selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'password'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'password' 
                                  ? AppColors.primaryColor 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'كلمة المرور',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _loginMethod == 'password' 
                                    ? Colors.white 
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMethod = 'otp'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMethod == 'otp' 
                                  ? AppColors.primaryColor 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'رمز التحقق',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _loginMethod == 'otp' 
                                    ? Colors.white 
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'البريد الإلكتروني',
                  hintText: 'أدخل بريدك الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  maxLength: 100, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!value!.contains('@')) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),

                if (_loginMethod == 'password') ...[
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock,
                    maxLength: 50, // ✅ FIXED: Added maxLength
                    style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                    suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    onSuffixIconTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'كلمة المرور مطلوبة';
                      }
                      if (value!.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 30),
                CustomButton(
                  text: _loginMethod == 'password' ? 'تسجيل الدخول' : 'إرسال رمز التحقق',
                  onPressed: (_isLoggingIn || authState.isLoading) ? null : _handleLogin,
                  isLoading: _isLoggingIn || authState.isLoading,
                  // ✅ REMOVED: No need for style parameter anymore
                ),

                if (_loginMethod == 'password') ...[
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: (_isLoggingIn || authState.isLoading) ? null : _forgotPassword,
                    child: const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                TextButton(
                  onPressed: (_isLoggingIn || authState.isLoading) ? null : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'ليس لديك حساب؟ سجل الآن',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      bool success;
      
      if (_loginMethod == 'password') {
        success = await ref.read(authProvider.notifier).loginWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Send OTP first
        success = await ref.read(authProvider.notifier).sendLoginOTP(
          email: _emailController.text.trim(),
        );

        if (success && mounted) {
          // Show OTP input dialog
          final otpCode = await _showOTPDialog();
          if (otpCode != null && otpCode.isNotEmpty) {
            success = await ref.read(authProvider.notifier).loginWithOTP(
              email: _emailController.text.trim(),
              otpCode: otpCode,
            );
          } else {
            success = false;
          }
        }
      }

      // Navigation is handled in the listener
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<String?> _showOTPDialog() async {
    final otpController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('أدخل رمز التحقق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تم إرسال رمز التحقق إلى ${_emailController.text}'),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'أدخل الرمز المكون من 6 أرقام',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(otpController.text.trim()),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل بريدك الإلكتروني أولاً'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).forgotPassword(
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
