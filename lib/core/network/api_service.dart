import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';
import '../constants/api_constants.dart';
import '../../main.dart';

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  // ✅ AUTH APIs - Updated for new API
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

  Future<Response> logout() {
    return _dioClient.dio.post(ApiConstants.logout);
  }

  // ✅ PHONE VERIFICATION APIs
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

  // ✅ PASSWORD RESET APIs
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

  // ✅ RIDE APIs - Fixed endpoints
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
    return _dioClient.dio.get(ApiConstants.rideById(rideId));
  }

  // ✅ Fixed: Use userRides endpoint for driver's rides
  Future<Response> getMyRides({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userRides,
      queryParameters: params,
    );
  }

  Future<Response> updateRide(int rideId, Map<String, dynamic> rideData) {
    return _dioClient.dio.put(ApiConstants.updateRideById(rideId), data: rideData);
  }

  Future<Response> cancelRide(int rideId) {
    return _dioClient.dio.delete(ApiConstants.deleteRideById(rideId));
  }

  Future<Response> startRide(int rideId) {
    return _dioClient.dio.put(ApiConstants.startRideById(rideId));
  }

  Future<Response> completeRide(int rideId) {
    return _dioClient.dio.put(ApiConstants.completeRideById(rideId));
  }

  // ✅ RIDE STOP POINTS APIs - Fixed endpoints
  Future<Response> getRideStops(int rideId) {
    return _dioClient.dio.get(ApiConstants.rideStopsById(rideId));
  }

  Future<Response> addRideStop(int rideId, Map<String, dynamic> stopData) {
    return _dioClient.dio.post(ApiConstants.rideStopsById(rideId), data: stopData);
  }

  // ✅ BOOKING APIs - Fixed endpoints
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
    return _dioClient.dio.get(ApiConstants.bookingById(bookingId));
  }

  Future<Response> updateBooking(int bookingId, Map<String, dynamic> bookingData) {
    return _dioClient.dio.put(ApiConstants.bookingById(bookingId), data: bookingData);
  }

  Future<Response> cancelBooking(int bookingId) {
    return _dioClient.dio.post(ApiConstants.cancelBookingById(bookingId));
  }

  Future<Response> acceptBooking(int bookingId, {String? notes}) {
    return _dioClient.dio.post(
      ApiConstants.acceptBookingById(bookingId),
      data: {'notes': notes},
    );
  }

  Future<Response> rejectBooking(int bookingId, {String? notes}) {
    return _dioClient.dio.post(
      ApiConstants.rejectBookingById(bookingId),
      data: {'notes': notes},
    );
  }

  Future<Response> confirmBooking(int bookingId) {
    return _dioClient.dio.post(ApiConstants.confirmBookingById(bookingId));
  }

  Future<Response> completeBooking(int bookingId) {
    return _dioClient.dio.post(ApiConstants.completeBookingById(bookingId));
  }

  Future<Response> rateBooking(int bookingId, Map<String, dynamic> ratingData) {
    return _dioClient.dio.post(
      ApiConstants.rateBookingById(bookingId),
      data: ratingData,
    );
  }

  // ✅ CHAT APIs - Fixed endpoints
  Future<Response> getChats({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.chat,
      queryParameters: params,
    );
  }

  Future<Response> getChatMessages(int chatId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.chatMessagesById(chatId),
      queryParameters: params,
    );
  }

  Future<Response> sendChatMessage(int chatId, Map<String, dynamic> messageData) {
    return _dioClient.dio.post(
      ApiConstants.sendChatMessageById(chatId), 
      data: messageData,
    );
  }

  Future<Response> createChatForBooking(int bookingId) {
    return _dioClient.dio.post(ApiConstants.createChatForBookingById(bookingId));
  }

  Future<Response> getChatUnreadCount() {
    return _dioClient.dio.get(ApiConstants.chatUnreadCount);
  }

  Future<Response> markChatAsRead(int chatId) {
    return _dioClient.dio.put(ApiConstants.markChatReadById(chatId));
  }

  Future<Response> deleteChat(int chatId) {
    return _dioClient.dio.delete(ApiConstants.deleteChatById(chatId));
  }

  // ✅ NOTIFICATION APIs - Fixed endpoints
  Future<Response> getNotifications({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.notifications,
      queryParameters: params,
    );
  }

  Future<Response> getNotificationById(int notificationId) {
    return _dioClient.dio.get(ApiConstants.notificationById(notificationId));
  }

  Future<Response> markNotificationAsRead(int notificationId) {
    return _dioClient.dio.put(ApiConstants.markNotificationReadById(notificationId));
  }

  Future<Response> markNotificationAsUnread(int notificationId) {
    return _dioClient.dio.put(ApiConstants.markNotificationUnreadById(notificationId));
  }

  Future<Response> markAllNotificationsAsRead() {
    return _dioClient.dio.put('${ApiConstants.notifications}/read-all');
  }

  Future<Response> deleteNotification(int notificationId) {
    return _dioClient.dio.delete(ApiConstants.deleteNotificationById(notificationId));
  }

  Future<Response> getNotificationUnreadCount() {
    return _dioClient.dio.get(ApiConstants.notificationUnreadCount);
  }

  Future<Response> testNotification() {
    return _dioClient.dio.post(ApiConstants.testNotification);
  }

  // ✅ LEGACY NOTIFICATION APIs
  Future<Response> getLegacyNotifications({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.legacyNotifications,
      queryParameters: params,
    );
  }

  Future<Response> getLegacyNotificationById(int notificationId) {
    return _dioClient.dio.get(ApiConstants.legacyNotificationById(notificationId));
  }

  Future<Response> markLegacyNotificationAsRead(int notificationId) {
    return _dioClient.dio.put(ApiConstants.markLegacyNotificationReadById(notificationId));
  }

  Future<Response> deleteLegacyNotification(int notificationId) {
    return _dioClient.dio.delete(ApiConstants.deleteLegacyNotificationById(notificationId));
  }

  Future<Response> getLegacyUnreadCount() {
    return _dioClient.dio.get(ApiConstants.legacyUnreadCount);
  }

  // ✅ ADMIN CONVERSATION APIs
  Future<Response> getAdminConversations({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.adminConversations,
      queryParameters: params,
    );
  }

  Future<Response> getConversationMessages(int adminId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.conversationMessagesById(adminId),
      queryParameters: params,
    );
  }

  Future<Response> sendConversationMessage(int adminId, Map<String, dynamic> messageData) {
    return _dioClient.dio.post(
      ApiConstants.sendConversationMessageById(adminId),
      data: messageData,
    );
  }

  Future<Response> markConversationAsRead(int adminId) {
    return _dioClient.dio.put(ApiConstants.markConversationReadById(adminId));
  }

  Future<Response> getAdminMessagesUnreadCount() {
    return _dioClient.dio.get(ApiConstants.adminMessagesUnreadCount);
  }

  // ✅ RATING & REVIEW APIs - Fixed endpoints
  Future<Response> createRating(Map<String, dynamic> ratingData) {
    return _dioClient.dio.post(ApiConstants.ratings, data: ratingData);
  }

  Future<Response> getRating(int ratingId) {
    return _dioClient.dio.get(ApiConstants.ratingById(ratingId));
  }

  Future<Response> updateRating(int ratingId, Map<String, dynamic> ratingData) {
    return _dioClient.dio.put(ApiConstants.updateRatingById(ratingId), data: ratingData);
  }

  Future<Response> deleteRating(int ratingId) {
    return _dioClient.dio.delete(ApiConstants.deleteRatingById(ratingId));
  }

  Future<Response> getGivenRatings({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.givenRatings,
      queryParameters: params,
    );
  }

  Future<Response> getReceivedRatings({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.receivedRatings,
      queryParameters: params,
    );
  }

  Future<Response> getUserRatings(int userId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userRatingsById(userId),
      queryParameters: params,
    );
  }

  Future<Response> getRideRatings(int rideId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.rideRatingsById(rideId),
      queryParameters: params,
    );
  }

  // ✅ REVIEW APIs
  Future<Response> createReview(Map<String, dynamic> reviewData) {
    return _dioClient.dio.post(ApiConstants.reviews, data: reviewData);
  }

  Future<Response> getReview(int reviewId) {
    return _dioClient.dio.get(ApiConstants.reviewById(reviewId));
  }

  Future<Response> updateReview(int reviewId, Map<String, dynamic> reviewData) {
    return _dioClient.dio.put(ApiConstants.updateReviewById(reviewId), data: reviewData);
  }

  Future<Response> deleteReview(int reviewId) {
    return _dioClient.dio.delete(ApiConstants.deleteReviewById(reviewId));
  }

  Future<Response> getUserReviews(int userId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userReviewsById(userId),
      queryParameters: params,
    );
  }

  Future<Response> getRideReviews(int rideId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.rideReviewsById(rideId),
      queryParameters: params,
    );
  }

  // ✅ DOCUMENT MANAGEMENT APIs
  Future<Response> uploadDocument(FormData formData) {
    return _dioClient.dio.post(ApiConstants.documentsUpload, data: formData);
  }

  Future<Response> getMyDocuments() {
    return _dioClient.dio.get(ApiConstants.myDocuments);
  }

  Future<Response> getDocument(int documentId) {
    return _dioClient.dio.get(ApiConstants.documentById(documentId));
  }

  Future<Response> updateDocument(int documentId, Map<String, dynamic> documentData) {
    return _dioClient.dio.put(ApiConstants.updateDocumentById(documentId), data: documentData);
  }

  Future<Response> deleteDocument(int documentId) {
    return _dioClient.dio.delete(ApiConstants.deleteDocumentById(documentId));
  }

  Future<Response> getDocumentImage(String filename) {
    return _dioClient.dio.get(ApiConstants.documentImageByFilename(filename));
  }

  Future<Response> getDocumentImageById(int documentId) {
    return _dioClient.dio.get(ApiConstants.documentImageById(documentId));
  }

  Future<Response> getVerificationStatus() {
    return _dioClient.dio.get(ApiConstants.verificationStatus);
  }

  Future<Response> getRequiredDocuments() {
    return _dioClient.dio.get(ApiConstants.requiredDocuments);
  }

  // ✅ USER PROFILE APIs
  Future<Response> getUserProfile(int userId) {
    return _dioClient.dio.get(ApiConstants.userProfileById(userId));
  }

  Future<Response> getUserRidesProfile(int userId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userRidesById(userId),
      queryParameters: params,
    );
  }

  Future<Response> getUserRatingsDetail(int userId, {Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userRatingsDetailById(userId),
      queryParameters: params,
    );
  }

  Future<Response> blockUser(int userId) {
    return _dioClient.dio.post(ApiConstants.blockUserById(userId));
  }

  Future<Response> unblockUser(int userId) {
    return _dioClient.dio.post(ApiConstants.unblockUserById(userId));
  }

  Future<Response> reportUser(int userId, Map<String, dynamic> reportData) {
    return _dioClient.dio.post(ApiConstants.reportUserById(userId), data: reportData);
  }

  // ✅ REAL-TIME APIs
  Future<Response> getRealtimeStatus() {
    return _dioClient.dio.get(ApiConstants.realtimeStatus);
  }

  Future<Response> getRealtimeChatStatus(int chatId) {
    return _dioClient.dio.get(ApiConstants.realtimeChatById(chatId));
  }

  Future<Response> getRealtimeRideStatus(int rideId) {
    return _dioClient.dio.get(ApiConstants.realtimeRideById(rideId));
  }

  Future<Response> getRealtimeNotifications(int userId) {
    return _dioClient.dio.get(ApiConstants.realtimeNotificationsById(userId));
  }

  Future<Response> getRealtimeUserStatus(int userId) {
    return _dioClient.dio.get(ApiConstants.realtimeUserStatus(userId));
  }

  // ✅ STATISTICS APIs
  Future<Response> getBookingStats() {
    return _dioClient.dio.get(ApiConstants.bookingStats);
  }

  Future<Response> getChatStats() {
    return _dioClient.dio.get(ApiConstants.chatStats);
  }

  Future<Response> getNotificationStats() {
    return _dioClient.dio.get(ApiConstants.notificationStats);
  }

  // ✅ SYSTEM APIs
  Future<Response> healthCheck() {
    return _dioClient.dio.get(ApiConstants.health);
  }

  // ✅ ADDITIONAL HELPER METHODS

  // Get user's own ratings
  Future<Response> getMyRatings({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.userRatings,
      queryParameters: params,
    );
  }

  // Get all reviews
  Future<Response> getAllReviews({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.reviews,
      queryParameters: params,
    );
  }

  // Get all ratings
  Future<Response> getAllRatings({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.ratings,
      queryParameters: params,
    );
  }

  // Get all documents
  Future<Response> getAllDocuments({Map<String, dynamic>? params}) {
    return _dioClient.dio.get(
      ApiConstants.documents,
      queryParameters: params,
    );
  }

  // Batch operations
  Future<Response> markMultipleNotificationsAsRead(List<int> notificationIds) {
    return _dioClient.dio.put(
      '${ApiConstants.notifications}/batch-read',
      data: {'notificationIds': notificationIds},
    );
  }

  Future<Response> deleteMultipleNotifications(List<int> notificationIds) {
    return _dioClient.dio.delete(
      '${ApiConstants.notifications}/batch-delete',
      data: {'notificationIds': notificationIds},
    );
  }

  // Generic API call method for custom endpoints
  Future<Response> customRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    switch (method.toUpperCase()) {
      case 'GET':
        return _dioClient.dio.get(
          endpoint,
          queryParameters: queryParameters,
          options: options,
        );
      case 'POST':
        return _dioClient.dio.post(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      case 'PUT':
        return _dioClient.dio.put(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      case 'PATCH':
        return _dioClient.dio.patch(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      case 'DELETE':
        return _dioClient.dio.delete(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);
  return ApiService(dioClient);
});
