import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_provider.dart';

/// Ayarlar ekranı - Profil ve uygulama ayarları
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // GitHub repository URL (kullanıcı doldurabilir)
  static const String GITHUB_REPO_URL =
      'https://github.com/USERNAME/REPO_NAME'; // TODO: Doldurulacak
  static const String GITHUB_RELEASES_URL = '$GITHUB_REPO_URL/releases/latest';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Profil Bölümü
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user?.profilePhoto != null
                      ? NetworkImage(user!.profilePhoto!)
                      : null,
                  child: user?.profilePhoto == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Güncelleme Bölümü
          _buildSection(
            title: 'Uygulama',
            children: [
              _buildListTile(
                icon: Icons.update,
                title: 'Güncellemeleri Kontrol Et',
                subtitle: 'En son sürümü indirin',
                onTap: () => _checkForUpdates(context),
                trailing: const Icon(Icons.open_in_new, size: 20),
              ),
              _buildListTile(
                icon: Icons.info_outline,
                title: 'Sürüm',
                subtitle: 'v1.0.0', // pubspec.yaml'dan alınabilir
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hesap Bölümü
          _buildSection(
            title: 'Hesap',
            children: [
              _buildListTile(
                icon: Icons.person_outline,
                title: 'Profili Düzenle',
                subtitle: 'Bilgilerinizi güncelleyin',
                onTap: () {
                  // TODO: Profil düzenleme ekranı
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.lock_outline,
                title: 'Şifreyi Değiştir',
                subtitle: 'Güvenliğinizi koruyun',
                onTap: () {
                  // TODO: Şifre değiştirme
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Diğer
          _buildSection(
            title: 'Diğer',
            children: [
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Yardım & Destek',
                subtitle: 'S.S.S ve destek',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yakında eklenecek!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Çıkış Yap Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _logout(context, auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF667eea)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    // GitHub Releases sayfasını aç
    final Uri url = Uri.parse(GITHUB_RELEASES_URL);

    try {
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Güncelleme sayfası açılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _logout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
