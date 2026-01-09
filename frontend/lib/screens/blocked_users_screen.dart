import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';

/// Engellenmiş Kullanıcılar Ekranı
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      _blockedUsers = await auth.apiService.getBlockedUsers();
    } catch (e) {
      // Handle error
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engellenmiş Kullanıcılar'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBlockedUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _blockedUsers.isEmpty
                ? _buildEmptyState()
                : _buildBlockedList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Engellenmiş kullanıcı yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final blocked = _blockedUsers[index];
        final user = blocked.blocked;
        
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
              backgroundColor: Colors.red[100],
              backgroundImage: user.profilePhoto != null
                  ? CachedNetworkImageProvider(user.profilePhoto!)
                  : null,
              child: user.profilePhoto == null
                  ? Icon(Icons.block, color: Colors.red[700])
                  : null,
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Engellenme tarihi: ${_formatDate(blocked.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: TextButton.icon(
              onPressed: () => _unblockUser(blocked),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Engeli Kaldır'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unblockUser(BlockedUser blocked) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Engeli Kaldır'),
        content: Text('${blocked.blocked.fullName} için engeli kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Engeli Kaldır'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.apiService.unblockUser(blocked.id);
      
      if (success) {
        _loadBlockedUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${blocked.blocked.fullName} için engel kaldırıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
