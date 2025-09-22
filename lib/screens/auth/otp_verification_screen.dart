import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
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

  @override
  void initState() {
    super.initState();
    // Send OTP automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOTP();
    });
  }

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
          ),
        );
        
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && ref.read(authProvider).error != null) {
            ref.read(authProvider.notifier).clearError();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('التحقق من البريد الإلكتروني'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.email_outlined,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 30),
                const Text(
                  'تحقق من بريدك الإلكتروني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'أرسلنا رمز التحقق إلى\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _otpController,
                  labelText: 'رمز التحقق',
                  hintText: 'أدخل الرمز المكون من 6 أرقام',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.security,
                  maxLength: 6, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
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
                const SizedBox(height: 30),
                CustomButton(
                  text: 'التحقق',
                  onPressed: (_isVerifying || authState.isLoading) 
                      ? null 
                      : _verifyOTP,
                  isLoading: _isVerifying || authState.isLoading,
                  // ✅ REMOVED: No need for style parameter
                ),
                const SizedBox(height: 20),
                
                // ✅ FIXED: Using ElevatedButton for resend with proper styling
                ElevatedButton(
                  onPressed: (_isResending || authState.isLoading) 
                      ? null 
                      : _resendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : const Text(
                          'إعادة إرسال الرمز',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'تخطي التحقق والذهاب لتسجيل الدخول',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
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

  Future<void> _sendOTP() async {
    final success = await ref.read(authProvider.notifier).resendOTP(
      email: widget.email,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).verifyOTP(
        email: widget.email,
        otpCode: _otpController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التحقق من البريد الإلكتروني بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
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

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      await _sendOTP();
      
      // Clear the OTP field to allow new input
      if (mounted) {
        _otpController.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
