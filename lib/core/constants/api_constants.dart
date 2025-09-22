class ApiConstants {
  static const String baseUrl = 'https://api.prodevtechs.com';
  static const String wsUrl = 'wss://api.prodevtechs.com';
  
  // Authentication & User Management
  static const String register = '/api/auth/register';
  static const String verifyOTP = '/api/auth/verify-otp';
  static const String resendOTP = '/api/auth/resend-otp';
  static const String login = '/api/auth/login';
  static const String sendLoginOTP = '/api/auth/send-login-otp';
  static const String logout = '/api/auth/logout';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyResetOTP = '/api/auth/verify-reset-otp';
  static const String resetPassword = '/api/auth/reset-password';
  static const String me = '/api/auth/me';
  
  // Phone Verification
  static const String sendPhoneOTP = '/api/auth/send-phone-otp';
  static const String verifyPhoneOTP = '/api/auth/verify-phone-otp';
  
  // User Profile Management
  static const String profile = '/api/users/profile';
  static const String changePassword = '/api/users/change-password';
  static const String userRides = '/api/users/rides';
  static const String userRatings = '/api/users/ratings';
  
  // Ride Management
  static const String rides = '/api/rides';
  static const String searchRides = '/api/rides/search';
  static const String searchRidesByStops = '/api/rides/search-by-stops';
  static const String rideStops = '/api/rides'; // + /{id}/stops
  
  // Bookings
  static const String bookings = '/api/bookings';
  static const String driverBookings = '/api/bookings/driver';
  static const String bookingStats = '/api/bookings/stats/summary';
  
  // Chat & Messaging
  static const String chat = '/api/chat';
  static const String chatUnreadCount = '/api/chat/unread/count';
  static const String createChatForBooking = '/api/chat/create-for-booking';
  static const String chatStats = '/api/chat/stats/overview';
  
  // Notifications (New System)
  static const String notifications = '/api/notifications';
  static const String notificationStats = '/api/notifications/stats/overview';
  static const String notificationUnreadCount = '/api/notifications/unread/count';
  static const String testNotification = '/api/notifications/test';
  
  // Legacy Notifications
  static const String legacyNotifications = '/api/user-notifications/notifications';
  static const String legacyUnreadCount = '/api/user-notifications/notifications/unread-count';
  static const String legacyNotificationStats = '/api/user-notifications/notifications/stats';
  
  // Admin-User Messaging
  static const String adminConversations = '/api/user-notifications/conversations';
  static const String adminMessagesUnreadCount = '/api/user-notifications/messages/unread-count';
  static const String adminMessageStats = '/api/user-notifications/messages/stats';
  
  // Ratings & Reviews
  static const String ratings = '/api/ratings';
  static const String reviews = '/api/reviews';
  
  // Document Management
  static const String documentsUpload = '/api/documents/upload';
  static const String myDocuments = '/api/documents/my-documents';
  static const String verificationStatus = '/api/documents/verification/status';
  static const String requiredDocuments = '/api/documents/verification/required-documents';
  
  // Real-time Features
  static const String realtimeChat = '/api/realtime/chat';
  static const String realtimeRide = '/api/realtime/ride';
  static const String realtimeNotifications = '/api/realtime/notifications';
  static const String realtimeStatus = '/api/realtime/status';
  
  // System
  static const String health = '/health';
}
