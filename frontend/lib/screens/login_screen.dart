import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

/// Login Ekranı - Google ve E-posta ile giriş
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailLogin = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (success && mounted) {
      // E-posta doğrulanmış mı kontrol et
      if (auth.isEmailVerified) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/verify-email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / İkon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Başlık
                  const Text(
                    'Arkadaşlık',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni arkadaşlar edin',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Google Giriş veya E-posta Giriş
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) {
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      }

                      return Column(
                        children: [
                          // Google ile Giriş Butonu
                          if (!_showEmailLogin) ...[
                            ElevatedButton(
                              onPressed: () async {
                                final success = await auth.signInWithGoogle();
                                if (success && context.mounted) {
                                  Navigator.pushReplacementNamed(context, '/home');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(
                                    'https://www.google.com/favicon.ico',
                                    height: 24,
                                    errorBuilder: (_, __, ___) => 
                                        const Icon(Icons.g_mobiledata, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Google ile Giriş Yap',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Ayırıcı
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'veya',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // E-posta ile giriş butonu
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _showEmailLogin = true),
                              icon: const Icon(Icons.email, color: Colors.white),
                              label: const Text(
                                'E-posta ile Giriş',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                          
                          // E-posta Giriş Formu
                          if (_showEmailLogin) ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Geri butonu
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => setState(() => _showEmailLogin = false),
                                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                      label: const Text('Geri', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // E-posta alanı
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'E-posta',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'E-posta gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Şifre alanı
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Şifre',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Şifre gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Giriş butonu
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _signInWithEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF667eea),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Giriş Yap',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Hata mesajı
                          if (auth.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                auth.error!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Kayıt ol linki
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: Text(
                              'Hesabınız yok mu? Kayıt olun',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
