import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// API Servisi - Django backend ile iletişim
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator için
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS/Web için
  
  String? _sessionId;

  /// Session ID'yi SharedPreferences'tan al
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sessionid');
  }

  /// Session ID'yi kaydet
  Future<void> saveSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionid', sessionId);
    _sessionId = sessionId;
  }

  /// HTTP headers
  Map<String, String> get headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_sessionId != null) {
      h['Cookie'] = 'sessionid=$_sessionId';
    }
    return h;
  }

  /// Google login
  Future<User?> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/google-login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Session cookie'yi kaydet
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        final sessionMatch = RegExp(r'sessionid=([^;]+)').firstMatch(cookies);
        if (sessionMatch != null) {
          await saveSession(sessionMatch.group(1)!);
        }
      }
      return User.fromJson(data['user']);
    }
    return null;
  }

  /// Mevcut kullanıcı bilgisi
  Future<User?> getCurrentUser() async {
    await loadSession();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  /// Kullanıcı ara
  Future<List<User>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search/?q=$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    return [];
  }

  /// Arkadaşlık isteği gönder
  Future<bool> sendFriendRequest(int receiverId, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/send-request/'),
      headers: headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'note': note,
      }),
    );

    return response.statusCode == 201;
  }

  /// Arkadaş listesi
  Future<List<Friendship>> getMyFriends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/my-friends/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Friendship.fromJson(json)).toList();
    }
    return [];
  }

  /// Bekleyen istekler (Admin)
  Future<List<FriendRequest>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/admin/pending/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => FriendRequest.fromJson(json)).toList();
    }
    return [];
  }

  /// İsteği onayla (Admin)
  Future<bool> approveRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/admin/approve/$requestId/'),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  /// İsteği reddet (Admin)
  Future<bool> rejectRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/admin/reject/$requestId/'),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  /// Kullanıcı engelle
  Future<bool> blockUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/block/'),
      headers: headers,
      body: jsonEncode({'user_id': userId}),
    );
    return response.statusCode == 201;
  }

  /// Engeli kaldır
  Future<bool> unblockUser(int blockId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/unblock/$blockId/'),
      headers: headers,
    );
    return response.statusCode == 200;
  }

  /// Engellenmiş kullanıcılar
  Future<List<BlockedUser>> getBlockedUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/blocked/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => BlockedUser.fromJson(json)).toList();
    }
    return [];
  }

  /// Çıkış yap
  Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/users/logout/'),
      headers: headers,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionid');
    _sessionId = null;
  }
}
