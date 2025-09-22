// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getNotificationStatsHash() =>
    r'd8da53a6780d32055f9d88f92688b72523f09603';

/// See also [getNotificationStats].
@ProviderFor(getNotificationStats)
final getNotificationStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  getNotificationStats,
  name: r'getNotificationStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getNotificationStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetNotificationStatsRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$notificationsHash() => r'31572d8a4dfae9643b9a9b7dc49a0953eec8568b';

/// See also [Notifications].
@ProviderFor(Notifications)
final notificationsProvider =
    AutoDisposeNotifierProvider<Notifications, NotificationState>.internal(
  Notifications.new,
  name: r'notificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Notifications = AutoDisposeNotifier<NotificationState>;
String _$legacyNotificationsHash() =>
    r'468b24c9e579a2a6b9b9a0e021047415f05c8ea0';

/// See also [LegacyNotifications].
@ProviderFor(LegacyNotifications)
final legacyNotificationsProvider = AutoDisposeNotifierProvider<
    LegacyNotifications, List<NotificationModel>>.internal(
  LegacyNotifications.new,
  name: r'legacyNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$legacyNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LegacyNotifications = AutoDisposeNotifier<List<NotificationModel>>;
String _$adminConversationsHash() =>
    r'131fc34721cb9212f04773a6d17b6c394419cd9c';

/// See also [AdminConversations].
@ProviderFor(AdminConversations)
final adminConversationsProvider = AutoDisposeNotifierProvider<
    AdminConversations, List<Map<String, dynamic>>>.internal(
  AdminConversations.new,
  name: r'adminConversationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminConversationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminConversations = AutoDisposeNotifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
