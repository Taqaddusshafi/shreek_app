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
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isDriver => user?.isDriver ?? false;
  bool get isPassenger => user?.isPassenger ?? false;
  
  // Convenience getters
  String get currentUserName => user?.name ?? '';
  String get currentUserEmail => user?.email ?? '';
  String get currentUserPhone => user?.phone ?? '';
  bool get isLoggedIn => isAuthenticated;
  bool get hasError => error != null;
  
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
    
    // ✅ FIXED: Initialize auth check immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus();
    });
    
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    final token = _prefs.getString('jwt_token');
    if (kDebugMode) {
      print('🔍 Checking auth status. Token exists: ${token != null}');
    }
    
    if (token != null) {
      await getCurrentUser();
    }
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
    if (kDebugMode) {
      print('⏳ Auth loading: $loading');
    }
  }

  void _setError(String? error) {
    state = state.copyWith(error: error);
    if (kDebugMode && error != null) {
      print('❌ Auth error: $error');
    }
  }

  // ✅ FIXED: Login with password - enhanced debugging
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
    
    if (kDebugMode) {
      print('🚀 Starting login for: $email');
    }
    
    _setLoading(true);
    _setError(null);

    try {
      if (kDebugMode) {
        print('📡 Making login request to: ${ApiConstants.login}');
      }

      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'loginMethod': 'password',
        },
      );

      if (kDebugMode) {
        print('📈 Login response status: ${response.statusCode}');
        print('📄 Login response data: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ FIXED: Handle different response structures
        final responseData = response.data;
        
        String? token;
        Map<String, dynamic>? userData;
        
        // Try different response structures
        if (responseData['data'] != null) {
          final data = responseData['data'];
          token = data['token'] ?? data['accessToken'] ?? data['authToken'];
          userData = data['user'];
        } else {
          token = responseData['token'] ?? responseData['accessToken'] ?? responseData['authToken'];
          userData = responseData['user'];
        }

        if (kDebugMode) {
          print('🔑 Token received: ${token != null}');
          print('👤 User data received: ${userData != null}');
        }

        if (token != null && userData != null) {
          // Save token
          await _prefs.setString('jwt_token', token);
          
          // Create user object
          final user = User.fromJson(userData);
          
          if (kDebugMode) {
            print('✅ User created: ${user.name} (${user.email})');
            print('👨‍💼 Is driver: ${user.isDriver}');
          }
          
          // Update state
          state = state.copyWith(user: user, isLoading: false);
          
          if (kDebugMode) {
            print('🎉 Login successful! User authenticated: ${state.isAuthenticated}');
          }
          
          return true;
        } else {
          if (kDebugMode) {
            print('❌ Missing token or user data in response');
          }
          _setError('استجابة خادم غير صحيحة');
          _setLoading(false);
          return false;
        }
      }
      
      final errorMessage = response.data['message'] ?? 'فشل في تسجيل الدخول';
      if (kDebugMode) {
        print('❌ Login failed with message: $errorMessage');
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Login DioException: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }
      
      String errorMessage = 'حدث خطأ في الاتصال';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'انتهت مهلة الاتصال';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة استلام البيانات';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'خطأ في الاتصال بالخادم';
      } else if (e.response != null) {
        try {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message'] as String? ?? 'خطأ من الخادم';
          } else {
            errorMessage = 'خطأ من الخادم';
          }
        } catch (parseError) {
          errorMessage = 'خطأ من الخادم';
        }
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected login error: $e');
        print('❌ Stack trace: $e');
      }
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ FIXED: Enhanced getCurrentUser
  Future<void> getCurrentUser() async {
    if (kDebugMode) {
      print('👤 Getting current user...');
    }

    try {
      final response = await _dioClient.dio.get(ApiConstants.me);
      
      if (kDebugMode) {
        print('👤 getCurrentUser response: ${response.statusCode}');
        print('👤 getCurrentUser data: ${response.data}');
      }
      
      if (response.statusCode == 200) {
        // Handle different response structures
        final responseData = response.data;
        Map<String, dynamic>? userData;
        
        if (responseData['data'] != null) {
          userData = responseData['data']['user'] ?? responseData['data'];
        } else {
          userData = responseData['user'] ?? responseData;
        }

        if (userData != null) {
          final user = User.fromJson(userData);
          state = state.copyWith(user: user);
          
          if (kDebugMode) {
            print('✅ Current user loaded: ${user.name}');
          }
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ getCurrentUser error: ${e.response?.statusCode}');
      }
      
      if (e.response?.statusCode == 401) {
        if (kDebugMode) {
          print('🔐 Token expired, logging out');
        }
        await logout();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected getCurrentUser error: $e');
      }
    }
  }

  // ✅ FIXED: Register method with gender included in API call
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String nationality,
    required String city,
    required bool isDriver,
    required String gender, // ✅ Added gender parameter
  }) async {
    if (state.isLoading) {
      if (kDebugMode) {
        print('⚠️ Registration already in progress, ignoring call');
      }
      return false;
    }

    if (kDebugMode) {
      print('🔥 Starting registration for: $email');
      print('📋 Registration data:');
      print('  - Name: $name');
      print('  - Email: $email');
      print('  - Phone: $phone');
      print('  - Gender: $gender'); // ✅ Log gender
      print('  - Nationality: $nationality');
      print('  - City: $city');
      print('  - Is Driver: $isDriver');
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
          'gender': gender, // ✅ FIXED: Added gender to API call
        },
      );

      if (kDebugMode) {
        print('📡 Registration response: ${response.statusCode}');
        print('📄 Response data: ${response.data}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Registration successful');
        }
        _setLoading(false);
        return true;
      }
      
      String errorMessage = 'فشل في إنشاء الحساب';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Registration DioError: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }
      
      String errorMessage = 'حدث خطأ في الاتصال';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'انتهت مهلة الاتصال';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة استلام البيانات';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'خطأ في الاتصال بالخادم';
      } else if (e.response != null) {
        try {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message'] as String? ?? 'خطأ من الخادم';
          } else {
            errorMessage = 'خطأ من الخادم';
          }
        } catch (parseError) {
          errorMessage = 'خطأ من الخادم';
        }
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

  // ✅ LOGIN WITH OTP
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        String? token;
        Map<String, dynamic>? userData;
        
        if (responseData['data'] != null) {
          final data = responseData['data'];
          token = data['token'] ?? data['accessToken'] ?? data['authToken'];
          userData = data['user'];
        } else {
          token = responseData['token'] ?? responseData['accessToken'];
          userData = responseData['user'];
        }

        if (token != null && userData != null) {
          await _prefs.setString('jwt_token', token);
          final user = User.fromJson(userData);
          state = state.copyWith(user: user, isLoading: false);
          return true;
        }
      }
      
      String errorMessage = 'فشل في تسجيل الدخول';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ FIXED: Ultra-robust verifyOTP method that handles ALL response types
  Future<bool> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    if (state.isLoading) return false;
    
    if (kDebugMode) {
      print('🔍 Starting OTP verification for: $email');
      print('  - OTP Code: $otpCode');
    }
    
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

      if (kDebugMode) {
        print('📡 OTP verification response: ${response.statusCode}');
        print('📄 Response data: ${response.data}');
        print('📄 Response data type: ${response.data.runtimeType}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // ✅ FIXED: Handle ALL possible response types
        if (responseData == null) {
          if (kDebugMode) {
            print('⚠️ Response data is null, but status is 200 - considering successful');
          }
          _setLoading(false);
          return true;
        }

        // ✅ Handle non-Map responses (String, bool, number, etc.)
        if (responseData is! Map<String, dynamic>) {
          if (kDebugMode) {
            print('⚠️ Response is not a Map (type: ${responseData.runtimeType}), treating as successful verification');
            print('📄 Response content: $responseData');
          }
          _setLoading(false);
          return true;
        }

        // ✅ Now we know it's a Map - handle it safely
        final responseMap = responseData as Map<String, dynamic>;
        Map<String, dynamic>? userData;
        String? token;
        String? message;
        
        try {
          // Extract message if available
          message = responseMap['message'] as String?;
          if (kDebugMode) {
            print('💬 Message: $message');
          }
          
          // Try nested data structure first
          if (responseMap.containsKey('data')) {
            final dataValue = responseMap['data'];
            
            if (dataValue is Map<String, dynamic>) {
              if (dataValue.containsKey('user') && dataValue['user'] is Map<String, dynamic>) {
                userData = dataValue['user'] as Map<String, dynamic>;
              } else if (dataValue.containsKey('name') || dataValue.containsKey('email')) {
                // data itself might be user data
                userData = dataValue;
              }
              
              // Try to extract token
              if (dataValue.containsKey('token')) {
                token = dataValue['token'] as String?;
              } else if (dataValue.containsKey('accessToken')) {
                token = dataValue['accessToken'] as String?;
              } else if (dataValue.containsKey('authToken')) {
                token = dataValue['authToken'] as String?;
              }
            }
          } 
          
          // Try direct structure if no nested data
          if (userData == null && responseMap.containsKey('user')) {
            final userValue = responseMap['user'];
            if (userValue is Map<String, dynamic>) {
              userData = userValue;
            }
          }
          
          // Try direct token if not found in data
          if (token == null) {
            token = responseMap['token'] as String? ?? 
                   responseMap['accessToken'] as String? ?? 
                   responseMap['authToken'] as String?;
          }

          if (kDebugMode) {
            print('👤 User data found: ${userData != null}');
            print('🔑 Token found: ${token != null}');
            if (userData != null) {
              print('👤 User data keys: ${userData.keys.toList()}');
            }
          }

          // ✅ Process the verification result
          if (userData != null) {
            try {
              final user = User.fromJson(userData);
              
              // If we have a token, save it and authenticate user
              if (token != null) {
                await _prefs.setString('jwt_token', token);
                state = state.copyWith(user: user, isLoading: false);
                
                if (kDebugMode) {
                  print('✅ User authenticated with token after OTP verification');
                }
              } else {
                // Email verified but no token (user needs to login separately)
                if (kDebugMode) {
                  print('✅ Email verified without token - user needs to login');
                }
                _setLoading(false);
              }
              
              return true;
            } catch (userParseError) {
              if (kDebugMode) {
                print('❌ Error parsing user data: $userParseError');
                print('📄 User data that failed: $userData');
              }
              // Still consider verification successful if we can't parse user
              _setLoading(false);
              return true;
            }
          } else {
            // No user data but successful response
            if (kDebugMode) {
              print('✅ OTP verification successful (no user data in response)');
            }
            _setLoading(false);
            return true;
          }
          
        } catch (parseError) {
          if (kDebugMode) {
            print('❌ Error parsing response structure: $parseError');
            print('📄 Response that failed parsing: $responseMap');
          }
          
          // If we can't parse but got 200, still consider it successful
          _setLoading(false);
          return true;
        }
      }

      // ✅ Handle non-200 status codes
      String errorMessage = 'رمز التحقق غير صحيح';
      
      try {
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          errorMessage = responseMap['message'] as String? ?? errorMessage;
        } else if (response.data is String) {
          errorMessage = response.data as String;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not extract error message, using default');
        }
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ OTP verification DioException: ${e.type}');
        print('❌ Error message: ${e.message}');
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
        print('❌ Response data type: ${e.response?.data.runtimeType}');
      }
      
      String errorMessage = 'خطأ في التحقق من الرمز';
      
      // Handle different status codes
      if (e.response?.statusCode == 400) {
        errorMessage = 'رمز التحقق غير صحيح أو منتهي الصلاحية';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'البريد الإلكتروني غير موجود';
      } else if (e.response?.statusCode == 422) {
        errorMessage = 'بيانات غير صحيحة';
      } else if (e.response?.data != null) {
        try {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message'] as String? ?? errorMessage;
          } else if (responseData is String) {
            errorMessage = responseData;
          }
        } catch (parseError) {
          if (kDebugMode) {
            print('⚠️ Could not parse error response, using default message');
          }
        }
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected OTP verification error: $e');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Stack trace: ${StackTrace.current}');
      }
      
      _setError('حدث خطأ غير متوقع في التحقق');
      _setLoading(false);
      return false;
    }
  }

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

      String errorMessage = 'فشل في إرسال رمز التحقق';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'خطأ في إرسال رمز التحقق';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

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

      String errorMessage = 'فشل في إرسال رمز التحقق';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'خطأ في إرسال رمز التحقق';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ PROFILE METHODS
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? gender,
    String? name,
    String? bio,
    String? nationality,
    String? currentAddress,
    String? city,
    String? stateValue,
    String? postalCode,
    String? country,
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
          'firstName': firstName,
          'lastName': lastName,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
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
        Map<String, dynamic>? userData;
        try {
          if (response.data is Map<String, dynamic>) {
            userData = response.data['data']?['user'] ?? response.data['user'];
          }
        } catch (e) {
          // Handle parsing error
        }

        if (userData != null) {
          final user = User.fromJson(userData);
          state = state.copyWith(user: user, isLoading: false);
          return true;
        }
      }
      
      String errorMessage = 'فشل في تحديث الملف الشخصي';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
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
      
      String errorMessage = 'فشل في تغيير كلمة المرور';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
      
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ FORGOT PASSWORD FLOW
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

      String errorMessage = 'فشل في إرسال رمز إعادة تعيين كلمة المرور';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'خطأ في إرسال الرمز';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
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

      String errorMessage = 'رمز التحقق غير صحيح';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'خطأ في التحقق من الرمز';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
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

      String errorMessage = 'فشل في إعادة تعيين كلمة المرور';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'حدث خطأ';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ PHONE VERIFICATION
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

      String errorMessage = 'فشل في إرسال رمز التحقق';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'خطأ في إرسال رمز التحقق';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

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
        final currentUser = state.user;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(phoneVerified: true);
          state = state.copyWith(user: updatedUser, isLoading: false);
        } else {
          _setLoading(false);
        }
        return true;
      }

      String errorMessage = 'رمز التحقق غير صحيح';
      try {
        if (response.data is Map<String, dynamic>) {
          errorMessage = response.data['message'] as String? ?? errorMessage;
        }
      } catch (e) {
        // Use default error message
      }

      _setError(errorMessage);
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      String errorMessage = 'خطأ في التحقق من الرمز';
      try {
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response!.data['message'] as String? ?? errorMessage;
        }
      } catch (parseError) {
        // Use default error message
      }
      
      _setError(errorMessage);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع');
      _setLoading(false);
      return false;
    }
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    if (kDebugMode) {
      print('🚪 Logging out...');
    }

    try {
      await _dioClient.dio.post(ApiConstants.logout);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Logout API call failed: $e');
      }
    }
    
    await _prefs.clear();
    state = AuthState();
    
    if (kDebugMode) {
      print('✅ Logout completed. State reset.');
    }
  }

  void clearError() {
    if (state.error != null) {
      _setError(null);
    }
  }

  void updateUserInState(User updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  Future<void> refreshUser() async {
    if (state.isAuthenticated) {
      await getCurrentUser();
    }
  }

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

final currentUserNameProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserName);
final currentUserEmailProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserEmail);
final currentUserPhoneProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserPhone);
final currentUserCityProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserCity);
final currentUserNationalityProvider = Provider<String>((ref) => ref.watch(authProvider).currentUserNationality);

final authLoadingProvider = Provider<bool>((ref) => ref.watch(authProvider).isLoading);
final authErrorProvider = Provider<String?>((ref) => ref.watch(authProvider).error);
final hasAuthErrorProvider = Provider<bool>((ref) => ref.watch(authProvider).hasError);

final isEmailVerifiedProvider = Provider<bool>((ref) => ref.watch(authProvider).isEmailVerified);
final isPhoneVerifiedProvider = Provider<bool>((ref) => ref.watch(authProvider).isPhoneVerified);
final needsEmailVerificationProvider = Provider<bool>((ref) => ref.watch(authProvider.notifier).needsEmailVerification);
final needsPhoneVerificationProvider = Provider<bool>((ref) => ref.watch(authProvider.notifier).needsPhoneVerification);

final profileImageUrlProvider = Provider<String?>((ref) => ref.watch(authProvider).profileImageUrl);
final lastLoginProvider = Provider<DateTime?>((ref) => ref.watch(authProvider).lastLoginAt);
