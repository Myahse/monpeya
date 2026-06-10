class RentalConversation {
  const RentalConversation({
    required this.userId,
    required this.userName,
    this.userPhoto,
    this.lastMessage = '',
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  final String userId;
  final String userName;
  final String? userPhoto;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  factory RentalConversation.fromBackend(Map<String, dynamic> json) {
    return RentalConversation(
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] as String?) ?? 'Utilisateur',
      userPhoto: json['userPhoto'] as String?,
      lastMessage: (json['lastMessage'] as String?) ?? '',
      lastMessageTime: DateTime.tryParse('${json['lastMessageTime']}'),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class RentalMessage {
  const RentalMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime? sentAt;
  final bool isRead;

  factory RentalMessage.fromBackend(Map<String, dynamic> json) {
    return RentalMessage(
      id: (json['messagesId'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      content: (json['content'] as String?) ?? '',
      sentAt: DateTime.tryParse('${json['sentAt']}'),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSendPayload({
    required String senderId,
    required String receiverId,
  }) {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': 'TEXT',
    };
  }
}
