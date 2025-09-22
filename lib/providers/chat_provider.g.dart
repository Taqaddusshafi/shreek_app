// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getChatStatsHash() => r'1c955397a19d71e16b7d84ad895d3d4330ee3ef4';

/// See also [getChatStats].
@ProviderFor(getChatStats)
final getChatStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  getChatStats,
  name: r'getChatStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$getChatStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetChatStatsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$chatHash() => r'4187733b8bbc45f5957ed663a00b20392e72bb49';

/// See also [Chat].
@ProviderFor(Chat)
final chatProvider = AutoDisposeNotifierProvider<Chat, ChatState>.internal(
  Chat.new,
  name: r'chatProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Chat = AutoDisposeNotifier<ChatState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
