import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Auth Provider - Kullanıcı oturum yönetimi
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdminUser ?? false;
  String? get error => _error;
  ApiService get apiService => _apiService;

  /// Mevcut oturumu kontrol et
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _apiService.getCurrentUser();
    } catch (e) {
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Google ile giriş yap
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        _error = 'Giriş iptal edildi';
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        _isLoading = false;
        _error = 'Token alınamadı';
        notifyListeners();
        return false;
      }

      _currentUser = await _apiService.googleLogin(googleAuth.idToken!);
      
      if (_currentUser == null) {
        _error = 'Sunucu hatası';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Giriş hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignIn.signOut();
      await _apiService.logout();
    } catch (e) {
      // Ignore
    }

    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
