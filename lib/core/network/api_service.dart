import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';
import '../constants/api_constants.dart';
import '../../main.dart';

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  // ✅ Auth APIs - Updated for new API
  Future<Response> loginWithPassword(String email, String password) {
    return _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'email': email, 
        'password': password,
        'loginMethod': 'password',
      },
    );
  }

  Future<Response> loginWithOTP(String email, String otpCode) {
    return _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'email': email, 
        'loginMethod': 'otp',
        'otpCode': otpCode,
      },
    );
  }

  Future<Response> register(Map<String, dynamic> userData) {
    return _dioClient.dio.post(ApiConstants.register, data: userData);
  }

  Future<Response> verifyOTP(String email, String otpCode) {
    return _dioClient.dio.post(
      ApiConstants.verifyOTP,
      data: {'email': email, 'otpCode': otpCode},
    );
  }

  Future<Response> resendOTP(String email) {
    return _dioClient.dio.post(
      ApiConstants.resendOTP,
      data: {'email': email},
    );
  }

  Future<Response> sendLoginOTP(String email) {
    return _dioClient.dio.post(
      ApiConstants.sendLoginOTP,
      data: {'email': email},
    );
  }

  Future<Response> getCurrentUser() {
    return _dioClient.dio.get(ApiConstants.me);
  }

  Future<Response> updateProfile(Map<String, dynamic> profileData) {
    return _dioClient.dio.put(ApiConstants.profile, data: profileData);
  }

  Future<Response> changePassword(String currentPassword, String newPassword) {
    return _dioClient.dio.post(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // ✅ Phone Verification APIs
  Future<Response> sendPhoneOTP(String phone) {
    return _dioClient.dio.post(
      ApiConstants.sendPhoneOTP,
      data: {'phone': phone},
    );
  }

  Future<Response> verifyPhoneOTP(String phone, String otpCode) {
    return _dioClient.dio.post(
      ApiConstants.verifyPhoneOTP,
      data: {'phone': phone, 'otpCode': otpCode},
    );
  }

  // ✅ Password Reset APIs
  Future<Response> forgotPassword(String email) {
    return _dioClient.dio.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<Response> verifyResetOTP(String email, String otpCode) {
    return _dioClient.dio.post(
      ApiConstants.verifyResetOTP,
      data: {'email': email, 'otpCode': otpCode},
    );
  }

  Future<Response> resetPassword(String token, String newPassword) {
    return _dioClient.dio.post(
      ApiConstants.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  // ✅ Ride APIs - Updated for new API structure
  Future<Response> searchRides(Map<String, dynamic> params) {
    return _dioClient.dio.get(
      ApiConstants.searchRides,
      queryParameters: params,
    );
  }

  Future<Response> searchRidesByStops(Map<String, dynamic> searchData) {
    return _dioClient.dio.post(ApiConstants.searchRidesByStops, data: searchData);
  }

  Future<Response> createRide(Map<String, dynamic> rideData) {
    return _dioClient.dio.post(ApiConstants.rides, data: rideData);
  }

  Future<Response> getRide(int rideId) {
    return _dioClient.dio.get('${ApiConstants.rides}/$rideId');
  }

  Future<Response> getMyRides({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.rides,
      queryParameters: params,
    );
  }

  Future<Response> updateRide(int rideId, Map<String, dynamic> rideData) {
    return _dioClient.dio.put('${ApiConstants.rides}/$rideId', data: rideData);
  }

  Future<Response> cancelRide(int rideId) {
    return _dioClient.dio.delete('${ApiConstants.rides}/$rideId');
  }

  // ✅ Ride Stop Points APIs
  Future<Response> getRideStops(int rideId) {
    return _dioClient.dio.get('${ApiConstants.rideStops}/$rideId/stops');
  }

  Future<Response> addRideStop(int rideId, Map<String, dynamic> stopData) {
    return _dioClient.dio.post('${ApiConstants.rideStops}/$rideId/stops', data: stopData);
  }

  // ✅ Booking APIs - Updated for new API structure
  Future<Response> createBooking(Map<String, dynamic> bookingData) {
    return _dioClient.dio.post(ApiConstants.bookings, data: bookingData);
  }

  Future<Response> getMyBookings({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.bookings,
      queryParameters: params,
    );
  }

  Future<Response> getDriverBookings({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.driverBookings,
      queryParameters: params,
    );
  }

  Future<Response> getBooking(int bookingId) {
    return _dioClient.dio.get('${ApiConstants.bookings}/$bookingId');
  }

  Future<Response> updateBooking(int bookingId, Map<String, dynamic> bookingData) {
    return _dioClient.dio.put('${ApiConstants.bookings}/$bookingId', data: bookingData);
  }

  Future<Response> cancelBooking(int bookingId) {
    return _dioClient.dio.delete('${ApiConstants.bookings}/$bookingId');
  }

  Future<Response> acceptBooking(int bookingId, {String? notes}) {
    return _dioClient.dio.post(
      '${ApiConstants.bookings}/$bookingId/accept',
      data: {'notes': notes},
    );
  }

  Future<Response> rejectBooking(int bookingId, {String? notes}) {
    return _dioClient.dio.post(
      '${ApiConstants.bookings}/$bookingId/reject',
      data: {'notes': notes},
    );
  }

  Future<Response> completeBooking(int bookingId) {
    return _dioClient.dio.post('${ApiConstants.bookings}/$bookingId/complete');
  }

  // ✅ Chat APIs - Updated for new API structure
  Future<Response> getChatMessages({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.chat,
      queryParameters: params,
    );
  }

  Future<Response> sendChatMessage(Map<String, dynamic> messageData) {
    return _dioClient.dio.post(ApiConstants.chat, data: messageData);
  }

  Future<Response> createChatForBooking(int bookingId) {
    return _dioClient.dio.post(
      ApiConstants.createChatForBooking,
      data: {'bookingId': bookingId},
    );
  }

  Future<Response> getChatUnreadCount() {
    return _dioClient.dio.get(ApiConstants.chatUnreadCount);
  }

  Future<Response> markChatAsRead(int chatId) {
    return _dioClient.dio.patch('${ApiConstants.chat}/$chatId/read');
  }

  // ✅ Notification APIs - Updated for new notification system
  Future<Response> getNotifications({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.notifications,
      queryParameters: params,
    );
  }

  Future<Response> getNotificationById(int notificationId) {
    return _dioClient.dio.get('${ApiConstants.notifications}/$notificationId');
  }

  Future<Response> markNotificationAsRead(int notificationId) {
    return _dioClient.dio.patch('${ApiConstants.notifications}/$notificationId/read');
  }

  Future<Response> markAllNotificationsAsRead() {
    return _dioClient.dio.patch('${ApiConstants.notifications}/read-all');
  }

  Future<Response> deleteNotification(int notificationId) {
    return _dioClient.dio.delete('${ApiConstants.notifications}/$notificationId');
  }

  Future<Response> getNotificationUnreadCount() {
    return _dioClient.dio.get(ApiConstants.notificationUnreadCount);
  }

  Future<Response> testNotification() {
    return _dioClient.dio.post(ApiConstants.testNotification);
  }

  // ✅ Legacy Notification APIs (if still needed)
  Future<Response> getLegacyNotifications({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.legacyNotifications,
      queryParameters: params,
    );
  }

  Future<Response> getLegacyUnreadCount() {
    return _dioClient.dio.get(ApiConstants.legacyUnreadCount);
  }

  // ✅ Admin Conversation APIs
  Future<Response> getAdminConversations({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.adminConversations,
      queryParameters: params,
    );
  }

  Future<Response> getAdminMessagesUnreadCount() {
    return _dioClient.dio.get(ApiConstants.adminMessagesUnreadCount);
  }

  // ✅ Rating & Review APIs
  Future<Response> createRating(Map<String, dynamic> ratingData) {
    return _dioClient.dio.post(ApiConstants.ratings, data: ratingData);
  }

  Future<Response> createReview(Map<String, dynamic> reviewData) {
    return _dioClient.dio.post(ApiConstants.reviews, data: reviewData);
  }

  Future<Response> getUserRatings(int userId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userRatings.replaceAll('{userId}', userId.toString()),
      queryParameters: params,
    );
  }

  // ✅ Document Management APIs
  Future<Response> uploadDocument(FormData formData) {
    return _dioClient.dio.post(ApiConstants.documentsUpload, data: formData);
  }

  Future<Response> getMyDocuments() {
    return _dioClient.dio.get(ApiConstants.myDocuments);
  }

  Future<Response> getVerificationStatus() {
    return _dioClient.dio.get(ApiConstants.verificationStatus);
  }

  Future<Response> getRequiredDocuments() {
    return _dioClient.dio.get(ApiConstants.requiredDocuments);
  }

  // ✅ Real-time APIs
  Future<Response> getRealtimeStatus() {
    return _dioClient.dio.get(ApiConstants.realtimeStatus);
  }

  // ✅ Statistics APIs
  Future<Response> getBookingStats() {
    return _dioClient.dio.get(ApiConstants.bookingStats);
  }

  Future<Response> getChatStats() {
    return _dioClient.dio.get(ApiConstants.chatStats);
  }

  Future<Response> getNotificationStats() {
    return _dioClient.dio.get(ApiConstants.notificationStats);
  }

  // ✅ System APIs
  Future<Response> healthCheck() {
    return _dioClient.dio.get(ApiConstants.health);
  }

  Future<Response> logout() {
    return _dioClient.dio.post(ApiConstants.logout);
  }
}

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);
  return ApiService(dioClient);
});
