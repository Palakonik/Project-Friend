import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';

/// Arama Ekranı - Kullanıcı arama ve arkadaşlık isteği gönderme
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _message;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _message = 'En az 2 karakter girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      _searchResults = await auth.apiService.searchUsers(query);
      if (_searchResults.isEmpty) {
        _message = 'Kullanıcı bulunamadı';
      }
    } catch (e) {
      _message = 'Arama hatası';
      _searchResults = [];
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaş Ara'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ad veya soyad ile ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _message = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: _search,
            ),
          ),

          // Sonuçlar
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _message != null && _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        
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
              backgroundImage: user.profilePhoto != null
                  ? CachedNetworkImageProvider(user.profilePhoto!)
                  : null,
              child: user.profilePhoto == null
                  ? Text(
                      user.fullName.isNotEmpty 
                          ? user.fullName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _showSendRequestDialog(user),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Talep Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSendRequestDialog(User user) {
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.fullName} ile arkadaş ol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Arkadaşlık isteğiniz admin onayından sonra geçerli olacaktır.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                hintText: 'Kendinizi tanıtın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendRequest(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(User user) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final result = await auth.apiService.sendFriendRequest(
        user.id,
        _noteController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'İşlem tamamlandı'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
