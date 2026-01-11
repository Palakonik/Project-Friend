import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/auth_provider.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

/// Konuşmalar listesi ekranı
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Türkçe timeago ayarı
    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = auth.firebaseUser?.uid;

    if (_currentUserId != null) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final conversations = await _supabaseService.getConversations(
        _currentUserId!,
      );
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Konuşmalar yüklenemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: _buildConversationsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz sohbet yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Arkadaşlarınızla mesajlaşmaya başlayın!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final senderId = conversation['sender_id'];
    final receiverId = conversation['receiver_id'];
    final content = conversation['content'] ?? '';
    final createdAt = DateTime.parse(conversation['created_at']);
    final isRead = conversation['is_read'] ?? false;

    // Karşı tarafın bilgilerini al
    final otherUserId = senderId == _currentUserId ? receiverId : senderId;
    final otherUserData = senderId == _currentUserId
        ? conversation['receiver']
        : conversation['sender'];

    final otherUsername = otherUserData?['username'] ?? 'Kullanıcı';
    final otherAvatar = otherUserData?['avatar_url'];

    // Ben mi gönderdim?
    final isMine = senderId == _currentUserId;

    // Önizleme metni
    final previewText = isMine ? 'Sen: $content' : content;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              friendId: otherUserId,
              friendName: otherUsername,
              friendAvatar: otherAvatar,
            ),
          ),
        ).then((_) => _loadConversations()); // Geri dönünce yenile
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: !isRead && !isMine ? Colors.blue[50] : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: otherAvatar != null
                  ? CachedNetworkImageProvider(otherAvatar)
                  : null,
              child: otherAvatar == null
                  ? Text(
                      otherUsername.isNotEmpty
                          ? otherUsername[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Mesaj bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUsername,
                        style: TextStyle(
                          fontWeight: !isRead && !isMine
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeago.format(createdAt, locale: 'tr'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: !isRead && !isMine
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: !isRead && !isMine
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (!isRead && !isMine) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF667eea),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
