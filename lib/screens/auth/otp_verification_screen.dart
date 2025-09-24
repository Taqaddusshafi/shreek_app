import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../home/main_screen.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  bool _hasInitialOtpSent = false; // ✅ FIXED: Track if initial OTP was sent
  
  // ✅ Countdown timer for resend button
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // ✅ FIXED: Only send OTP if not already sent
    if (!_hasInitialOtpSent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendInitialOTP();
      });
    }
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (kDebugMode) {
        print('🎯 OTP VERIFICATION AUTH STATE CHANGED:');
        print('  - Previous error: ${previous?.error}');
        print('  - Next error: ${next.error}');
        print('  - Is authenticated: ${next.isAuthenticated}');
      }

      // ✅ Enhanced error handling
      if (next.error != null && previous?.error != next.error) {
        if (kDebugMode) {
          print('❌ OTP verification error: ${next.error}');
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
        
        // Auto-clear error
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            ref.read(authProvider.notifier).clearError();
          }
        });
      }

      // ✅ Handle successful verification and automatic login
      if (next.isAuthenticated && !next.isLoading && next.error == null) {
        if (previous?.isAuthenticated != true) {
          if (kDebugMode) {
            print('✅ OTP VERIFICATION SUCCESS - User authenticated');
            print('  - User: ${next.user?.name}');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التحقق بنجاح! مرحباً بك'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to main screen
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainScreen(),
                ),
                (route) => false,
              );
            }
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('التحقق من البريد الإلكتروني'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // ✅ Enhanced visual header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mark_email_unread,
                        size: 80,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'تحقق من بريدك الإلكتروني',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أرسلنا رمز التحقق المكون من 6 أرقام إلى',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // ✅ FIXED: OTP Input Field using TextFormField
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رمز التحقق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      enabled: !(_isVerifying || authState.isLoading),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: '000000',
                        prefixIcon: Icon(
                          Icons.security,
                          color: AppColors.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.errorColor),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.errorColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        counterText: '',
                      ),
                      onChanged: (value) {
                        setState(() {}); // Update UI for length checks
                        // Auto-verify when 6 digits are entered
                        if (value.length == 6 && !_isVerifying) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_otpController.text.length == 6 && !_isVerifying) {
                              _verifyOTP();
                            }
                          });
                        }
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'رمز التحقق مطلوب';
                        }
                        if (value!.length != 6) {
                          return 'رمز التحقق يجب أن يكون 6 أرقام';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'رمز التحقق يجب أن يكون أرقام فقط';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // ✅ Auto-verification hint
                if (_otpController.text.length < 6) ...[
                  Text(
                    'سيتم التحقق تلقائياً عند إدخال 6 أرقام',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 30),
                
                // ✅ Enhanced verify button
                CustomButton(
                  text: 'التحقق والمتابعة',
                  onPressed: (_isVerifying || authState.isLoading || _otpController.text.length != 6) 
                      ? null 
                      : _verifyOTP,
                  isLoading: _isVerifying || authState.isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // ✅ Enhanced resend button with timer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isResending || authState.isLoading || !_canResend) 
                        ? null 
                        : _resendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canResend 
                          ? Colors.grey.shade200 
                          : Colors.grey.shade100,
                      foregroundColor: _canResend 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _canResend 
                              ? AppColors.primaryColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: _isResending 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('جاري الإرسال...'),
                            ],
                          )
                        : Text(
                            _canResend 
                                ? 'إعادة إرسال الرمز'
                                : 'إعادة الإرسال خلال $_resendCountdown ثانية',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
                
                // ✅ Enhanced help section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لم تستلم الرمز؟',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• تحقق من صندوق البريد الوارد والرسائل المهملة\n• تأكد من صحة عنوان البريد الإلكتروني\n• قد يستغرق الوصول بضع دقائق',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                
                // ✅ Enhanced navigation options
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 20,
                      width: 1,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _showChangeEmailDialog();
                        },
                        child: const Text(
                          'تغيير البريد',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // ✅ Debug info (only in debug mode)
                if (kDebugMode) ...[
                  const SizedBox(height: 20),
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
                        Text('Email: ${widget.email}'),
                        Text('Auth Loading: ${authState.isLoading}'),
                        Text('Local Verifying: $_isVerifying'),
                        Text('Local Resending: $_isResending'),
                        Text('Can Resend: $_canResend'),
                        Text('Countdown: $_resendCountdown'),
                        Text('OTP Length: ${_otpController.text.length}'),
                        Text('Initial OTP Sent: $_hasInitialOtpSent'),
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

  // ✅ Start resend countdown timer
  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  // ✅ FIXED: Send initial OTP with duplicate prevention
  Future<void> _sendInitialOTP() async {
    if (_hasInitialOtpSent || _isResending) {
      if (kDebugMode) {
        print('⚠️ Initial OTP already sent or currently sending. Skipping.');
      }
      return;
    }

    if (kDebugMode) {
      print('📱 Sending initial OTP to: ${widget.email}');
    }

    _hasInitialOtpSent = true; // ✅ Mark as sent to prevent duplicates

    try {
      setState(() {
        _isResending = true;
      });

      final success = await ref.read(authProvider.notifier).resendOTP(
        email: widget.email,
      );

      if (mounted) {
        if (success) {
          if (kDebugMode) {
            print('✅ Initial OTP sent successfully');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          if (kDebugMode) {
            print('❌ Failed to send initial OTP');
          }
          _hasInitialOtpSent = false; // Reset flag on failure
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending initial OTP: $e');
      }
      _hasInitialOtpSent = false; // Reset flag on error
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال رمز التحقق: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ✅ FIXED: Verify OTP with better null safety and error handling
  Future<void> _verifyOTP() async {
    if (_isVerifying || !mounted) return;

    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('⚠️ OTP validation failed');
      }
      return;
    }

    final otpCode = _otpController.text.trim();
    if (otpCode.isEmpty || otpCode.length != 6) {
      if (kDebugMode) {
        print('⚠️ Invalid OTP code: "$otpCode"');
      }
      return;
    }

    if (kDebugMode) {
      print('🔍 VERIFYING OTP');
      print('  - Email: ${widget.email}');
      print('  - OTP: $otpCode');
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Clear any previous errors
      ref.read(authProvider.notifier).clearError();
      
      final success = await ref.read(authProvider.notifier).verifyOTP(
        email: widget.email,
        otpCode: otpCode,
      );

      if (!mounted) return;

      if (kDebugMode) {
        print('📧 OTP verification result: $success');
      }

      if (success) {
        if (kDebugMode) {
          print('✅ OTP verification successful');
        }

        // Check if user is now authenticated (auto-login after verification)
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          if (kDebugMode) {
            print('🎉 User is now authenticated, will navigate to MainScreen');
          }
          // Navigation handled by the listener
        } else {
          if (kDebugMode) {
            print('📝 OTP verified but user not authenticated, going to login');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التحقق من البريد الإلكتروني بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print('❌ OTP verification failed');
          final error = ref.read(authProvider).error;
          print('  - Error: $error');
        }
        
        // Clear the OTP field on failure
        _otpController.clear();
        
        // Vibrate on error (if available)
        try {
          HapticFeedback.vibrate();
        } catch (e) {
          // Ignore haptic feedback errors
        }

        // Show error if not handled by listener
        final currentError = ref.read(authProvider).error;
        if (currentError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رمز التحقق غير صحيح. يرجى المحاولة مرة أخرى'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OTP verification exception: $e');
        print('❌ Exception type: ${e.runtimeType}');
      }
      
      if (mounted) {
        _otpController.clear();
        
        // Show a more user-friendly error message
        String errorMessage = 'حدث خطأ غير متوقع';
        if (e.toString().contains('Null') || e.toString().contains('parsing')) {
          errorMessage = 'خطأ في الاتصال مع الخادم. يرجى المحاولة مرة أخرى';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _verifyOTP(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ✅ FIXED: Resend OTP with better duplicate prevention
  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    if (kDebugMode) {
      print('🔄 Resending OTP to: ${widget.email}');
    }

    setState(() {
      _isResending = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).resendOTP(
        email: widget.email,
      );

      if (mounted) {
        if (success) {
          if (kDebugMode) {
            print('✅ OTP resent successfully');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة إرسال رمز التحقق'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Clear the OTP field and restart timer
          _otpController.clear();
          _startResendTimer();
        } else {
          if (kDebugMode) {
            print('❌ Failed to resend OTP');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resending OTP: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إعادة إرسال الرمز: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ✅ Change email dialog
  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تغيير البريد الإلكتروني'),
        content: const Text(
          'للتحقق من بريد إلكتروني مختلف، يرجى العودة إلى شاشة التسجيل وإدخال البريد الصحيح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('العودة'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }
}
