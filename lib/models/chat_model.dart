import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// ✅ ENHANCED: Message Model - Complete with all API fields
class Message {
  final int id;
  final int chatId; // ✅ ADDED: Chat ID for message grouping
  final String content;
  final String messageType;
  final int senderId;
  final String? senderName;
  final String? senderAvatar;
  final int? recipientId;
  final String? recipientName;
  final int? bookingId;
  final int? rideId;
  final bool isRead;
  final bool isDelivered;
  final bool isEdited;
  final String? editedAt;
  final String? replyToId;
  final String? attachmentUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.content,
    required this.messageType,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    this.recipientId,
    this.recipientName,
    this.bookingId,
    this.rideId,
    required this.isRead,
    this.isDelivered = false,
    this.isEdited = false,
    this.editedAt,
    this.replyToId,
    this.attachmentUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ ENHANCED: Robust factory method with comprehensive null safety
  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: _parseInteger(json['id']) ?? 0,
        chatId: _parseInteger(json['chatId']) ?? 0,
        content: json['content']?.toString() ?? '',
        messageType: json['messageType']?.toString() ?? 'text',
        senderId: _parseInteger(json['senderId']) ?? 0,
        senderName: json['senderName']?.toString() ?? 
                   json['sender']?['name']?.toString(),
        senderAvatar: json['senderAvatar']?.toString() ?? 
                     json['sender']?['profileImageUrl']?.toString(),
        recipientId: _parseInteger(json['recipientId']) ?? 
                    _parseInteger(json['recipient']?['id']),
        recipientName: json['recipientName']?.toString() ?? 
                      json['recipient']?['name']?.toString(),
        bookingId: _parseInteger(json['bookingId']),
        rideId: _parseInteger(json['rideId']),
        isRead: json['isRead'] == true,
        isDelivered: json['isDelivered'] == true,
        isEdited: json['isEdited'] == true,
        editedAt: json['editedAt']?.toString(),
        replyToId: json['replyToId']?.toString(),
        attachmentUrl: json['attachmentUrl']?.toString(),
        metadata: json['metadata'] is Map<String, dynamic> 
            ? json['metadata'] 
            : null,
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing Message from JSON: $e');
        print('❌ JSON data: $json');
      }
      rethrow;
    }
  }

  // ✅ ENHANCED: Complete toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'content': content,
      'messageType': messageType,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'bookingId': bookingId,
      'rideId': rideId,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'replyToId': replyToId,
      'attachmentUrl': attachmentUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ✅ ENHANCED: Complete copyWith method
  Message copyWith({
    int? id,
    int? chatId,
    String? content,
    String? messageType,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    int? recipientId,
    String? recipientName,
    int? bookingId,
    int? rideId,
    bool? isRead,
    bool? isDelivered,
    bool? isEdited,
    String? editedAt,
    String? replyToId,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      bookingId: bookingId ?? this.bookingId,
      rideId: rideId ?? this.rideId,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ ENHANCED: Message type helpers
  bool get isTextMessage => messageType.toLowerCase() == 'text';
  bool get isImageMessage => messageType.toLowerCase() == 'image';
  bool get isLocationMessage => messageType.toLowerCase() == 'location';
  bool get isFileMessage => messageType.toLowerCase() == 'file';
  bool get isSystemMessage => messageType.toLowerCase() == 'system';
  bool get isBookingMessage => messageType.toLowerCase() == 'booking';
  bool get isRideMessage => messageType.toLowerCase() == 'ride';
  
  // ✅ ENHANCED: Status helpers
  bool get isUnread => !isRead;
  bool get isPending => !isDelivered;
  bool get canEdit => senderId > 0 && !isEdited && isTextMessage;
  bool get hasAttachment => attachmentUrl?.isNotEmpty == true;
  
  // ✅ ENHANCED: Display helpers
  String get displaySenderName => senderName ?? 'مستخدم غير معروف';
  
  String get timeDisplay {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      // Today - show time only
      return DateFormat('HH:mm', 'ar').format(createdAt);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'أمس ${DateFormat('HH:mm', 'ar').format(createdAt)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return '${DateFormat('EEEE HH:mm', 'ar').format(createdAt)}';
    } else {
      // Older - show date and time
      return DateFormat('dd/MM/yyyy HH:mm', 'ar').format(createdAt);
    }
  }
  
  String get shortTimeDisplay {
    return DateFormat('HH:mm', 'ar').format(createdAt);
  }
  
  String get dateDisplay {
    return DateFormat('dd/MM/yyyy', 'ar').format(createdAt);
  }
  
  String get fullTimeDisplay {
    return DateFormat('dd/MM/yyyy HH:mm', 'ar').format(createdAt);
  }
  
  // ✅ ENHANCED: Content helpers
  String get displayContent {
    if (isTextMessage) return content;
    if (isImageMessage) return '📷 صورة';
    if (isLocationMessage) return '📍 موقع';
    if (isFileMessage) return '📎 ملف';
    if (isSystemMessage) return content;
    if (isBookingMessage) return '🎫 رسالة حجز';
    if (isRideMessage) return '🚗 رسالة رحلة';
    return content;
  }
  
  String get previewContent {
    if (content.length > 50) {
      return '${content.substring(0, 47)}...';
    }
    return displayContent;
  }
  
  // ✅ NEW: Message status for UI
  String get statusIcon {
    if (isSystemMessage) return '';
    if (!isDelivered) return '⏳'; // Pending
    if (!isRead) return '✓'; // Delivered but not read
    return '✓✓'; // Read
  }
  
  // ✅ NEW: Message context
  String get contextDisplay {
    if (bookingId != null) return 'حجز #$bookingId';
    if (rideId != null) return 'رحلة #$rideId';
    return '';
  }
  
  // ✅ Static helper methods for parsing
  static int? _parseInteger(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
  
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parsing DateTime from string: $value');
        }
        return null;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message{id: $id, chatId: $chatId, senderId: $senderId, content: "${content.length > 20 ? content.substring(0, 20) + "..." : content}", messageType: $messageType}';
  }
}

// ✅ ENHANCED: ChatInfo Model - Complete with all API fields
class ChatInfo {
  final int id;
  final int rideId;
  final int participant1Id;
  final int participant2Id;
  final String? participant1Name;
  final String? participant2Name;
  final String? participant1Avatar;
  final String? participant2Avatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ ENHANCED: Additional fields from API
  final int? bookingId;
  final String? rideFromCity;
  final String? rideToCity;
  final DateTime? rideDepartureDate;
  final String? rideStatus;

  ChatInfo({
    required this.id,
    required this.rideId,
    required this.participant1Id,
    required this.participant2Id,
    this.participant1Name,
    this.participant2Name,
    this.participant1Avatar,
    this.participant2Avatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    // Enhanced fields
    this.bookingId,
    this.rideFromCity,
    this.rideToCity,
    this.rideDepartureDate,
    this.rideStatus,
  });

  // ✅ ENHANCED: Robust factory method
  factory ChatInfo.fromJson(Map<String, dynamic> json) {
    try {
      return ChatInfo(
        id: Message._parseInteger(json['id']) ?? 0,
        rideId: Message._parseInteger(json['rideId']) ?? 0,
        participant1Id: Message._parseInteger(json['participant1Id']) ?? 0,
        participant2Id: Message._parseInteger(json['participant2Id']) ?? 0,
        participant1Name: json['participant1Name']?.toString() ?? 
                         json['participant1']?['name']?.toString(),
        participant2Name: json['participant2Name']?.toString() ?? 
                         json['participant2']?['name']?.toString(),
        participant1Avatar: json['participant1Avatar']?.toString() ?? 
                          json['participant1']?['profileImageUrl']?.toString(),
        participant2Avatar: json['participant2Avatar']?.toString() ?? 
                          json['participant2']?['profileImageUrl']?.toString(),
        lastMessage: json['lastMessage']?.toString(),
        lastMessageTime: Message._parseDateTime(json['lastMessageTime']),
        unreadCount: Message._parseInteger(json['unreadCount']) ?? 0,
        isActive: json['isActive'] == true,
        isArchived: json['isArchived'] == true,
        createdAt: Message._parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: Message._parseDateTime(json['updatedAt']) ?? DateTime.now(),
        // Enhanced fields
        bookingId: Message._parseInteger(json['bookingId']) ?? 
                  Message._parseInteger(json['booking']?['id']),
        rideFromCity: json['rideFromCity']?.toString() ?? 
                     json['ride']?['fromCity']?.toString(),
        rideToCity: json['rideToCity']?.toString() ?? 
                   json['ride']?['toCity']?.toString(),
        rideDepartureDate: Message._parseDateTime(json['rideDepartureDate']) ?? 
                         Message._parseDateTime(json['ride']?['departureDate']),
        rideStatus: json['rideStatus']?.toString() ?? 
                   json['ride']?['status']?.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing ChatInfo from JSON: $e');
        print('❌ JSON data: $json');
      }
      rethrow;
    }
  }

  // ✅ ENHANCED: Complete toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      'participant1Name': participant1Name,
      'participant2Name': participant2Name,
      'participant1Avatar': participant1Avatar,
      'participant2Avatar': participant2Avatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Enhanced fields
      'bookingId': bookingId,
      'rideFromCity': rideFromCity,
      'rideToCity': rideToCity,
      'rideDepartureDate': rideDepartureDate?.toIso8601String(),
      'rideStatus': rideStatus,
    };
  }

  // ✅ ENHANCED: Complete copyWith method
  ChatInfo copyWith({
    int? id,
    int? rideId,
    int? participant1Id,
    int? participant2Id,
    String? participant1Name,
    String? participant2Name,
    String? participant1Avatar,
    String? participant2Avatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Enhanced fields
    int? bookingId,
    String? rideFromCity,
    String? rideToCity,
    DateTime? rideDepartureDate,
    String? rideStatus,
  }) {
    return ChatInfo(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      participant1Name: participant1Name ?? this.participant1Name,
      participant2Name: participant2Name ?? this.participant2Name,
      participant1Avatar: participant1Avatar ?? this.participant1Avatar,
      participant2Avatar: participant2Avatar ?? this.participant2Avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Enhanced fields
      bookingId: bookingId ?? this.bookingId,
      rideFromCity: rideFromCity ?? this.rideFromCity,
      rideToCity: rideToCity ?? this.rideToCity,
      rideDepartureDate: rideDepartureDate ?? this.rideDepartureDate,
      rideStatus: rideStatus ?? this.rideStatus,
    );
  }

  // ✅ ENHANCED: Helper getters
  bool get hasUnread => unreadCount > 0;
  bool get isInactive => !isActive;
  
  // ✅ ENHANCED: Participant helpers
  String getParticipantName(int currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Name ?? 'مستخدم غير معروف';
    }
    return participant1Name ?? 'مستخدم غير معروف';
  }
  
  String? getParticipantAvatar(int currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Avatar;
    }
    return participant1Avatar;
  }
  
  int getOtherParticipantId(int currentUserId) {
    if (participant1Id == currentUserId) {
      return participant2Id;
    }
    return participant1Id;
  }
  
  // ✅ ENHANCED: Display helpers
  String get displayTitle => 'محادثة #$id';
  
  String get rideRoute {
    if (rideFromCity != null && rideToCity != null) {
      return '$rideFromCity → $rideToCity';
    }
    return 'رحلة #$rideId';
  }
  
  String get contextInfo {
    final parts = <String>[];
    
    if (bookingId != null) {
      parts.add('حجز #$bookingId');
    }
    
    if (rideFromCity != null && rideToCity != null) {
      parts.add('$rideFromCity → $rideToCity');
    }
    
    if (rideDepartureDate != null) {
      final dateStr = DateFormat('dd/MM', 'ar').format(rideDepartureDate!);
      parts.add(dateStr);
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'رحلة #$rideId';
  }
  
  String get lastMessageDisplay {
    if (lastMessage?.isEmpty ?? true) return 'لا توجد رسائل';
    if (lastMessage!.length > 30) {
      return '${lastMessage!.substring(0, 27)}...';
    }
    return lastMessage!;
  }
  
  String get lastMessageTimeDisplay {
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} د';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm', 'ar').format(lastMessageTime!);
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'ar').format(lastMessageTime!);
    } else {
      return DateFormat('dd/MM', 'ar').format(lastMessageTime!);
    }
  }
  
  // ✅ NEW: Status helpers
  bool get isRideActive => rideStatus?.toLowerCase() == 'active';
  bool get isRideCompleted => rideStatus?.toLowerCase() == 'completed';
  bool get isRideCancelled => rideStatus?.toLowerCase() == 'cancelled';
  
  // ✅ NEW: Empty instance for fallback
  static ChatInfo empty() {
    return ChatInfo(
      id: 0,
      rideId: 0,
      participant1Id: 0,
      participant2Id: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatInfo{id: $id, rideId: $rideId, participants: $participant1Id<->$participant2Id, unread: $unreadCount}';
  }
}

// ✅ DEPRECATED: Keep for backward compatibility - just an alias to ChatInfo
@Deprecated('Use ChatInfo instead')
class Conversation extends ChatInfo {
  Conversation({
    required super.id,
    required super.rideId,
    required super.participant1Id,
    required super.participant2Id,
    super.participant1Name,
    super.participant2Name,
    super.participant1Avatar,
    super.participant2Avatar,
    super.lastMessage,
    super.lastMessageTime,
    super.unreadCount = 0,
    super.isActive = true,
    super.isArchived = false,
    required super.createdAt,
    required super.updatedAt,
    super.bookingId,
    super.rideFromCity,
    super.rideToCity,
    super.rideDepartureDate,
    super.rideStatus,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final chatInfo = ChatInfo.fromJson(json);
    return Conversation(
      id: chatInfo.id,
      rideId: chatInfo.rideId,
      participant1Id: chatInfo.participant1Id,
      participant2Id: chatInfo.participant2Id,
      participant1Name: chatInfo.participant1Name,
      participant2Name: chatInfo.participant2Name,
      participant1Avatar: chatInfo.participant1Avatar,
      participant2Avatar: chatInfo.participant2Avatar,
      lastMessage: chatInfo.lastMessage,
      lastMessageTime: chatInfo.lastMessageTime,
      unreadCount: chatInfo.unreadCount,
      isActive: chatInfo.isActive,
      isArchived: chatInfo.isArchived,
      createdAt: chatInfo.createdAt,
      updatedAt: chatInfo.updatedAt,
      bookingId: chatInfo.bookingId,
      rideFromCity: chatInfo.rideFromCity,
      rideToCity: chatInfo.rideToCity,
      rideDepartureDate: chatInfo.rideDepartureDate,
      rideStatus: chatInfo.rideStatus,
    );
  }

  // Legacy getters for backward compatibility
  String get participantName => getParticipantName(0);
  String? get participantImage => participant1Avatar ?? participant2Avatar;
  String? get lastMessageContent => lastMessage;
  String get chatId => 'chat_$id';
}

// ✅ NEW: Chat Statistics Model
class ChatStats {
  final int totalChats;
  final int activeChats;
  final int archivedChats;
  final int totalMessages;
  final int unreadMessages;
  final double avgResponseTime;
  final DateTime lastUpdated;

  ChatStats({
    required this.totalChats,
    required this.activeChats,
    required this.archivedChats,
    required this.totalMessages,
    required this.unreadMessages,
    required this.avgResponseTime,
    required this.lastUpdated,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    return ChatStats(
      totalChats: Message._parseInteger(json['totalChats']) ?? 0,
      activeChats: Message._parseInteger(json['activeChats']) ?? 0,
      archivedChats: Message._parseInteger(json['archivedChats']) ?? 0,
      totalMessages: Message._parseInteger(json['totalMessages']) ?? 0,
      unreadMessages: Message._parseInteger(json['unreadMessages']) ?? 0,
      avgResponseTime: (json['avgResponseTime'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: Message._parseDateTime(json['lastUpdated']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalChats': totalChats,
      'activeChats': activeChats,
      'archivedChats': archivedChats,
      'totalMessages': totalMessages,
      'unreadMessages': unreadMessages,
      'avgResponseTime': avgResponseTime,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
