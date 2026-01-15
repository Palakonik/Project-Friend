import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';

/// Ana Sayfa - Arkadaş listesi ve navigasyon
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Friendship> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      _friends = await auth.apiService.getMyFriends();
    } catch (e) {
      // Handle error
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaşlarım'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // APIs butonu
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: () {
              Navigator.pushNamed(context, '/apis');
            },
            tooltip: 'API Örnekleri',
          ),
          // Admin butonu
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () async {
                await Navigator.pushNamed(context, '/admin');
                _loadFriends(); // Admin panelinden dönünce listeyi yenile
              },
              tooltip: 'Admin Paneli',
            ),
          // Engellenmiş kullanıcılar
          IconButton(
            icon: const Icon(Icons.block),
            onPressed: () async {
              await Navigator.pushNamed(context, '/blocked');
              _loadFriends(); // Engel ekranından dönünce listeyi yenile
            },
            tooltip: 'Engellenmiş Kullanıcılar',
          ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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
      body: RefreshIndicator(
        onRefresh: _loadFriends,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _friends.isEmpty
                ? _buildEmptyState()
                : _buildFriendsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/search');
          _loadFriends(); // Geri dönünce listeyi yenile
        },
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.person_add),
        label: const Text('Arkadaş Ekle'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz arkadaşınız yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni arkadaşlar eklemek için + butonuna tıklayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friendship = _friends[index];
        final friend = friendship.friend;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: friend.profilePhoto != null
                  ? CachedNetworkImageProvider(friend.profilePhoto!)
                  : null,
              child: friend.profilePhoto == null
                  ? Text(
                      friend.fullName.isNotEmpty 
                          ? friend.fullName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            title: Text(
              friend.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Arkadaş oldu: ${_formatDate(friendship.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block') {
                  await _blockFriend(friend);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Engelle'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _blockFriend(User friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: Text('${friend.fullName} engellenecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.apiService.blockUser(friend.id);
      if (success) {
        _loadFriends();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${friend.fullName} engellendi')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
