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
      profilePhoto: json['profile_photo'],
      isAdminUser: json['is_admin_user'] ?? false,
    );
  }
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

  Friendship({
    required this.id,
    required this.friend,
    required this.createdAt,
  });

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
