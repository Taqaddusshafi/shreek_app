import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/chat_model.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../main.dart';

part 'chat_provider.g.dart';

// ✅ ENHANCED: Chat State according to your API structure
class ChatState {
  final List<Message> messages;
  final List<ChatInfo> chatInfos;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int unreadCount;
  final int? activeChatId;
  final int? activeBookingId;
  final int? activeRideId;
  final Map<String, dynamic>? chatStats;

  ChatState({
    this.messages = const [],
    this.chatInfos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.unreadCount = 0,
    this.activeChatId,
    this.activeBookingId,
    this.activeRideId,
    this.chatStats,
  });

  ChatState copyWith({
    List<Message>? messages,
    List<ChatInfo>? chatInfos,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? unreadCount,
    int? activeChatId,
    int? activeBookingId,
    int? activeRideId,
    Map<String, dynamic>? chatStats,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      chatInfos: chatInfos ?? this.chatInfos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      activeChatId: activeChatId ?? this.activeChatId,
      activeBookingId: activeBookingId ?? this.activeBookingId,
      activeRideId: activeRideId ?? this.activeRideId,
      chatStats: chatStats ?? this.chatStats,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => chatInfos.isEmpty && !isLoading;
}

// ✅ FIXED: Chat Provider according to your Halawasl API
@riverpod
class Chat extends _$Chat {
  late DioClient _dioClient;

  @override
  ChatState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _dioClient = DioClient(prefs);
    return ChatState();
  }

  // ✅ FIXED: Load chat list using fromJson() method
  Future<void> loadChatList({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (kDebugMode) {
      print('🔍 Loading chat list, refresh: $refresh');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        'limit': 20,
        'offset': 0,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.chat,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> chatsJson = data['chats'] ?? data ?? [];
        
        if (kDebugMode) {
          print('📡 Received ${chatsJson.length} chats');
        }

        // ✅ FIXED: Use ChatInfo.fromJson() to handle all fields properly
        final chatInfos = chatsJson
            .map((json) => ChatInfo.fromJson(json))
            .toList();

        state = state.copyWith(
          chatInfos: chatInfos,
          isLoading: false,
        );

        if (kDebugMode) {
          print('✅ Chat list loaded successfully');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load chat list error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في جلب قائمة المحادثات',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading chat list: $e');
      }

      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ✅ FIXED: Get specific chat using your API structure
  Future<void> loadSpecificChat(int chatId) async {
    if (kDebugMode) {
      print('🔍 Loading specific chat: $chatId');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dioClient.dio.get(ApiConstants.chatById(chatId));

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        
        // Update the active chat
        state = state.copyWith(
          activeChatId: chatId,
          isLoading: false,
        );

        // Load messages for this chat
        await loadChatMessages(chatId: chatId);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load specific chat error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في جلب المحادثة',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading specific chat: $e');
      }

      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ✅ FIXED: Load chat messages using your API structure
  Future<void> loadChatMessages({
    int? chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (chatId == null) {
      if (kDebugMode) {
        print('⚠️ No chat ID provided for loading messages');
      }
      return;
    }

    final isInitialLoad = offset == 0;
    
    if (kDebugMode) {
      print('🔍 Loading chat messages for chat: $chatId, limit: $limit, offset: $offset');
    }

    state = state.copyWith(
      isLoading: isInitialLoad,
      isLoadingMore: !isInitialLoad,
      error: null,
    );

    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.chatMessagesById(chatId),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> messagesJson = data['messages'] ?? data ?? [];
        
        if (kDebugMode) {
          print('📡 Received ${messagesJson.length} messages');
        }

        final newMessages = messagesJson
            .map((json) => Message.fromJson(json))
            .toList();

        final updatedMessages = isInitialLoad
            ? newMessages
            : [...state.messages, ...newMessages];

        state = state.copyWith(
          messages: updatedMessages,
          activeChatId: chatId,
          isLoading: false,
          isLoadingMore: false,
        );

        if (kDebugMode) {
          print('✅ Chat messages loaded successfully');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load chat messages error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في جلب الرسائل',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading messages: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ✅ FIXED: Send message using your API structure
  Future<bool> sendMessage({
    required int chatId,
    required String message,
    String messageType = 'text',
  }) async {
    if (kDebugMode) {
      print('📤 Sending message to chat: $chatId');
      print('📤 Message: $message');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.chatMessagesById(chatId),
        data: {
          'message': message,
          'messageType': messageType,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final newMessage = Message.fromJson(data['message'] ?? data);
        
        // Add message to current messages
        state = state.copyWith(
          messages: [...state.messages, newMessage],
        );

        if (kDebugMode) {
          print('✅ Message sent successfully');
        }
        
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Send message error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'حدث خطأ في إرسال الرسالة',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error sending message: $e');
      }

      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ FIXED: Mark chat as read using your API structure
  Future<void> markChatAsRead(int chatId) async {
    if (kDebugMode) {
      print('✅ Marking chat as read: $chatId');
    }

    try {
      await _dioClient.dio.post(ApiConstants.markChatReadById(chatId));
      
      // Update local state
      final updatedChatInfos = state.chatInfos.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();

      // Calculate unread count reduction
      final chatToUpdate = state.chatInfos
          .where((chat) => chat.id == chatId)
          .firstOrNull;
      final unreadReduction = chatToUpdate?.unreadCount ?? 0;

      state = state.copyWith(
        chatInfos: updatedChatInfos,
        unreadCount: (state.unreadCount - unreadReduction).clamp(0, double.infinity).toInt(),
      );

      if (kDebugMode) {
        print('✅ Chat marked as read successfully');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Mark chat as read error: ${e.response?.statusCode}');
      }
      // Silently ignore errors for read status
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error marking chat as read: $e');
      }
      // Silently ignore errors for read status
    }
  }

  // ✅ FIXED: Get unread count using your API structure
  Future<void> loadUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.chatUnreadCount);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final unreadCount = data['unreadCount'] ?? data['count'] ?? 0;
        
        state = state.copyWith(unreadCount: unreadCount);

        if (kDebugMode) {
          print('✅ Unread count loaded: $unreadCount');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load unread count error: ${e.response?.statusCode}');
      }
      // Silently ignore unread count errors
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading unread count: $e');
      }
    }
  }

  // ✅ FIXED: Create chat for booking using your API structure
  Future<bool> createChatForBooking(int bookingId) async {
    if (kDebugMode) {
      print('🆕 Creating chat for booking: $bookingId');
    }

    try {
      final response = await _dioClient.dio.post(
        ApiConstants.createChatForBooking,
        data: {
          'bookingId': bookingId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final chatId = data['chatId'] ?? data['id'];
        
        if (chatId != null) {
          // Load the newly created chat
          await loadSpecificChat(chatId);
        }

        // Refresh chat list
        await loadChatList(refresh: true);

        if (kDebugMode) {
          print('✅ Chat created for booking successfully');
        }
        
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Create chat for booking error: ${e.response?.statusCode}');
        print('❌ Error data: ${e.response?.data}');
      }

      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'حدث خطأ في إنشاء المحادثة',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error creating chat: $e');
      }

      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ NEW: Load chat statistics
  Future<void> loadChatStats() async {
    if (kDebugMode) {
      print('📊 Loading chat statistics');
    }

    try {
      final response = await _dioClient.dio.get(ApiConstants.chatStats);

      if (response.statusCode == 200) {
        final stats = response.data['data'] ?? response.data;
        
        state = state.copyWith(chatStats: stats);

        if (kDebugMode) {
          print('✅ Chat stats loaded: $stats');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Load chat stats error: ${e.response?.statusCode}');
      }
      // Don't set error for stats, it's not critical
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading chat stats: $e');
      }
    }
  }

  // ✅ NEW: Search messages within a chat
  Future<void> searchMessages({
    required int chatId,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    if (kDebugMode) {
      print('🔍 Searching messages in chat: $chatId, query: $query');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = {
        'q': query,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dioClient.dio.get(
        '${ApiConstants.chatById(chatId)}/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> messagesJson = data['messages'] ?? data ?? [];

        final searchResults = messagesJson
            .map((json) => Message.fromJson(json))
            .toList();

        state = state.copyWith(
          messages: searchResults,
          isLoading: false,
        );

        if (kDebugMode) {
          print('✅ Found ${searchResults.length} messages matching query');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Search messages error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'حدث خطأ في البحث عن الرسائل',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error searching messages: $e');
      }

      state = state.copyWith(
        isLoading: false,
        error: 'حدث خطأ غير متوقع في البحث',
      );
    }
  }

  // ✅ NEW: Delete message
  Future<bool> deleteMessage(int messageId) async {
    if (kDebugMode) {
      print('🗑️ Deleting message: $messageId');
    }

    try {
      final response = await _dioClient.dio.delete(
        '${ApiConstants.chat}/messages/$messageId',
      );

      if (response.statusCode == 200) {
        // Remove message from current state
        final updatedMessages = state.messages
            .where((message) => message.id != messageId)
            .toList();

        state = state.copyWith(messages: updatedMessages);

        if (kDebugMode) {
          print('✅ Message deleted successfully');
        }
        
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Delete message error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'حدث خطأ في حذف الرسالة',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error deleting message: $e');
      }

      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ NEW: Archive chat
  Future<bool> archiveChat(int chatId) async {
    if (kDebugMode) {
      print('📁 Archiving chat: $chatId');
    }

    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.chatById(chatId)}/archive',
      );

      if (response.statusCode == 200) {
        // Remove from current chat list
        final updatedChatInfos = state.chatInfos
            .where((chat) => chat.id != chatId)
            .toList();

        state = state.copyWith(chatInfos: updatedChatInfos);

        if (kDebugMode) {
          print('✅ Chat archived successfully');
        }
        
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Archive chat error: ${e.response?.statusCode}');
      }

      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'حدث خطأ في أرشفة المحادثة',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error archiving chat: $e');
      }

      state = state.copyWith(error: 'حدث خطأ غير متوقع');
      return false;
    }
  }

  // ✅ NEW: Real-time message handling
  void addIncomingMessage(Message message) {
    if (kDebugMode) {
      print('📨 Incoming message for chat: ${message.chatId}');
    }

    // Only add if it's for the active chat
    if (state.activeChatId == message.chatId) {
      state = state.copyWith(
        messages: [...state.messages, message],
      );
    } else {
      // Increase unread count for other chats
      final updatedChatInfos = state.chatInfos.map((chat) {
        if (chat.id == message.chatId) {
          return chat.copyWith(
            unreadCount: chat.unreadCount + 1,
            lastMessage: message.content,
            lastMessageTime: message.createdAt,
          );
        }
        return chat;
      }).toList();

      state = state.copyWith(
        chatInfos: updatedChatInfos,
        unreadCount: state.unreadCount + 1,
      );
    }
  }

  // ✅ NEW: Update message status (read/delivered)
  void updateMessageStatus(int messageId, {bool? isRead, bool? isDelivered}) {
    final updatedMessages = state.messages.map((message) {
      if (message.id == messageId) {
        return message.copyWith(
          isRead: isRead ?? message.isRead,
          isDelivered: isDelivered ?? message.isDelivered,
        );
      }
      return message;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  // ✅ NEW: Get chat by ID from current state
  ChatInfo? getChatById(int chatId) {
    try {
      return state.chatInfos.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Get or create chat for booking
  Future<int?> getOrCreateChatForBooking(int bookingId) async {
    // First try to find existing chat
    final existingChat = state.chatInfos
        .where((chat) => chat.bookingId == bookingId)
        .firstOrNull;

    if (existingChat != null) {
      if (kDebugMode) {
        print('📋 Found existing chat for booking: ${existingChat.id}');
      }
      return existingChat.id;
    }

    // Create new chat if not found
    final success = await createChatForBooking(bookingId);
    if (success) {
      // Find the newly created chat
      final newChat = state.chatInfos
          .where((chat) => chat.bookingId == bookingId)
          .firstOrNull;
      return newChat?.id;
    }

    return null;
  }

  // ✅ Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!state.isLoadingMore && state.activeChatId != null) {
      await loadChatMessages(
        chatId: state.activeChatId!,
        offset: state.messages.length,
      );
    }
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
      activeChatId: null,
      activeBookingId: null,
      activeRideId: null,
    );
  }

  // ✅ Set active chat
  void setActiveChat(int chatId, {int? bookingId, int? rideId}) {
    state = state.copyWith(
      activeChatId: chatId,
      activeBookingId: bookingId,
      activeRideId: rideId,
    );
    
    // Mark as read when opening chat
    markChatAsRead(chatId);
  }

  // ✅ Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadChatList(refresh: true),
      loadUnreadCount(),
      loadChatStats(),
    ]);
  }

  // ✅ Initialize chat system
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🚀 Initializing chat system...');
    }

    await Future.wait([
      loadChatList(),
      loadUnreadCount(),
    ]);

    if (kDebugMode) {
      print('✅ Chat system initialized');
    }
  }
}

// ✅ FIXED: Convenience Providers with proper error handling
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

final isChatLoadingMoreProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isLoadingMore;
});

final chatErrorProvider = Provider<String?>((ref) {
  return ref.watch(chatProvider).error;
});

final hasChatErrorProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).hasError;
});

final chatStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(chatProvider).chatStats;
});

final activeChatIdProvider = Provider<int?>((ref) {
  return ref.watch(chatProvider).activeChatId;
});

final activeBookingIdProvider = Provider<int?>((ref) {
  return ref.watch(chatProvider).activeBookingId;
});

final activeChatInfoProvider = Provider<ChatInfo?>((ref) {
  final state = ref.watch(chatProvider);
  if (state.activeChatId == null) return null;
  
  try {
    return state.chatInfos.firstWhere((chat) => chat.id == state.activeChatId);
  } catch (e) {
    return null;
  }
});
