import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_provider.dart';

/// Kayıt Ekranı - E-posta ile kayıt
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _profilePhoto;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profilePhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Profil fotoğrafı zorunlu
    if (_profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir profil fotoğrafı seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.registerWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      profilePhoto: _profilePhoto,
    );
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/verify-email');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Geri butonu
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Başlık
                  const Text(
                    'Hesap Oluştur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni arkadaşlar edinmeye başla',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Profil Fotoğrafı
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: _profilePhoto != null
                              ? DecorationImage(
                                  image: FileImage(_profilePhoto!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profilePhoto == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fotoğraf Ekle',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Form Alanları
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'Ad',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Soyad',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Soyad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _emailController,
                    label: 'E-posta',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta gerekli';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Şifre',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Şifre Tekrarı',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Hata Mesajı
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // Kayıt Butonu
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Giriş Yap Linki
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Zaten hesabınız var mı? Giriş yapın',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
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
        errorStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      validator: validator,
    );
  }
}
