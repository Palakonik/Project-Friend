import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

/// E-posta Doğrulama Ekranı
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Her 3 saniyede bir doğrulama durumunu kontrol et
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final verified = await auth.checkEmailVerification();
    
    if (verified && mounted) {
      _timer?.cancel();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.resendVerificationEmail();
    
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });
    
    // 60 saniye bekleme süresi
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama e-postası tekrar gönderildi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.firebaseUser?.email ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // E-posta ikonu
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Başlık
                const Text(
                  'E-postanızı Doğrulayın',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Açıklama
                Text(
                  'Doğrulama linki şu adrese gönderildi:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bekleme göstergesi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Doğrulama bekleniyor...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Talimatlar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ne yapmalısınız:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction('1', 'E-posta kutunuzu kontrol edin'),
                      const SizedBox(height: 8),
                      _buildInstruction('2', 'Doğrulama linkine tıklayın'),
                      const SizedBox(height: 8),
                      _buildInstruction('3', 'Buraya otomatik yönlendirileceksiniz'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Tekrar gönder butonu
                TextButton.icon(
                  onPressed: _canResend ? _resendEmail : null,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    _canResend 
                        ? 'E-postayı Tekrar Gönder' 
                        : 'Tekrar gönder ($_resendCooldown sn)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Manuel doğrulama butonu
                OutlinedButton(
                  onPressed: _checkVerification,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Doğruladım, Kontrol Et',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Geri dön
                TextButton(
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(
                    'Farklı hesap kullan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
