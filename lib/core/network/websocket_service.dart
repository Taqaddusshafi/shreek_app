import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shreek_app/core/constants/api_constants.dart';
import 'package:shreek_app/main.dart';
import 'package:shreek_app/models/chat_model.dart';
import 'package:shreek_app/models/notification_model.dart';
import 'package:shreek_app/providers/booking_provider.dart';
import 'package:shreek_app/providers/chat_provider.dart';
import 'package:shreek_app/providers/notification_provider.dart';
import 'package:shreek_app/providers/ride_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? _socket;
  final Ref _ref;
  bool _isConnecting = false;

  WebSocketService(this._ref);

  Future<void> connect() async {
    if (_isConnecting || (_socket?.connected ?? false)) return;
    
    _isConnecting = true;
    
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        _isConnecting = false;
        return;
      }

      // ✅ FIXED: Correct socket.io options configuration
      _socket = IO.io(
        ApiConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setTimeout(30000)
            .disableAutoConnect()           // Manual connection control
            .enableReconnection()           // Enable reconnection
            .enableForceNew()               // Force new connection
            .build(),
      );

      _setupEventListeners();
      _socket?.connect();
      
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection error: $e');
      }
      _isConnecting = false;
    }
  }

  void _setupEventListeners() {
    // Connection Events
    _socket?.on('connect', (_) {
      if (kDebugMode) {
        print('✅ WebSocket connected to ${ApiConstants.wsUrl}');
      }
      _isConnecting = false;
    });

    _socket?.on('disconnect', (reason) {
      if (kDebugMode) {
        print('❌ WebSocket disconnected: $reason');
      }
      _isConnecting = false;
    });

    _socket?.on('error', (error) {
      if (kDebugMode) {
        print('🚨 WebSocket error: $error');
      }
      _isConnecting = false;
    });

    _socket?.on('reconnect', (attempt) {
      if (kDebugMode) {
        print('🔄 WebSocket reconnected (attempt: $attempt)');
      }
    });

    // ✅ FIXED: Chat Events with correct method names
    _socket?.on('new_message', (data) {
      try {
        final message = Message.fromJson(data);
        _ref.read(chatProvider.notifier).addIncomingMessage(message); // ✅ FIXED: Use correct method
      } catch (e) {
        if (kDebugMode) {
          print('Error handling new message: $e');
        }
      }
    });

    _socket?.on('conversation_created', (data) {
      try {
        // ✅ FIXED: Use correct method name
        _ref.read(chatProvider.notifier).loadChatList();
      } catch (e) {
        if (kDebugMode) {
          print('Error handling new conversation: $e');
        }
      }
    });

    _socket?.on('message_read', (data) {
      try {
        // ✅ FIXED: Use correct method name
        _ref.read(chatProvider.notifier).loadChatList();
      } catch (e) {
        if (kDebugMode) {
          print('Error handling message read: $e');
        }
      }
    });

    // ✅ Notification Events
    _socket?.on('new_notification', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        _ref.read(notificationsProvider.notifier).loadNotifications();
      } catch (e) {
        if (kDebugMode) {
          print('Error handling new notification: $e');
        }
      }
    });

    // ✅ Ride Events
    _socket?.on('ride_updated', (data) {
      try {
        _ref.read(myRidesProvider.notifier).loadMyRides();
        _ref.read(rideSearchProvider.notifier).clearRides();
      } catch (e) {
        if (kDebugMode) {
          print('Error handling ride update: $e');
        }
      }
    });

    // ✅ Booking Events
    _socket?.on('booking_status_changed', (data) {
      try {
        _ref.read(myBookingsProvider.notifier).loadMyBookings();
      } catch (e) {
        if (kDebugMode) {
          print('Error handling booking status change: $e');
        }
      }
    });

    _socket?.on('ride_booking_received', (data) {
      try {
        _ref.read(notificationsProvider.notifier).loadNotifications();
        _ref.read(myRidesProvider.notifier).loadMyRides();
      } catch (e) {
        if (kDebugMode) {
          print('Error handling ride booking: $e');
        }
      }
    });

    // ✅ Typing Events
    _socket?.on('user_typing', (data) {
      // Handle typing indicators in chat UI
      if (kDebugMode) {
        print('User typing: $data');
      }
    });

    _socket?.on('user_stopped_typing', (data) {
      // Handle stop typing indicators
      if (kDebugMode) {
        print('User stopped typing: $data');
      }
    });
  }

  // ✅ Chat Methods
  void joinConversation(String conversationId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('join_conversation', conversationId);
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('leave_conversation', conversationId);
    }
  }

  void sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
  }) {
    if (_socket?.connected ?? false) {
      _socket?.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType,
      });
    }
  }

  void markMessageAsRead(String messageId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('mark_message_read', messageId);
    }
  }

  void startTyping(String conversationId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('start_typing', conversationId);
    }
  }

  void stopTyping(String conversationId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('stop_typing', conversationId);
    }
  }

  // ✅ Ride Methods
  void joinRide(String rideId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('join_ride', rideId);
    }
  }

  void leaveRide(String rideId) {
    if (_socket?.connected ?? false) {
      _socket?.emit('leave_ride', rideId);
    }
  }

  void updateLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) {
    if (_socket?.connected ?? false) {
      _socket?.emit('update_location', {
        'rideId': rideId,
        'latitude': latitude,
        'longitude': longitude,
      });
    }
  }

  // ✅ Booking Methods
  void updateBookingStatus({
    required String bookingId,
    required String status,
  }) {
    if (_socket?.connected ?? false) {
      _socket?.emit('update_booking_status', {
        'bookingId': bookingId,
        'status': status,
      });
    }
  }

  // ✅ Connection Management
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
  }

  void reconnect() {
    disconnect();
    connect();
  }

  // ✅ Getters
  bool get isConnected => _socket?.connected ?? false;
  bool get isConnecting => _isConnecting;
  String get connectionStatus {
    if (isConnecting) return 'Connecting...';
    if (isConnected) return 'Connected';
    return 'Disconnected';
  }
}

// ✅ WebSocket Providers
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});

final webSocketConnectionProvider = StateProvider<bool>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.isConnected;
});
