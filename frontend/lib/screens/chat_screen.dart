import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/message_bubble.dart';

/// Chat ekranı - İki kullanıcı arasında mesajlaşma
class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatar;

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseService _supabaseService = SupabaseService();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = auth.firebaseUser?.uid;

    // Mesajları okundu olarak işaretle
    if (_currentUserId != null) {
      _markMessagesAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await _supabaseService.markMessagesAsRead(widget.friendId, _currentUserId!);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sohbet')),
        body: const Center(child: Text('Giriş yapmalısınız')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Mesajlar listesi (REAL-TIME!)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.watchMessages(
                _currentUserId!,
                widget.friendId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajı gönderin!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto scroll to bottom when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final messageModel = Message.fromJson(messageData);
                    final isMine = messageModel.senderId == _currentUserId;

                    return MessageBubble(
                      message: messageModel.content,
                      isMine: isMine,
                      timestamp: messageModel.createdAt,
                      isRead: messageModel.isRead,
                    );
                  },
                );
              },
            ),
          ),

          // Mesaj giriş alanı
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF667eea),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: widget.friendAvatar != null
                ? NetworkImage(widget.friendAvatar!)
                : null,
            child: widget.friendAvatar == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.friendName, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Mesaj yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    // Mesajı gönder
    final success = await _supabaseService.sendMessage(
      senderId: _currentUserId!,
      receiverId: widget.friendId,
      content: content,
    );

    if (success) {
      _messageController.clear();
      // ScrollController otomatik olarak en alta inecek (StreamBuilder tetiklenince)
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj gönderilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
