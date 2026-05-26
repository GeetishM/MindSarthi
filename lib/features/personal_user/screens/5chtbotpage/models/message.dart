class Message {
  String messageId;
  String chatId;
  Role role;
  StringBuffer message;
  List<String> imagesUrls;
  DateTime timeSent;
  bool isSynced;
  String? userId;

  // constructor
  Message({
    required this.messageId,
    required this.chatId,
    required this.role,
    required this.message,
    required this.imagesUrls,
    required this.timeSent,
    this.isSynced = false,
    this.userId,
  });

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'role': role.index,
      'message': message.toString(),
      'imagesUrls': imagesUrls,
      'timeSent': timeSent.toIso8601String(),
      'isSynced': isSynced,
      'userId': userId,
    };
  }

  // from map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      role: Role.values[map['role'] ?? 0],
      message: StringBuffer(map['message'] ?? ''),
      imagesUrls: List<String>.from(map['imagesUrls'] ?? []),
      timeSent: DateTime.tryParse(map['timeSent'] ?? '') ?? DateTime.now(),
      isSynced: map['isSynced'] ?? false,
      userId: map['userId'],
    );
  }

  // copyWith
  Message copyWith({
    String? messageId,
    String? chatId,
    Role? role,
    StringBuffer? message,
    List<String>? imagesUrls,
    DateTime? timeSent,
    bool? isSynced,
    String? userId,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      message: message ?? this.message,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      timeSent: timeSent ?? this.timeSent,
      isSynced: isSynced ?? this.isSynced,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message && other.messageId == messageId;
  }

  @override
  int get hashCode {
    return messageId.hashCode;
  }
}

enum Role {
  user,
  assistant,
}
