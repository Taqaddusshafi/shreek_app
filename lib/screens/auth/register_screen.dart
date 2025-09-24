import 'package:flutter/foundation.dart';
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
  String _selectedGender = 'male'; // ✅ Use 'male' as default

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (kDebugMode) {
        print('🎯 REGISTRATION AUTH STATE CHANGED:');
        print('  - Previous error: ${previous?.error}');
        print('  - Next error: ${next.error}');
        print('  - Loading: ${next.isLoading}');
      }

      // ✅ Enhanced error handling
      if (next.error != null && previous?.error != next.error) {
        if (kDebugMode) {
          print('❌ Registration error: ${next.error}');
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
        
        // Auto-clear error after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
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
                const SizedBox(height: 20),
                
                // ✅ Enhanced title section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'أنشئ حسابك في Shareek',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'املأ البيانات التالية لإنشاء حسابك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // ✅ PERSONAL INFORMATION SECTION
                _buildSectionHeader('المعلومات الشخصية', Icons.person),
                
                CustomTextField(
                  controller: _nameController,
                  labelText: 'الاسم الكامل',
                  hintText: 'أدخل اسمك الكامل (الأول والأخير)',
                  prefixIcon: Icons.person,
                  maxLength: 100,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'الاسم مطلوب';
                    }
                    final nameParts = value!.trim().split(' ');
                    if (nameParts.length < 2) {
                      return 'أدخل الاسم الأول والأخير على الأقل';
                    }
                    if (value.trim().length < 3) {
                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'البريد الإلكتروني',
                  hintText: 'example@domain.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  maxLength: 100,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
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
                
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'رقم الهاتف',
                  hintText: 'مثال: +966501234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  maxLength: 15,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'رقم الهاتف مطلوب';
                    }
                    final cleanedPhone = value!.replaceAll(RegExp(r'[^\d+]'), '');
                    if (cleanedPhone.length < 10 || cleanedPhone.length > 15) {
                      return 'رقم الهاتف يجب أن يكون بين 10-15 رقم';
                    }
                    return null;
                  },
                ),

                // ✅ FIXED: Gender Selection with proper validation
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'الجنس',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          ' *',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('ذكر'),
                              value: 'male',
                              groupValue: _selectedGender,
                              onChanged: (_isRegistering || authState.isLoading) ? null : (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                              activeColor: AppColors.primaryColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('أنثى'),
                              value: 'female',
                              groupValue: _selectedGender,
                              onChanged: (_isRegistering || authState.isLoading) ? null : (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                              activeColor: AppColors.primaryColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                
                // ✅ LOCATION SECTION
                _buildSectionHeader('معلومات المكان', Icons.location_on),

                CustomTextField(
                  controller: _nationalityController,
                  labelText: 'الجنسية',
                  hintText: 'أدخل جنسيتك',
                  prefixIcon: Icons.flag,
                  maxLength: 50,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'الجنسية مطلوبة';
                    }
                    if (value!.trim().length < 2) {
                      return 'الجنسية يجب أن تكون حرفين على الأقل';
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
                  maxLength: 50,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'المدينة مطلوبة';
                    }
                    if (value!.trim().length < 2) {
                      return 'اسم المدينة يجب أن يكون حرفين على الأقل';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                // ✅ Enhanced account type selection
                _buildSectionHeader('نوع الحساب', Icons.account_circle),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          _isDriver ? 'حساب سائق' : 'حساب راكب',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _isDriver 
                                ? '• يمكنك تسجيل رحلات جديدة\n• استقبال طلبات الحجز\n• كسب المال من الرحلات'
                                : '• البحث عن رحلات متاحة\n• حجز مقاعد في الرحلات\n• التواصل مع السائقين',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        value: _isDriver,
                        onChanged: (_isRegistering || authState.isLoading) ? null : (value) {
                          setState(() {
                            _isDriver = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // ✅ PASSWORD SECTION
                _buildSectionHeader('كلمة المرور', Icons.lock),
                
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'كلمة المرور',
                  hintText: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock,
                  maxLength: 50,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
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
                    if (value.length > 50) {
                      return 'كلمة المرور طويلة جداً';
                    }
                    // Check for at least one letter
                    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                      return 'كلمة المرور يجب أن تحتوي على حرف واحد على الأقل';
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
                  maxLength: 50,
                  style: const TextStyle(fontSize: 16),
                  enabled: !(_isRegistering || authState.isLoading),
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
                
                // ✅ Enhanced register button
                CustomButton(
                  text: 'إنشاء الحساب',
                  onPressed: (_isRegistering || authState.isLoading) 
                      ? null 
                      : _register,
                  isLoading: _isRegistering || authState.isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // ✅ Enhanced login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لديك حساب بالفعل؟ ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: (_isRegistering || authState.isLoading) ? null : () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'سجل دخولك',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // ✅ Debug info (only in debug mode)
                if (kDebugMode) ...[
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
                        Text('Local Loading: $_isRegistering'),
                        Text('Selected Gender: $_selectedGender'),
                        Text('Is Driver: $_isDriver'),
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

  // ✅ Helper: Section header widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Registration method with gender included
  Future<void> _register() async {
    // ✅ Added gender validation
    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الجنس'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isRegistering || !_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('⚠️ Registration validation failed or already in progress');
      }
      return;
    }

    if (kDebugMode) {
      print('🔥 REGISTRATION ATTEMPT STARTED');
      print('  - Name: ${_nameController.text.trim()}');
      print('  - Email: ${_emailController.text.trim()}');
      print('  - Phone: ${_phoneController.text.trim()}');
      print('  - Gender: $_selectedGender');
      print('  - City: ${_cityController.text.trim()}');
      print('  - Nationality: ${_nationalityController.text.trim()}');
      print('  - Is Driver: $_isDriver');
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // ✅ FIXED: Include gender in registration call
      final success = await ref.read(authProvider.notifier).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        nationality: _nationalityController.text.trim(),
        city: _cityController.text.trim(),
        isDriver: _isDriver,
        gender: _selectedGender, // ✅ FIXED: Include gender
      );

      if (kDebugMode) {
        print('📡 Registration result: $success');
      }

      if (success && mounted) {
        if (kDebugMode) {
          print('✅ Registration successful, showing success message');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب بنجاح! تحقق من بريدك الإلكتروني'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ✅ Navigate to OTP verification
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print('❌ Registration failed');
          final authState = ref.read(authProvider);
          print('  - Error: ${authState.error}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Registration exception: $e');
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
          _isRegistering = false;
        });
        
        if (kDebugMode) {
          print('🏁 Registration attempt completed');
        }
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
