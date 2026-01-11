import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';

/// Admin Panel - Bekleyen arkadaşlık isteklerini onaylama/reddetme ve kullanıcı yönetimi
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FriendRequest> _pendingRequests = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingRequests = true;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingRequests();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      _pendingRequests = await auth.apiService.getPendingRequests();
    } catch (e) {
      // Handle error
    }
    
    setState(() => _isLoadingRequests = false);
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      _allUsers = await auth.apiService.getAllUsers();
    } catch (e) {
      // Handle error
    }
    
    setState(() => _isLoadingUsers = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: const Color(0xFF764ba2),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'İstekler'),
            Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // İstekler sekmesi
          RefreshIndicator(
            onRefresh: _loadPendingRequests,
            child: _isLoadingRequests
                ? const Center(child: CircularProgressIndicator())
                : _pendingRequests.isEmpty
                    ? _buildEmptyRequestsState()
                    : _buildRequestsList(),
          ),
          // Kullanıcılar sekmesi
          RefreshIndicator(
            onRefresh: _loadAllUsers,
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _allUsers.isEmpty
                    ? _buildEmptyUsersState()
                    : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bekleyen istek yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tüm arkadaşlık istekleri işlendi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gönderen ve Alıcı
                Row(
                  children: [
                    // Gönderen
                    _buildUserAvatar(request.sender),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.sender.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Gönderen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    const SizedBox(width: 8),
                    // Alıcı
                    _buildUserAvatar(request.receiver),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.receiver.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Alıcı',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Not
                if (request.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.note,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Tarih
                const SizedBox(height: 12),
                Text(
                  'Talep tarihi: ${_formatDate(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                
                // Aksiyon butonları
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRequest(request),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reddet'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(request),
                        icon: const Icon(Icons.check),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(User user) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: user.profilePhoto != null
          ? CachedNetworkImageProvider(user.profilePhoto!)
          : null,
      child: user.profilePhoto == null
          ? Text(
              user.fullName.isNotEmpty 
                  ? user.fullName[0].toUpperCase() 
                  : '?',
              style: const TextStyle(fontSize: 16),
            )
          : null,
    );
  }

  Future<void> _approveRequest(FriendRequest request) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.apiService.approveRequest(request.id);
    
    if (success) {
      _loadPendingRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.sender.fullName} ve ${request.receiver.fullName} artık arkadaş!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İsteği Reddet'),
        content: Text('${request.sender.fullName} tarafından gönderilen isteği reddetmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.apiService.rejectRequest(request.id);
      
      if (success) {
        _loadPendingRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İstek reddedildi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyUsersState() {
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
            'Kullanıcı bulunamadı',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        final isAdmin = user['is_admin_user'] == true;
        final isCurrentUser = user['id'] == currentUserId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: isAdmin ? const Color(0xFF764ba2) : Colors.grey[300],
              backgroundImage: user['profile_photo'] != null
                  ? CachedNetworkImageProvider(user['profile_photo'])
                  : null,
              child: user['profile_photo'] == null
                  ? Text(
                      (user['full_name'] ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        color: isAdmin ? Colors.white : Colors.grey[700],
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user['full_name'] ?? 'Bilinmeyen',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF764ba2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? ''),
                if (isCurrentUser)
                  const Text(
                    '(Siz)',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            trailing: isCurrentUser
                ? null
                : Switch(
                    value: isAdmin,
                    activeColor: const Color(0xFF764ba2),
                    onChanged: (value) => _toggleAdmin(user),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _toggleAdmin(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['is_admin_user'] == true ? 'Admin Yetkisini Kaldır' : 'Admin Yetkisi Ver'),
        content: Text(
          user['is_admin_user'] == true
              ? '${user['full_name']} kullanıcısının admin yetkisini kaldırmak istiyor musunuz?'
              : '${user['full_name']} kullanıcısına admin yetkisi vermek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user['is_admin_user'] == true ? Colors.red : const Color(0xFF764ba2),
            ),
            child: Text(user['is_admin_user'] == true ? 'Kaldır' : 'Ver'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.apiService.toggleAdminStatus(user['id']);
      
      if (result['error'] == null) {
        _loadAllUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'İşlem başarılı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

