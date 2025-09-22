import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/notification_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'notification_provider.g.dart';

// Notification State
class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final int unreadChatCount;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.unreadChatCount = 0,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    int? unreadChatCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadChatCount: unreadChatCount ?? this.unreadChatCount,
    );
  }

  // ✅ FIXED: Add convenience getters to NotificationState
  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      notifications.where((n) => n.isRead).toList();

  bool get hasUnreadNotifications => unreadCount > 0;
  bool get hasUnreadChats => unreadChatCount > 0;
  int get totalUnreadCount => unreadCount + unreadChatCount;
  bool get hasError => error != null;
  
  // ✅ NEW: Additional convenience getters
  int get readCount => notifications.where((n) => n.isRead).length;
  int get totalNotificationCount => notifications.length;
  bool get isEmpty => notifications.isEmpty;
  bool get isNotEmpty => notifications.isNotEmpty;
}

// Notifications Provider
@riverpod
class Notifications extends _$Notifications {
  late DioClient _dioClient;

  @override
  NotificationState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return NotificationState();
  }

  Future<void> loadNotifications({
    String? type,
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        if (type != null) 'type': type,
        if (isRead != null) 'isRead': isRead,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.notifications,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> notificationsJson = data is List 
            ? data 
            : data['notifications'] ?? [];
            
        final notifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Also get unread count from the response
        final unreadCount = data['unreadCount'] ?? 
                           notifications.where((n) => !n.isRead).length;

        state = state.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الإشعارات',
      );
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.notificationUnreadCount);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final unreadCount = data['unreadCount'] ?? data['count'] ?? 0;
        
        state = state.copyWith(unreadCount: unreadCount);
      }
    } on DioException catch (_) {
      // Silently ignore unread count errors
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.notifications}/$notificationId/read',
      );

      if (response.statusCode == 200) {
        // Update notification in local list
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في تحديث الإشعار',
      );
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.notifications}/read-all',
      );

      if (response.statusCode == 200) {
        // Update all notifications in list
        final updatedNotifications = state.notifications
            .map((notification) => notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            ))
            .toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في تحديث الإشعارات',
      );
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _dioClient.dio.delete(
        '${ApiConstants.notifications}/$notificationId',
      );

      if (response.statusCode == 200) {
        // Remove notification from local list
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != notificationId)
            .toList();

        // Update unread count if the deleted notification was unread
        final deletedNotification = state.notifications
            .firstWhere((n) => n.id == notificationId);
        final newUnreadCount = deletedNotification.isRead 
            ? state.unreadCount 
            : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في حذف الإشعار',
      );
      return false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    try {
      final response = await _dioClient.dio.delete(ApiConstants.notifications);

      if (response.statusCode == 200) {
        state = state.copyWith(
          notifications: [],
          unreadCount: 0,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في حذف الإشعارات',
      );
      return false;
    }
  }

  Future<void> loadChatUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.chatUnreadCount);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final unreadChatCount = data['unreadCount'] ?? data['count'] ?? 0;
        
        state = state.copyWith(unreadChatCount: unreadChatCount);
      }
    } on DioException catch (_) {
      // Silently ignore chat unread count errors
    }
  }

  Future<bool> sendTestNotification() async {
    try {
      final response = await _dioClient.dio.post(ApiConstants.testNotification);
      return response.statusCode == 200;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في إرسال الإشعار التجريبي',
      );
      return false;
    }
  }

  void addNotification(NotificationModel notification) {
    final updatedNotifications = [notification, ...state.notifications];
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: notification.isRead ? state.unreadCount : state.unreadCount + 1,
    );
  }

  void updateUnreadChatCount(int count) {
    state = state.copyWith(unreadChatCount: count);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> loadAllUnreadCounts() async {
    await Future.wait([
      loadUnreadCount(),
      loadChatUnreadCount(),
    ]);
  }

  // ✅ NEW: Filter notifications by type
  Future<void> loadNotificationsByType(String type) async {
    await loadNotifications(type: type);
  }

  // ✅ NEW: Load only unread notifications
  Future<void> loadUnreadNotificationsOnly() async {
    await loadNotifications(isRead: false);
  }

  // ✅ NEW: Load only read notifications
  Future<void> loadReadNotificationsOnly() async {
    await loadNotifications(isRead: true);
  }

  // ✅ NEW: Mark notification as unread (if API supports it)
  Future<bool> markAsUnread(int notificationId) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.notifications}/$notificationId/unread',
      );

      if (response.statusCode == 200) {
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(
              isRead: false,
              readAt: null,
            );
          }
          return notification;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount + 1,
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في تحديث الإشعار',
      );
      return false;
    }
  }
}

// ✅ Legacy Notifications Provider (if needed)
@riverpod
class LegacyNotifications extends _$LegacyNotifications {
  late DioClient _dioClient;

  @override
  List<NotificationModel> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return [];
  }

  Future<void> loadLegacyNotifications() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.legacyNotifications);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        
        final notifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        state = notifications;
      }
    } on DioException catch (e) {
      // Handle error silently for legacy notifications
    }
  }
}

// ✅ Admin Conversations Provider
@riverpod
class AdminConversations extends _$AdminConversations {
  late DioClient _dioClient;

  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return [];
  }

  Future<void> loadAdminConversations() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminConversations);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> conversationsJson = data['conversations'] ?? [];
        
        state = conversationsJson.cast<Map<String, dynamic>>();
      }
    } on DioException catch (e) {
      // Handle error
    }
  }

  Future<int> loadAdminMessagesUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.adminMessagesUnreadCount);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return data['unreadCount'] ?? 0;
      }
    } on DioException catch (e) {
      // Handle error
    }
    return 0;
  }
}

// ✅ Notification Statistics Provider
@riverpod
Future<Map<String, dynamic>> getNotificationStats(GetNotificationStatsRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get(ApiConstants.notificationStats);
    
    if (response.statusCode == 200) {
      return response.data['data'] ?? response.data;
    }
    return {};
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? 'حدث خطأ في جلب إحصائيات الإشعارات';
  }
}

// ✅ FIXED: Convenience providers using state getters
final unreadCountProvider = Provider<int>((ref) => 
    ref.watch(notificationsProvider).unreadCount);
    
final unreadChatCountProvider = Provider<int>((ref) => 
    ref.watch(notificationsProvider).unreadChatCount);

final totalUnreadCountProvider = Provider<int>((ref) => 
    ref.watch(notificationsProvider).totalUnreadCount);

final hasUnreadNotificationsProvider = Provider<bool>((ref) => 
    ref.watch(notificationsProvider).hasUnreadNotifications);

final hasUnreadChatsProvider = Provider<bool>((ref) => 
    ref.watch(notificationsProvider).hasUnreadChats);

// ✅ FIXED: Access unreadNotifications from state
final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) => 
    ref.watch(notificationsProvider).unreadNotifications);

final readNotificationsProvider = Provider<List<NotificationModel>>((ref) => 
    ref.watch(notificationsProvider).readNotifications);

final allNotificationsProvider = Provider<List<NotificationModel>>((ref) => 
    ref.watch(notificationsProvider).notifications);

final notificationLoadingProvider = Provider<bool>((ref) => 
    ref.watch(notificationsProvider).isLoading);

final notificationErrorProvider = Provider<String?>((ref) => 
    ref.watch(notificationsProvider).error);

final hasNotificationErrorProvider = Provider<bool>((ref) => 
    ref.watch(notificationsProvider).hasError);

final notificationCountProvider = Provider<int>((ref) => 
    ref.watch(notificationsProvider).totalNotificationCount);

final isNotificationEmptyProvider = Provider<bool>((ref) => 
    ref.watch(notificationsProvider).isEmpty);

// ✅ NEW: Notification type filters
final rideBookingNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationsProvider).notifications;
  return notifications.where((n) => n.isRideBooking).toList();
});

final systemNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationsProvider).notifications;
  return notifications.where((n) => n.isSystemNotification).toList();
});

final messageNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationsProvider).notifications;
  return notifications.where((n) => n.isMessage).toList();
});
