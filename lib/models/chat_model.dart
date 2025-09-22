class Message {
  final int id;
  final String content;
  final String messageType;
  final int senderId;
  final String senderName;
  final int? bookingId;
  final int? rideId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.content,
    required this.messageType,
    required this.senderId,
    required this.senderName,
    this.bookingId,
    this.rideId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      messageType: json['messageType'] ?? 'text',
      senderId: json['senderId'],
      senderName: json['senderName'] ?? '',
      bookingId: json['bookingId'],
      rideId: json['rideId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'messageType': messageType,
      'senderId': senderId,
      'senderName': senderName,
      'bookingId': bookingId,
      'rideId': rideId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    String? content,
    String? messageType,
    int? senderId,
    String? senderName,
    int? bookingId,
    int? rideId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      bookingId: bookingId ?? this.bookingId,
      rideId: rideId ?? this.rideId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isTextMessage => messageType == 'text';
  bool get isImageMessage => messageType == 'image';
  bool get isLocationMessage => messageType == 'location';
  String get timeDisplay => '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}

// ✅ FIXED: ChatInfo class (replacing the old Conversation model)
class ChatInfo {
  final int? bookingId;
  final int? rideId;
  final String participantName;
  final String? participantImage;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatInfo({
    this.bookingId,
    this.rideId,
    required this.participantName,
    this.participantImage,
    this.lastMessageContent,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json) {
    return ChatInfo(
      bookingId: json['bookingId'],
      rideId: json['rideId'],
      participantName: json['participantName'] ?? '',
      participantImage: json['participantImage'],
      lastMessageContent: json['lastMessageContent'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'rideId': rideId,
      'participantName': participantName,
      'participantImage': participantImage,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  String get displayTitle => participantName.isNotEmpty ? participantName : 'محادثة';
  bool get hasUnread => unreadCount > 0;
  String get chatId => bookingId != null ? 'booking_$bookingId' : 'ride_$rideId';
}

// ✅ DEPRECATED: Keep for backward compatibility - just an alias to ChatInfo
class Conversation extends ChatInfo {
  Conversation({
    super.bookingId,
    super.rideId,
    required super.participantName,
    super.participantImage,
    super.lastMessageContent,
    super.lastMessageTime,
    super.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      bookingId: json['bookingId'],
      rideId: json['rideId'],
      participantName: json['participantName'] ?? '',
      participantImage: json['participantImage'],
      lastMessageContent: json['lastMessageContent'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
