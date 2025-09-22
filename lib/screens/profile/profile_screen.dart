import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _gender;
  bool _isInitialized = false;
  bool _isUpdating = false;

  void _initializeUserData() {
    if (_isInitialized) return;
    
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _firstNameController.text = _getUserFirstName(user);
      _lastNameController.text = _getUserLastName(user);
      _phoneController.text = _getUserPhone(user);
      _gender = _getUserGender(user);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = ref.watch(currentUserProvider);

    if (user != null) {
      _initializeUserData();
    }

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ref.read(authProvider.notifier).clearError();
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _getUserProfileImage(user),
                            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                            child: _getUserProfileImage(user) == null
                                ? Text(
                                    _getUserInitial(user),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getUserFullName(user),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getUserEmail(user),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getUserRole(user),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          if (_getUserRating(user) != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getUserRating(user)!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_getUserTotalRides(user)} رحلة)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Profile Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _firstNameController,
                            labelText: 'الاسم الأول',
                            prefixIcon: Icons.person,
                            enabled: !(_isUpdating || authState.isLoading),
                            validator: (v) => v == null || v.isEmpty ? 'الاسم الأول مطلوب' : null,
                            maxLength: 50,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _lastNameController,
                            labelText: 'الاسم الأخير',
                            prefixIcon: Icons.person_outline,
                            enabled: !(_isUpdating || authState.isLoading),
                            validator: (v) => v == null || v.isEmpty ? 'الاسم الأخير مطلوب' : null,
                            maxLength: 50,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _phoneController,
                            labelText: 'رقم الهاتف',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            enabled: !(_isUpdating || authState.isLoading),
                            maxLength: 15,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          
                          // Gender Selection
                          const Text(
                            'الجنس',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('ذكر'),
                                  value: 'male',
                                  groupValue: _gender,
                                  onChanged: (_isUpdating || authState.isLoading) 
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _gender = value;
                                          });
                                        },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('أنثى'),
                                  value: 'female',
                                  groupValue: _gender,
                                  onChanged: (_isUpdating || authState.isLoading) 
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _gender = value;
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          CustomButton(
                            text: 'تحديث الملف الشخصي',
                            isLoading: _isUpdating || authState.isLoading,
                            onPressed: (_isUpdating || authState.isLoading) 
                                ? null 
                                : _updateProfile,
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'تغيير كلمة المرور',
                            backgroundColor: Colors.blue,
                            onPressed: (_isUpdating || authState.isLoading)
                                ? null 
                                : _changePassword,
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'تسجيل خروج',
                            backgroundColor: AppColors.errorColor,
                            onPressed: (_isUpdating || authState.isLoading) 
                                ? null 
                                : _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ✅ Helper methods for safe user property access
  ImageProvider? _getUserProfileImage(dynamic user) {
    try {
      final image = user?.profileImage ?? user?.profile_image ?? user?.avatar;
      return image != null ? NetworkImage(image) : null;
    } catch (e) {
      return null;
    }
  }

  String _getUserInitial(dynamic user) {
    try {
      final firstName = user?.firstName ?? user?.first_name ?? user?.name ?? '';
      return firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
    } catch (e) {
      return 'U';
    }
  }

  String _getUserFirstName(dynamic user) {
    try {
      return user?.firstName ?? user?.first_name ?? user?.name?.split(' ')[0] ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getUserLastName(dynamic user) {
    try {
      return user?.lastName ?? user?.last_name ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getUserPhone(dynamic user) {
    try {
      return user?.phone ?? user?.phoneNumber ?? user?.mobile ?? '';
    } catch (e) {
      return '';
    }
  }

  String? _getUserGender(dynamic user) {
    try {
      return user?.gender ?? user?.sex;
    } catch (e) {
      return null;
    }
  }

  String _getUserFullName(dynamic user) {
    try {
      if (user?.fullName != null) return user.fullName;
      if (user?.full_name != null) return user.full_name;
      
      final firstName = user?.firstName ?? user?.first_name ?? '';
      final lastName = user?.lastName ?? user?.last_name ?? '';
      
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        return '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        return firstName;
      } else if (user?.name != null) {
        return user.name;
      }
      
      return 'مستخدم';
    } catch (e) {
      return 'مستخدم';
    }
  }

  String _getUserEmail(dynamic user) {
    try {
      return user?.email ?? user?.emailAddress ?? 'بريد إلكتروني';
    } catch (e) {
      return 'بريد إلكتروني';
    }
  }

  double? _getUserRating(dynamic user) {
    try {
      final rating = user?.rating;
      return rating != null ? rating.toDouble() : null;
    } catch (e) {
      return null;
    }
  }

  int _getUserTotalRides(dynamic user) {
    try {
      return user?.totalRides ?? user?.total_rides ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _getUserRole(dynamic user) {
    try {
      final isDriver = user?.isDriver ?? user?.is_driver ?? false;
      return isDriver ? 'سائق' : 'راكب';
    } catch (e) {
      return 'راكب';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || _isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        gender: _gender,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الملف الشخصي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChangePasswordDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _isUpdating = true;
      });

      try {
        final success = await ref.read(authProvider.notifier).changePassword(
          currentPassword: result['current']!,
          newPassword: result['new']!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تغيير كلمة المرور بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تغيير كلمة المرور: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isUpdating = true;
      });

      try {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تسجيل الخروج: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();
  final _formKeyPwd = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تغيير كلمة المرور'),
      content: Form(
        key: _formKeyPwd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _currentPwdController,
              labelText: 'كلمة المرور الحالية',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              enabled: !_isLoading,
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              maxLength: 50,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _newPwdController,
              labelText: 'كلمة المرور الجديدة',
              obscureText: true,
              prefixIcon: Icons.lock,
              enabled: !_isLoading,
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
              maxLength: 50,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPwdController,
              labelText: 'تأكيد كلمة المرور الجديدة',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              enabled: !_isLoading,
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (v != _newPwdController.text) return 'كلمة المرور غير متطابقة';
                return null;
              },
              maxLength: 50,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitPasswordChange,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تغيير'),
        ),
      ],
    );
  }

  void _submitPasswordChange() {
    if (!_formKeyPwd.currentState!.validate()) return;
    
    Navigator.of(context).pop({
      'current': _currentPwdController.text,
      'new': _newPwdController.text,
    });
  }

  @override
  void dispose() {
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }
}
