import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_provider.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

/// Ana Sayfa - Kullanıcı listesi (sohbet için)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.firebaseUser?.uid;

    if (currentUserId == null) {
      setState(() {
        _error = 'Giriş yapmalısınız';
        _isLoading = false;
      });
      return;
    }

    try {
      // Tüm kullanıcıları getir
      final response = await _supabaseService.client
          .from('users')
          .select()
          .neq('id', currentUserId) // Kendisi hariç
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('✅ ${_users.length} kullanıcı yüklendi');
    } catch (e) {
      setState(() {
        _error = 'Kullanıcılar yüklenemedi: $e';
        _isLoading = false;
      });
      print('❌ Kullanıcı yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Profil menüsü
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: user?.profilePhoto != null
                  ? CachedNetworkImageProvider(user!.profilePhoto!)
                  : null,
              child: user?.profilePhoto == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            onSelected: (value) {
              if (value == 'logout') {
                auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Kullanıcı',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Çıkış Yap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz kullanıcı yok',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk kullanıcı sensin!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final otherUser = _users[index];
          return _buildUserTile(otherUser);
        },
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> otherUser) {
    final username = otherUser['username'] ?? 'Kullanıcı';
    final email = otherUser['email'] ?? '';
    final avatarUrl = otherUser['avatar_url'];
    final bio = otherUser['bio'] ?? '';

    return InkWell(
      onTap: () {
        // Chat ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              friendId: otherUser['id'],
              friendName: username,
              friendAvatar: avatarUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Kullanıcı bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            // Mesaj ikonu
            Icon(Icons.chat_bubble_outline, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
