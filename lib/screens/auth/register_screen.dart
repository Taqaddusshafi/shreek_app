import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _cityController = TextEditingController();
  
  bool _isDriver = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistering = false;

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
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'أنشئ حسابك في Halawasl',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 30),
                
                CustomTextField(
                  controller: _nameController,
                  labelText: 'الاسم الكامل',
                  hintText: 'أدخل اسمك الكامل',
                  prefixIcon: Icons.person,
                  maxLength: 100, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'الاسم مطلوب';
                    }
                    if (value!.trim().split(' ').length < 2) {
                      return 'أدخل الاسم الأول والأخير على الأقل';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'رقم الهاتف',
                  hintText: 'مثال: 966501234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  maxLength: 15, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'رقم الهاتف مطلوب';
                    }
                    final cleanedPhone = value!.replaceAll(RegExp(r'[^\d]'), '');
                    if (cleanedPhone.length < 10 || cleanedPhone.length > 15) {
                      return 'رقم الهاتف يجب أن يكون بين 10-15 رقم';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                CustomTextField(
                  controller: _nationalityController,
                  labelText: 'الجنسية',
                  hintText: 'أدخل جنسيتك',
                  prefixIcon: Icons.flag,
                  maxLength: 50, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'الجنسية مطلوبة';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                CustomTextField(
                  controller: _cityController,
                  labelText: 'المدينة',
                  hintText: 'أدخل مدينتك',
                  prefixIcon: Icons.location_city,
                  maxLength: 50, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'المدينة مطلوبة';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الحساب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: Text(_isDriver ? 'سائق' : 'راكب'),
                        subtitle: Text(
                          _isDriver 
                              ? 'يمكنك تسجيل رحلات وتوصيل الركاب'
                              : 'يمكنك البحث عن رحلات والانضمام إليها',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _isDriver,
                        onChanged: (value) {
                          setState(() {
                            _isDriver = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'كلمة المرور',
                  hintText: 'أدخل كلمة المرور (6 أحرف على الأقل)',
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
                    if (!RegExp(r'^(?=.*[a-zA-Z])').hasMatch(value)) {
                      return 'كلمة المرور يجب أن تحتوي على حروف';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'تأكيد كلمة المرور',
                  hintText: 'أعد إدخال كلمة المرور',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  maxLength: 50, // ✅ FIXED: Added maxLength
                  style: const TextStyle(fontSize: 16), // ✅ FIXED: Added style
                  suffixIcon: _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  onSuffixIconTap: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'تأكيد كلمة المرور مطلوب';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                CustomButton(
                  text: 'إنشاء الحساب',
                  onPressed: (_isRegistering || authState.isLoading) 
                      ? null 
                      : _register,
                  isLoading: _isRegistering || authState.isLoading,
                  // ✅ REMOVED: No need for style parameter
                ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: (_isRegistering || authState.isLoading) ? null : () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'لديك حساب؟ سجل دخولك',
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

  Future<void> _register() async {
    if (_isRegistering || !_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        nationality: _nationalityController.text.trim(),
        city: _cityController.text.trim(),
        isDriver: _isDriver,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح! تحقق من بريدك الإلكتروني'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
