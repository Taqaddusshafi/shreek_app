import 'package:flutter/foundation.dart';
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
      if (kDebugMode) {
        print('🎯 AUTH STATE CHANGED:');
        print('  - Previous authenticated: ${previous?.isAuthenticated}');
        print('  - Next authenticated: ${next.isAuthenticated}');
        print('  - User: ${next.user?.name}');
        print('  - Error: ${next.error}');
        print('  - Loading: ${next.isLoading}');
      }

      // ✅ FIXED: Handle errors with better UX
      if (next.error != null && previous?.error != next.error) {
        if (kDebugMode) {
          print('❌ Showing error: ${next.error}');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'إغلاق',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(authProvider.notifier).clearError();
              },
            ),
          ),
        );
        
        // ✅ AUTO-CLEAR error after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            ref.read(authProvider.notifier).clearError();
          }
        });
      }
      
      // ✅ FIXED: Navigate on successful login with proper checking
      if (next.isAuthenticated && !next.isLoading && next.error == null) {
        if (previous?.isAuthenticated != true) {
          if (kDebugMode) {
            print('✅ LOGIN SUCCESS - Navigating to MainScreen');
            print('  - User: ${next.user?.name}');
            print('  - Email: ${next.user?.email}');
            print('  - Is Driver: ${next.user?.isDriver}');
          }
          
          // ✅ FIXED: Use pushAndRemoveUntil to prevent back navigation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
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
                
                // ✅ APP LOGO AND TITLE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 80,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'مرحباً بك في Halawasl',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'سجل دخولك للمتابعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // ✅ LOGIN METHOD SELECTION
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
                
                // ✅ EMAIL FIELD
                CustomTextField(
                  controller: _emailController,
                  labelText: 'البريد الإلكتروني',
                  hintText: 'أدخل بريدك الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  maxLength: 100,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isLoggingIn || authState.isLoading),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),

                // ✅ PASSWORD FIELD (only for password login)
                if (_loginMethod == 'password') ...[
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock,
                    maxLength: 50,
                    style: const TextStyle(fontSize: 16),
                    enabled: !(_isLoggingIn || authState.isLoading),
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
                
                // ✅ LOGIN BUTTON
                CustomButton(
                  text: _loginMethod == 'password' ? 'تسجيل الدخول' : 'إرسال رمز التحقق',
                  onPressed: (_isLoggingIn || authState.isLoading) ? null : _handleLogin,
                  isLoading: _isLoggingIn || authState.isLoading,
                ),

                // ✅ FORGOT PASSWORD (only for password login)
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
                
                // ✅ REGISTER LINK
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
                
                // ✅ DEBUG INFO (only in debug mode)
                if (kDebugMode) ...[
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug Info:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Auth Loading: ${authState.isLoading}'),
                        Text('Local Loading: $_isLoggingIn'),
                        Text('Authenticated: ${authState.isAuthenticated}'),
                        Text('User: ${authState.user?.name ?? 'null'}'),
                        Text('Error: ${authState.error ?? 'null'}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ENHANCED: Login handler with comprehensive debugging
  Future<void> _handleLogin() async {
    if (_isLoggingIn || !_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('⚠️ Login validation failed or already in progress');
      }
      return;
    }

    if (kDebugMode) {
      print('🔥 LOGIN ATTEMPT STARTED');
      print('  - Email: ${_emailController.text.trim()}');
      print('  - Method: $_loginMethod');
      print('  - Current auth state: ${ref.read(authProvider).isAuthenticated}');
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      bool success = false;
      
      if (_loginMethod == 'password') {
        if (kDebugMode) {
          print('🔑 Attempting password login...');
        }
        
        success = await ref.read(authProvider.notifier).loginWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (kDebugMode) {
          print('🔑 Password login result: $success');
        }
      } else {
        if (kDebugMode) {
          print('📱 Attempting OTP login...');
        }
        
        // Send OTP first
        success = await ref.read(authProvider.notifier).sendLoginOTP(
          email: _emailController.text.trim(),
        );

        if (kDebugMode) {
          print('📱 Send OTP result: $success');
        }

        if (success && mounted) {
          // Show OTP input dialog
          final otpCode = await _showOTPDialog();
          if (otpCode != null && otpCode.isNotEmpty) {
            if (kDebugMode) {
              print('📱 Verifying OTP: $otpCode');
            }
            
            success = await ref.read(authProvider.notifier).loginWithOTP(
              email: _emailController.text.trim(),
              otpCode: otpCode,
            );
            
            if (kDebugMode) {
              print('📱 OTP verification result: $success');
            }
          } else {
            success = false;
            if (kDebugMode) {
              print('📱 OTP dialog cancelled');
            }
          }
        }
      }

      // ✅ ENHANCED: Post-login state checking
      if (mounted) {
        final finalAuthState = ref.read(authProvider);
        if (kDebugMode) {
          print('🎯 FINAL LOGIN STATE:');
          print('  - Success: $success');
          print('  - Authenticated: ${finalAuthState.isAuthenticated}');
          print('  - User: ${finalAuthState.user?.name}');
          print('  - Error: ${finalAuthState.error}');
        }

        // ✅ Show success message if login was successful
        if (success && finalAuthState.isAuthenticated) {
          if (kDebugMode) {
            print('✅ Login successful, showing success message');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل الدخول بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login exception: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
        
        if (kDebugMode) {
          print('🏁 Login attempt completed, local loading set to false');
        }
      }
    }
  }

  // ✅ ENHANCED: OTP Dialog
  Future<String?> _showOTPDialog() async {
    final otpController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'أدخل رمز التحقق',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تم إرسال رمز التحقق إلى\n${_emailController.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) {
                // Auto-submit when 6 digits are entered
                if (value.length == 6) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = otpController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED: Forgot password
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل بريدك الإلكتروني أولاً'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('🔄 Sending forgot password request for: ${_emailController.text}');
    }

    final success = await ref.read(authProvider.notifier).forgotPassword(
      email: _emailController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'فشل في إرسال رابط إعادة التعيين'),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
