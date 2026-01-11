import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service - PostgreSQL veritabanı ve real-time chat işlemleri
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Firebase user'ı Supabase'e senkronize et (ilk giriş veya güncelleme)
  /// ⚠️ Veritabanı şeması: id, email, username, avatar_url, bio, created_at
  Future<Map<String, dynamic>?> syncUserFromFirebase({
    required String firebaseUid,
    required String email,
    String? username,
    String?
    displayName, // Display name sadece username oluşturmak için kullanılır
    String? avatarUrl,
  }) async {
    try {
      // Null safety checks
      if (firebaseUid.isEmpty) {
        print('❌ Supabase sync hatası: Firebase UID boş!');
        throw Exception('Firebase UID boş olamaz');
      }

      if (email.isEmpty) {
        print('❌ Supabase sync hatası: Email boş!');
        throw Exception('Email boş olamaz');
      }

      // Username oluştur
      String finalUsername = username ?? email.split('@').first;

      // Eğer displayName varsa ve username null ise, displayName'den username yap
      if (username == null && displayName != null && displayName.isNotEmpty) {
        // Boşlukları kaldır, küçük harfe çevir, özel karakterleri temizle
        finalUsername = displayName
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^a-z0-9]'), '');

        // Eğer çok kısa olduysa email'den al
        if (finalUsername.length < 3) {
          finalUsername = email.split('@').first;
        }
      }

      print('🔄 Supabase sync başlatılıyor...');
      print('   - UID: $firebaseUid');
      print('   - Email: $email');
      print('   - Username: $finalUsername');

      // UPSERT - Sadece veritabanında VAR OLAN sütunları kullan
      final userData = {
        'id': firebaseUid,
        'email': email,
        'username': finalUsername,
        'avatar_url': avatarUrl,
        'bio': '', // Varsayılan boş bio
        // ⚠️ first_name ve last_name GÖNDERİLMİYOR (veritabanında yok!)
      };

      // UPSERT: Eğer id varsa günceller, yoksa ekler
      final response = await client
          .from('users')
          .upsert(userData, onConflict: 'id')
          .select()
          .single();

      print('✅ Supabase sync başarılı!');
      print('   - Kayıtlı ID: ${response['id']}');
      print('   - Username: ${response['username']}');

      return response;
    } on PostgrestException catch (e) {
      // Supabase-specific errors
      print('❌ Supabase PostgreSQL hatası:');
      print('   - Kod: ${e.code}');
      print('   - Mesaj: ${e.message}');
      print('   - Detay: ${e.details}');

      // User-friendly hata mesajı
      if (e.code == 'PGRST204') {
        throw Exception(
          'Veritabanı şeması güncellemesi gerekiyor. Lütfen tekrar deneyin.',
        );
      } else if (e.code == '23505') {
        throw Exception('Bu kullanıcı zaten kayıtlı');
      } else {
        throw Exception('Veritabanı hatası: ${e.message}');
      }
    } catch (e, stackTrace) {
      // Genel hatalar
      print('❌ Supabase sync genel hatası:');
      print('   - Hata: $e');
      print('   - Stack: $stackTrace');

      throw Exception('Senkronizasyon hatası: ${e.toString()}');
    }
  }

  /// Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Online durumunu güncelle
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await client
          .from('users')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Update online status error: $e');
    }
  }

  /// Arkadaşlık isteği gönder
  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // User ID'leri sırala (küçük olan önce)
      final userId1 = senderId.compareTo(receiverId) < 0
          ? senderId
          : receiverId;
      final userId2 = senderId.compareTo(receiverId) < 0
          ? receiverId
          : senderId;

      await client.from('friendships').insert({
        'user_id_1': userId1,
        'user_id_2': userId2,
        'status': 'pending',
        'requested_by': senderId,
      });

      return true;
    } catch (e) {
      print('Send friend request error: $e');
      return false;
    }
  }

  /// Arkadaşlık isteğini kabul et
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      await client
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', requestId);
      return true;
    } catch (e) {
      print('Accept friend request error: $e');
      return false;
    }
  }

  /// Arkadaşlık listesini getir
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      final response = await client
          .from('friendships')
          .select('*, user_id_1(*), user_id_2(*)')
          .eq('status', 'accepted')
          .or('user_id_1.eq.$userId,user_id_2.eq.$userId');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get friends error: $e');
      return [];
    }
  }

  /// Mesaj gönder
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      await client.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
      });
      return true;
    } catch (e) {
      print('Send message error: $e');
      return false;
    }
  }

  /// İki kullanıcı arasındaki mesajları dinle (REAL-TIME!)
  Stream<List<Map<String, dynamic>>> watchMessages(
    String currentUserId,
    String otherUserId,
  ) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) {
          // Sadece bu iki kullanıcı arasındaki mesajları filtrele
          return data.where((message) {
            final senderId = message['sender_id'];
            final receiverId = message['receiver_id'];
            return (senderId == currentUserId && receiverId == otherUserId) ||
                (senderId == otherUserId && receiverId == currentUserId);
          }).toList();
        });
  }

  /// Okunmamış mesaj sayısını getir
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await client
          .from('messages')
          .select()
          .eq('receiver_id', userId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      print('Get unread count error: $e');
      return 0;
    }
  }

  /// Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      await client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('sender_id', senderId)
          .eq('receiver_id', receiverId)
          .eq('is_read', false);
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  /// Son konuşmaları getir (her arkadaş için son mesaj)
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      // Tüm mesajları al (gönderilen ve alınan)
      final allMessages = await client
          .from('messages')
          .select('*, sender:sender_id(*), receiver:receiver_id(*)')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      // Her kullanıcı için son mesajı grupla
      final Map<String, Map<String, dynamic>> conversationsMap = {};

      for (var message in allMessages) {
        final senderId = message['sender_id'];
        final receiverId = message['receiver_id'];
        final otherUserId = senderId == userId ? receiverId : senderId;

        // Eğer bu kullanıcıyla bir konuşma yoksa, ekle
        if (!conversationsMap.containsKey(otherUserId)) {
          conversationsMap[otherUserId] = message;
        }
      }

      return conversationsMap.values.toList();
    } catch (e) {
      print('Get conversations error: $e');
      return [];
    }
  }

  /// Kullanıcıyı engelle
  Future<bool> blockUser(String blockerId, String blockedId) async {
    try {
      await client.from('blocked_users').insert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      });
      return true;
    } catch (e) {
      print('Block user error: $e');
      return false;
    }
  }

  /// İki kullanıcının arkadaş olup olmadığını kontrol et
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final user1 = userId1.compareTo(userId2) < 0 ? userId1 : userId2;
      final user2 = userId1.compareTo(userId2) < 0 ? userId2 : userId1;

      final result = await client
          .from('friendships')
          .select()
          .eq('user_id_1', user1)
          .eq('user_id_2', user2)
          .eq('status', 'accepted')
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('Are friends check error: $e');
      return false;
    }
  }
}
