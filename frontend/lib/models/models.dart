/// Kullanıcı modeli
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePhoto;
  final bool isAdminUser;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
    this.isAdminUser = false,
  });

  String get fullName => '$firstName $lastName'.trim().isNotEmpty
      ? '$firstName $lastName'.trim()
      : username;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePhoto: json['profile_photo_url'] ?? json['profile_photo'],
      isAdminUser: json['is_admin_user'] ?? false,
    );
  }
}

/// Mesaj modeli
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}

/// Konuşma modeli (son mesaj ile birlikte)
class Conversation {
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatarUrl;
  final Message lastMessage;
  final int unreadCount;

  Conversation({
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatarUrl,
    required this.lastMessage,
    this.unreadCount = 0,
  });
}

/// Arkadaşlık isteği modeli
class FriendRequest {
  final int id;
  final User sender;
  final User receiver;
  final String note;
  final String status;
  final String statusDisplay;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.note,
    required this.status,
    required this.statusDisplay,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      receiver: User.fromJson(json['receiver']),
      note: json['note'] ?? '',
      status: json['status'] ?? 'pending',
      statusDisplay: json['status_display'] ?? 'Beklemede',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Arkadaşlık modeli
class Friendship {
  final int id;
  final User friend;
  final DateTime createdAt;

  Friendship({required this.id, required this.friend, required this.createdAt});

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      friend: User.fromJson(json['friend']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Engellenmiş kullanıcı modeli
class BlockedUser {
  final int id;
  final User blocked;
  final DateTime createdAt;

  BlockedUser({
    required this.id,
    required this.blocked,
    required this.createdAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'],
      blocked: User.fromJson(json['blocked']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
