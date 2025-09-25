class ApiConstants {
  // ✅ BASE URLS
  static const String baseUrl = 'https://api.prodevtechs.com';
  static const String wsUrl = 'wss://api.prodevtechs.com';
  
  // ✅ AUTHENTICATION & USER MANAGEMENT
  static const String register = '$baseUrl/api/auth/register';
  static const String verifyOTP = '$baseUrl/api/auth/verify-otp';
  static const String resendOTP = '$baseUrl/api/auth/resend-otp';
  static const String login = '$baseUrl/api/auth/login';
  static const String sendLoginOTP = '$baseUrl/api/auth/send-login-otp';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password';
  static const String verifyResetOTP = '$baseUrl/api/auth/verify-reset-otp';
  static const String resetPassword = '$baseUrl/api/auth/reset-password';
  static const String me = '$baseUrl/api/auth/me';
  
  // ✅ PHONE VERIFICATION
  static const String sendPhoneOTP = '$baseUrl/api/auth/send-phone-otp';
  static const String verifyPhoneOTP = '$baseUrl/api/auth/verify-phone-otp';
  
  // ✅ USER PROFILE MANAGEMENT
  static const String profile = '$baseUrl/api/users/profile';
  static const String changePassword = '$baseUrl/api/users/change-password';
  static const String userRides = '$baseUrl/api/users/rides';
  static const String userRatings = '$baseUrl/api/users/ratings';
  
  // ✅ RIDE MANAGEMENT
  static const String rides = '$baseUrl/api/rides';
  static const String searchRides = '$baseUrl/api/rides/search';
  static const String searchRidesByStops = '$baseUrl/api/rides/search-by-stops';
  
  // ✅ BOOKING MANAGEMENT
  static const String bookings = '$baseUrl/api/bookings';
  static const String driverBookings = '$baseUrl/api/bookings/driver';
  static const String bookingStats = '$baseUrl/api/bookings/stats/summary';
  
  // ✅ CHAT & MESSAGING
  static const String chat = '$baseUrl/api/chat';
  static const String chatUnreadCount = '$baseUrl/api/chat/unread/count';
  static const String createChatForBooking = '$baseUrl/api/chat/create-for-booking';
  static const String chatStats = '$baseUrl/api/chat/stats/overview';
  
  // ✅ NOTIFICATIONS (New System)
  static const String notifications = '$baseUrl/api/notifications';
  static const String notificationStats = '$baseUrl/api/notifications/stats/overview';
  static const String notificationUnreadCount = '$baseUrl/api/notifications/unread/count';
  static const String testNotification = '$baseUrl/api/notifications/test';
  
  // ✅ LEGACY NOTIFICATIONS
  static const String legacyNotifications = '$baseUrl/api/user-notifications/notifications';
  static const String legacyUnreadCount = '$baseUrl/api/user-notifications/notifications/unread-count';
  static const String legacyNotificationStats = '$baseUrl/api/user-notifications/notifications/stats';
  
  // ✅ ADMIN-USER MESSAGING
  static const String adminConversations = '$baseUrl/api/user-notifications/conversations';
  static const String adminMessagesUnreadCount = '$baseUrl/api/user-notifications/messages/unread-count';
  static const String adminMessageStats = '$baseUrl/api/user-notifications/messages/stats';
  
  // ✅ RATINGS & REVIEWS
  static const String ratings = '$baseUrl/api/ratings';
  static const String givenRatings = '$baseUrl/api/ratings/given';
  static const String receivedRatings = '$baseUrl/api/ratings/received';
  static const String reviews = '$baseUrl/api/reviews';
  
  // ✅ DOCUMENT MANAGEMENT
  static const String documentsUpload = '$baseUrl/api/documents/upload';
  static const String myDocuments = '$baseUrl/api/documents/my-documents';
  static const String documents = '$baseUrl/api/documents';
  static const String verificationStatus = '$baseUrl/api/documents/verification/status';
  static const String requiredDocuments = '$baseUrl/api/documents/verification/required-documents';
  
  // ✅ REAL-TIME FEATURES
  static const String realtimeChat = '$baseUrl/api/realtime/chat';
  static const String realtimeRide = '$baseUrl/api/realtime/ride';
  static const String realtimeNotifications = '$baseUrl/api/realtime/notifications';
  static const String realtimeStatus = '$baseUrl/api/realtime/status';
  
  // ✅ SYSTEM & HEALTH
  static const String health = '$baseUrl/health';
  
  // ✅ WEBSOCKET ENDPOINTS
  static const String wsChat = '$wsUrl/api/realtime/chat';
  static const String wsRide = '$wsUrl/api/realtime/ride';
  static const String wsNotifications = '$wsUrl/api/realtime/notifications';
  static const String wsStatus = '$wsUrl/api/realtime/status';
  
  // ✅ DYNAMIC ENDPOINT BUILDERS
  
  // Ride Endpoints
  static String rideById(int rideId) => '$rides/$rideId';
  static String rideStopsById(int rideId) => '$rides/$rideId/stops';
  static String updateRideById(int rideId) => '$rides/$rideId';
  static String deleteRideById(int rideId) => '$rides/$rideId';
  static String startRideById(int rideId) => '$rides/$rideId/start';
  static String completeRideById(int rideId) => '$rides/$rideId/complete';
  static String cancelRideById(int rideId) => '$rides/$rideId/cancel';
  
  // Booking Endpoints
  static String bookingById(int bookingId) => '$bookings/$bookingId';
  static String cancelBookingById(int bookingId) => '$bookings/$bookingId/cancel';
  static String acceptBookingById(int bookingId) => '$bookings/$bookingId/accept';
  static String rejectBookingById(int bookingId) => '$bookings/$bookingId/reject';
  static String confirmBookingById(int bookingId) => '$bookings/$bookingId/confirm';
  static String completeBookingById(int bookingId) => '$bookings/$bookingId/complete';
  static String rateBookingById(int bookingId) => '$bookings/$bookingId/rate';
  
  // Chat Endpoints
  static String chatById(int chatId) => '$chat/$chatId';
  static String chatMessagesById(int chatId) => '$chat/$chatId/messages';
  static String sendChatMessageById(int chatId) => '$chat/$chatId/messages';
  static String markChatReadById(int chatId) => '$chat/$chatId/read';
  static String deleteChatById(int chatId) => '$chat/$chatId';
  static String createChatForBookingById(int bookingId) => '$createChatForBooking/$bookingId';
  
  // Document Endpoints
  static String documentById(int documentId) => '$documents/$documentId';
  static String updateDocumentById(int documentId) => '$documents/$documentId';
  static String deleteDocumentById(int documentId) => '$documents/$documentId';
  static String documentImageByFilename(String filename) => '$baseUrl/api/documents/image/$filename';
  static String documentImageById(int documentId) => '$documents/$documentId/image';
  
  // Notification Endpoints
  static String notificationById(int notificationId) => '$notifications/$notificationId';
  static String markNotificationReadById(int notificationId) => '$notifications/$notificationId/read';
  static String markNotificationUnreadById(int notificationId) => '$notifications/$notificationId/unread';
  static String deleteNotificationById(int notificationId) => '$notifications/$notificationId';
  
  // Rating & Review Endpoints
  static String ratingById(int ratingId) => '$ratings/$ratingId';
  static String updateRatingById(int ratingId) => '$ratings/$ratingId';
  static String deleteRatingById(int ratingId) => '$ratings/$ratingId';
  static String reviewById(int reviewId) => '$reviews/$reviewId';
  static String updateReviewById(int reviewId) => '$reviews/$reviewId';
  static String deleteReviewById(int reviewId) => '$reviews/$reviewId';
  static String userReviewsById(int userId) => '$baseUrl/api/reviews/user/$userId';
  static String rideReviewsById(int rideId) => '$baseUrl/api/reviews/ride/$rideId';
  static String userRatingsById(int userId) => '$ratings/user/$userId';
  static String rideRatingsById(int rideId) => '$ratings/ride/$rideId';
  
  // Legacy Notification Endpoints
  static String legacyNotificationById(int notificationId) => '$legacyNotifications/$notificationId';
  static String markLegacyNotificationReadById(int notificationId) => '$legacyNotifications/$notificationId/read';
  static String deleteLegacyNotificationById(int notificationId) => '$legacyNotifications/$notificationId';
  
  // Admin Conversation Endpoints
  static String conversationById(int adminId) => '$adminConversations/$adminId';
  static String conversationMessagesById(int adminId) => '$adminConversations/$adminId/messages';
  static String sendConversationMessageById(int adminId) => '$adminConversations/$adminId/messages';
  static String markConversationReadById(int adminId) => '$adminConversations/$adminId/read';
  
  // User Profile Endpoints
  static String userProfileById(int userId) => '$baseUrl/api/users/$userId/profile';
  static String userRidesById(int userId) => '$baseUrl/api/users/$userId/rides';
  static String userRatingsDetailById(int userId) => '$baseUrl/api/users/$userId/ratings';
  static String blockUserById(int userId) => '$baseUrl/api/users/$userId/block';
  static String unblockUserById(int userId) => '$baseUrl/api/users/$userId/unblock';
  static String reportUserById(int userId) => '$baseUrl/api/users/$userId/report';
  
  // Real-time Endpoints
  static String realtimeChatById(int chatId) => '$realtimeChat/$chatId';
  static String realtimeRideById(int rideId) => '$realtimeRide/$rideId';
  static String realtimeNotificationsById(int userId) => '$realtimeNotifications/$userId';
  static String realtimeUserStatus(int userId) => '$realtimeStatus/$userId';
  
  // WebSocket Endpoints
  static String wsChatById(int chatId) => '$wsChat/$chatId';
  static String wsRideById(int rideId) => '$wsRide/$rideId';
  static String wsNotificationsById(int userId) => '$wsNotifications/$userId';
  static String wsUserStatus(int userId) => '$wsStatus/$userId';
  
  // ✅ UTILITY METHODS
  
  // Check if endpoint requires authentication
  static bool requiresAuth(String endpoint) {
    final publicEndpoints = [
      register,
      login,
      verifyOTP,
      resendOTP,
      forgotPassword,
      verifyResetOTP,
      resetPassword,
      sendLoginOTP,
      health,
    ];
    return !publicEndpoints.contains(endpoint);
  }
  
  // Get full URL for relative endpoint
  static String getFullUrl(String relativeEndpoint) {
    if (relativeEndpoint.startsWith('http')) {
      return relativeEndpoint;
    }
    return '$baseUrl$relativeEndpoint';
  }
  
  // Get WebSocket URL for real-time features
  static String getWebSocketUrl(String endpoint) {
    return endpoint.replaceFirst(baseUrl, wsUrl);
  }
  
  // Validate endpoint format
  static bool isValidEndpoint(String endpoint) {
    return endpoint.startsWith(baseUrl) || endpoint.startsWith(wsUrl);
  }
  
  // ✅ ENDPOINT CATEGORIES (for easier organization)
  
  static const List<String> authEndpoints = [
    register,
    verifyOTP,
    resendOTP,
    login,
    sendLoginOTP,
    logout,
    forgotPassword,
    verifyResetOTP,
    resetPassword,
    me,
    sendPhoneOTP,
    verifyPhoneOTP,
  ];
  
  static const List<String> userEndpoints = [
    profile,
    changePassword,
    userRides,
    userRatings,
  ];
  
  static const List<String> rideEndpoints = [
    rides,
    searchRides,
    searchRidesByStops,
  ];
  
  static const List<String> bookingEndpoints = [
    bookings,
    driverBookings,
    bookingStats,
  ];
  
  static const List<String> chatEndpoints = [
    chat,
    chatUnreadCount,
    createChatForBooking,
    chatStats,
  ];
  
  static const List<String> notificationEndpoints = [
    notifications,
    notificationStats,
    notificationUnreadCount,
    testNotification,
  ];
  
  static const List<String> documentEndpoints = [
    documentsUpload,
    myDocuments,
    documents,
    verificationStatus,
    requiredDocuments,
  ];
  
  static const List<String> ratingEndpoints = [
    ratings,
    givenRatings,
    receivedRatings,
    reviews,
  ];
  
  static const List<String> realtimeEndpoints = [
    realtimeChat,
    realtimeRide,
    realtimeNotifications,
    realtimeStatus,
  ];
  
  static const List<String> legacyEndpoints = [
    legacyNotifications,
    legacyUnreadCount,
    legacyNotificationStats,
    adminConversations,
    adminMessagesUnreadCount,
    adminMessageStats,
  ];
  
  // ✅ COMMON QUERY PARAMETERS
  static const Map<String, String> defaultQueryParams = {
    'limit': '20',
    'offset': '0',
    'sortBy': 'createdAt',
    'sortOrder': 'desc',
  };
  
  // ✅ HTTP METHODS FOR ENDPOINTS (Fixed duplicate keys)
  static const Map<String, String> httpMethods = {
    // Auth endpoints
    register: 'POST',
    verifyOTP: 'POST',
    resendOTP: 'POST',
    login: 'POST',
    sendLoginOTP: 'POST',
    logout: 'POST',
    forgotPassword: 'POST',
    verifyResetOTP: 'POST',
    resetPassword: 'POST',
    me: 'GET',
    sendPhoneOTP: 'POST',
    verifyPhoneOTP: 'POST',
    
    // User endpoints
    profile: 'GET', // GET for read, PUT for update
    changePassword: 'POST',
    userRides: 'GET',
    userRatings: 'GET',
    
    // Ride endpoints
    rides: 'GET', // GET for list, POST for create
    searchRides: 'GET',
    searchRidesByStops: 'POST',
    
    // Booking endpoints
    bookings: 'GET', // GET for list, POST for create
    driverBookings: 'GET',
    bookingStats: 'GET',
    
    // Chat endpoints
    chat: 'GET', // GET for list, POST for create
    chatUnreadCount: 'GET',
    createChatForBooking: 'POST',
    chatStats: 'GET',
    
    // Notification endpoints
    notifications: 'GET', // GET for list, POST for create
    notificationStats: 'GET',
    notificationUnreadCount: 'GET',
    testNotification: 'POST',
    
    // Document endpoints
    documentsUpload: 'POST',
    myDocuments: 'GET',
    documents: 'GET',
    verificationStatus: 'GET',
    requiredDocuments: 'GET',
    
    // Rating endpoints
    ratings: 'GET', // GET for list, POST for create
    givenRatings: 'GET',
    receivedRatings: 'GET',
    reviews: 'GET', // GET for list, POST for create
    
    // System endpoints
    health: 'GET',
  };
}
