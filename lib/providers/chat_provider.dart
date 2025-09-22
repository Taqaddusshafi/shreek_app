import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/chat_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'chat_provider.g.dart';

// ✅ UPDATED: Enhanced Chat State
class ChatState {
  final List<Message> messages;
  final List<ChatInfo> chatInfos;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final int? activeBookingId;

  ChatState({
    this.messages = const [],
    this.chatInfos = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.activeBookingId,
  });

  ChatState copyWith({
    List<Message>? messages,
    List<ChatInfo>? chatInfos,
    bool? isLoading,
    String? error,
    int? unreadCount,
    int? activeBookingId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      chatInfos: chatInfos ?? this.chatInfos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      activeBookingId: activeBookingId ?? this.activeBookingId,
    );
  }
}

// Chat Provider - Updated for new Halawasl API structure
@riverpod
class Chat extends _$Chat {
  late DioClient _dioClient;

  @override
  ChatState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return ChatState();
  }

  // ✅ FIXED: Renamed from loadConversations to loadChatList
  Future<void> loadChatList() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.get(ApiConstants.chat);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> chatsJson = data['chats'] ?? data ?? [];
        
        final chatInfos = chatsJson.map((json) {
          return ChatInfo(
            bookingId: json['bookingId'],
            rideId: json['rideId'],
            participantName: json['participantName'] ?? json['otherUserName'] ?? 'مستخدم',
            participantImage: json['participantImage'] ?? json['otherUserImage'],
            lastMessageContent: json['lastMessage']?['content'] ?? json['lastMessageContent'],
            lastMessageTime: json['lastMessage']?['createdAt'] != null 
                ? DateTime.parse(json['lastMessage']['createdAt'])
                : (json['lastMessageTime'] != null 
                    ? DateTime.parse(json['lastMessageTime'])
                    : null),
            unreadCount: json['unreadCount'] ?? 0,
          );
        }).toList();

        state = state.copyWith(
          chatInfos: chatInfos,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب قائمة المحادثات',
      );
    }
  }

  // ✅ FIXED: Load chat messages using new API structure
  Future<void> loadChatMessages({
    int? bookingId,
    int? rideId,
    int limit = 50,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        if (bookingId != null) 'bookingId': bookingId,
        if (rideId != null) 'rideId': rideId,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.chat,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> messagesJson = data['messages'] ?? data ?? [];
        
        final messages = messagesJson
            .map((json) => Message.fromJson(json))
            .toList();

        state = state.copyWith(
          messages: messages,
          isLoading: false,
          activeBookingId: bookingId,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'حدث خطأ في جلب الرسائل',
      );
    }
  }

  // ✅ FIXED: Send message using new API structure
  Future<bool> sendMessage({
    required String content,
    int? bookingId,
    int? rideId,
    String messageType = 'text',
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.chat,
        data: {
          'content': content,
          'messageType': messageType,
          if (bookingId != null) 'bookingId': bookingId,
          if (rideId != null) 'rideId': rideId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final message = Message.fromJson(data['message'] ?? data);
        
        // Add message to current messages
        state = state.copyWith(
          messages: [...state.messages, message],
        );
        
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في إرسال الرسالة',
      );
      return false;
    }
  }

  // ✅ NEW: Create chat for booking
  Future<bool> createChatForBooking(int bookingId) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.createChatForBooking,
        data: {'bookingId': bookingId},
      );

      if (response.statusCode == 200) {
        // Load messages for this booking
        await loadChatMessages(bookingId: bookingId);
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'حدث خطأ في إنشاء المحادثة',
      );
      return false;
    }
  }

  // ✅ FIXED: Get unread count
  Future<void> loadUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.chatUnreadCount);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final unreadCount = data['unreadCount'] ?? data['count'] ?? 0;
        
        state = state.copyWith(unreadCount: unreadCount);
      }
    } on DioException catch (e) {
      // Silently ignore unread count errors
    }
  }

  // ✅ NEW: Mark chat as read
  Future<void> markChatAsRead({int? bookingId, int? rideId}) async {
    try {
      final params = {
        if (bookingId != null) 'bookingId': bookingId,
        if (rideId != null) 'rideId': rideId,
      };
      
      await _dioClient.dio.patch(
        '${ApiConstants.chat}/read',
        data: params,
      );
      
      // Refresh chat list to update unread counts
      await loadChatList();
    } on DioException catch (e) {
      // Silently ignore errors
    }
  }

  // ✅ NEW: Real-time message handling - replaces addMessage
  void addIncomingMessage(Message message) {
    // Only add if it's for the active chat
    if (state.activeBookingId == message.bookingId) {
      state = state.copyWith(
        messages: [...state.messages, message],
      );
    } else {
      // Increase unread count for other chats
      state = state.copyWith(
        unreadCount: state.unreadCount + 1,
      );
    }
  }

  // ✅ DEPRECATED: Keep for backward compatibility - just calls addIncomingMessage
  void addMessage(Message message) {
    addIncomingMessage(message);
  }

  // ✅ Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // ✅ Clear active chat
  void clearActiveChat() {
    state = state.copyWith(
      messages: [],
      activeBookingId: null,
    );
  }
}

// ✅ NEW: Chat Statistics Provider
@riverpod
Future<Map<String, dynamic>> getChatStats(GetChatStatsRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final dioClient = DioClient(prefs);

  try {
    final response = await dioClient.dio.get(ApiConstants.chatStats);
    
    if (response.statusCode == 200) {
      return response.data['data'] ?? response.data;
    }
    return {};
  } on DioException catch (e) {
    throw e.response?.data['message'] ?? 'حدث خطأ في جلب إحصائيات المحادثات';
  }
}

// ✅ NEW: Convenience providers
final chatUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(chatProvider).unreadCount;
});

final activeChatMessagesProvider = Provider<List<Message>>((ref) {
  return ref.watch(chatProvider).messages;
});

final chatListProvider = Provider<List<ChatInfo>>((ref) {
  return ref.watch(chatProvider).chatInfos;
});

final isChatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isLoading;
});
