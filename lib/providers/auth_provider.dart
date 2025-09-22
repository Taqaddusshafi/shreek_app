import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'auth_provider.g.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isDriver => user?.isDriver ?? false;
  bool get isPassenger => user?.isPassenger ?? false;
  
  // ✅ FIXED: Add convenience getters to AuthState
  String get currentUserName => user?.name ?? '';
  String get currentUserEmail => user?.email ?? '';
  String get currentUserPhone => user?.phone ?? '';
  bool get isLoggedIn => isAuthenticated;
  bool get hasError => error != null;
  
  // ✅ NEW: Additional user info getters
  String get currentUserCity => user?.city ?? '';
  String get currentUserNationality => user?.nationality ?? '';
  bool get isPhoneVerified => user?.phoneVerified ?? false;
  bool get isEmailVerified => user?.emailVerified ?? false;
  String? get profileImageUrl => user?.profileImageUrl;
  DateTime? get lastLoginAt => user?.lastLoginAt;
}

// Auth Provider
@riverpod
class Auth extends _$Auth {
  late DioClient _dioClient;
  late SharedPreferences _prefs;

  @override
  AuthState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(_prefs);
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    final token = _prefs.getString('jwt_token');
    if (token != null) {
      await getCurrentUser();
    }
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String? error) {
    state = state.copyWith(error: error);
  }

  // ✅ NEW: Updated register method for new API
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String nationality,
    required String city,
    required bool isDriver,
  }) async {
    if (state.isLoading) {
      if (kDebugMode) {
        print('⚠️ Registration already in progress, ignoring call');
      }
      return false;
    }

    if (kDebugMode) {
      print('🔥 Starting registration for: $email');
    }
    
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'nationality': nationality,
          'city': city,
          'isDriver': isDriver,
        },
      );

      if (kDebugMode) {
        print('📡 Registration response: ${response.statusCode}');
        print('📄 Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Registration successful');
        }
        _setLoading(false);
        return true;
      }
      
      final errorMessage = response.data['message'] ?? 'فشل في إنشاء الحساب';
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Registration DioError: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response: ${e.response?.data}');
      }
      
      String errorMessage = 'حدث خطأ في الاتصال';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'انتهت مهلة الاتصال';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة استلام البيانات';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'خطأ في الاتصال بالخادم';
      } else if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? 'خطأ من الخادم';
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected registration error: $e');
      }
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Email OTP verification
  Future<bool> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.verifyOTP,
        data: {
          'email': email,
          'otpCode': otpCode,
        },
      );

      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        final user = User.fromJson(userData);
        
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }

      _setError(response.data['message'] ?? 'رمز التحقق غير صحيح');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في التحقق من الرمز');
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Resend OTP
  Future<bool> resendOTP({required String email}) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.resendOTP,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }

      _setError(response.data['message'] ?? 'فشل في إرسال رمز التحقق');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في إرسال رمز التحقق');
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Login with password
  Future<bool> loginWithPassword({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) {
      if (kDebugMode) {
        print('⚠️ Login already in progress');
      }
      return false;
    }
    
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'loginMethod': 'password',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];
        final userData = data['user'];

        await _prefs.setString('jwt_token', token);
        final user = User.fromJson(userData);
        
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      
      _setError(response.data['message'] ?? 'فشل في تسجيل الدخول');
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';
      
      if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'خطأ في الاتصال بالخادم';
      } else if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? 'خطأ من الخادم';
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Send login OTP
  Future<bool> sendLoginOTP({required String email}) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.sendLoginOTP,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }

      _setError(response.data['message'] ?? 'فشل في إرسال رمز التحقق');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في إرسال رمز التحقق');
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Login with OTP
  Future<bool> loginWithOTP({
    required String email,
    required String otpCode,
  }) async {
    if (state.isLoading) return false;
    
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'loginMethod': 'otp',
          'otpCode': otpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];
        final userData = data['user'];

        await _prefs.setString('jwt_token', token);
        final user = User.fromJson(userData);
        
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      
      _setError(response.data['message'] ?? 'فشل في تسجيل الدخول');
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';
      
      if (e.response != null) {
        errorMessage = e.response!.data['message'] ?? 'خطأ من الخادم';
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Phone verification
  Future<bool> sendPhoneOTP({required String phone}) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.sendPhoneOTP,
        data: {'phone': phone},
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }

      _setError(response.data['message'] ?? 'فشل في إرسال رمز التحقق');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في إرسال رمز التحقق');
      _setLoading(false);
      return false;
    }
  }

  // ✅ FIXED: Null-safe phone verification
  Future<bool> verifyPhoneOTP({
    required String phone,
    required String otpCode,
  }) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.verifyPhoneOTP,
        data: {
          'phone': phone,
          'otpCode': otpCode,
        },
      );

      if (response.statusCode == 200) {
        // ✅ FIXED: Update user's phone verification status with null check
        final currentUser = state.user;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(phoneVerified: true);
          state = state.copyWith(user: updatedUser, isLoading: false);
        } else {
          // If no user in state, just update loading
          _setLoading(false);
        }
        return true;
      }

      _setError(response.data['message'] ?? 'رمز التحقق غير صحيح');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في التحقق من الرمز');
      _setLoading(false);
      return false;
    }
  }

  Future<void> getCurrentUser() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.me);
      
      if (response.statusCode == 200) {
        final userData = response.data['data']['user'] ?? response.data['user'];
        final user = User.fromJson(userData);
        state = state.copyWith(user: user);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
      }
    }
  }

  // ✅ FIXED: Null-safe profile update
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? nationality,
    String? currentAddress,
    String? city,
    String? stateValue, // Changed from 'state' to avoid confusion
    String? postalCode,
    String? country, required String firstName, required String lastName, String? phone, String? gender,
  }) async {
    if (state.isLoading) {
      if (kDebugMode) {
        print('⚠️ Profile update already in progress');
      }
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.put(
        ApiConstants.profile,
        data: {
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (nationality != null) 'nationality': nationality,
          if (currentAddress != null) 'currentAddress': currentAddress,
          if (city != null) 'city': city,
          if (stateValue != null) 'state': stateValue,
          if (postalCode != null) 'postalCode': postalCode,
          if (country != null) 'country': country,
        },
      );

      if (response.statusCode == 200) {
        final userData = response.data['data']['user'] ?? response.data['user'];
        final user = User.fromJson(userData);
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      
      _setError(response.data['message'] ?? 'فشل في تحديث الملف الشخصي');
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'حدث خطأ في الاتصال');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isLoading) {
      if (kDebugMode) {
        print('⚠️ Password change already in progress');
      }
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }
      
      _setError(response.data['message'] ?? 'فشل في تغيير كلمة المرور');
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'حدث خطأ في الاتصال');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Forgot password flow
  Future<bool> forgotPassword({required String email}) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }

      _setError(response.data['message'] ?? 'فشل في إرسال رمز إعادة تعيين كلمة المرور');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في إرسال الرمز');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyResetOTP({
    required String email,
    required String otpCode,
  }) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.verifyResetOTP,
        data: {
          'email': email,
          'otpCode': otpCode,
        },
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }

      _setError(response.data['message'] ?? 'رمز التحقق غير صحيح');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'خطأ في التحقق من الرمز');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (state.isLoading) return false;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return true;
      }

      _setError(response.data['message'] ?? 'فشل في إعادة تعيين كلمة المرور');
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _setError(e.response?.data['message'] ?? 'حدث خطأ');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiConstants.logout);
    } catch (e) {
      // Handle logout error silently
    }
    await _prefs.clear();
    state = AuthState();
  }

  void clearError() {
    if (state.error != null) {
      _setError(null);
    }
  }

  // ✅ NEW: Safe user update method
  void updateUserInState(User updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  // ✅ NEW: Refresh user data
  Future<void> refreshUser() async {
    if (state.isAuthenticated) {
      await getCurrentUser();
    }
  }

  // ✅ NEW: Check if user needs verification
  bool get needsEmailVerification => 
      state.isAuthenticated && !state.isEmailVerified;
      
  bool get needsPhoneVerification => 
      state.isAuthenticated && !state.isPhoneVerified;
}

// Convenience providers
final currentUserProvider = Provider<User?>((ref) => ref.watch(authProvider).user);
final isAuthenticatedProvider = Provider<bool>((ref) => ref.watch(authProvider).isAuthenticated);
final isDriverProvider = Provider<bool>((ref) => ref.watch(authProvider).isDriver);
final isPassengerProvider = Provider<bool>((ref) => ref.watch(authProvider).isPassenger);

// ✅ FIXED: Updated convenience providers to use state getters
final currentUserNameProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserName);
final currentUserEmailProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserEmail);
final currentUserPhoneProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserPhone);
final currentUserCityProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserCity);
final currentUserNationalityProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserNationality);

final authLoadingProvider = Provider<bool>((ref) => ref.watch(authProvider).isLoading);
final authErrorProvider = Provider<String?>((ref) => ref.watch(authProvider).error);
final hasAuthErrorProvider = Provider<bool>((ref) => ref.watch(authProvider).hasError);

// ✅ NEW: Verification status providers
final isEmailVerifiedProvider = Provider<bool>((ref) => ref.watch(authProvider).isEmailVerified);
final isPhoneVerifiedProvider = Provider<bool>((ref) => ref.watch(authProvider).isPhoneVerified);
final needsEmailVerificationProvider = Provider<bool>((ref) => ref.watch(authProvider.notifier).needsEmailVerification);
final needsPhoneVerificationProvider = Provider<bool>((ref) => ref.watch(authProvider.notifier).needsPhoneVerification);

// ✅ NEW: Profile info providers
final profileImageUrlProvider = Provider<String?>((ref) => ref.watch(authProvider).profileImageUrl);
final lastLoginProvider = Provider<DateTime?>((ref) => ref.watch(authProvider).lastLoginAt);
