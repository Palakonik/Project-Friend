import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart' as app_models;
import 'api_service.dart';

/// Auth Provider - Firebase ile kullanıcı oturum yönetimi
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  app_models.User? _currentUser;
  User? _firebaseUser;
  bool _isLoading = false;
  String? _error;

  app_models.User? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdminUser ?? false;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;
  String? get error => _error;
  ApiService get apiService => _apiService;

  /// Mevcut oturumu kontrol et
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _firebaseUser = _firebaseAuth.currentUser;
      
      if (_firebaseUser != null) {
        // Firebase'den token al ve backend'e gönder
        final idToken = await _firebaseUser!.getIdToken();
        if (idToken != null) {
          _currentUser = await _apiService.firebaseLogin(idToken);
        }
      }
    } catch (e) {
      _currentUser = null;
      _firebaseUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Google ile giriş yap (Firebase üzerinden)
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
      
      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile giriş yap
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      _firebaseUser = userCredential.user;

      if (_firebaseUser == null) {
        _error = 'Firebase girişi başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Firebase token'ı backend'e gönder
      final idToken = await _firebaseUser!.getIdToken();
      if (idToken != null) {
        _currentUser = await _apiService.firebaseLogin(idToken);
      }
      
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

  /// E-posta ile kayıt ol
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    File? profilePhoto,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Firebase'de kullanıcı oluştur
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _firebaseUser = userCredential.user;
      
      if (_firebaseUser == null) {
        _error = 'Kayıt başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Firebase'de isim güncelle
      await _firebaseUser!.updateDisplayName('$firstName $lastName');
      
      // E-posta doğrulama gönder
      await _firebaseUser!.sendEmailVerification();

      // Backend'e kayıt bilgilerini gönder
      final idToken = await _firebaseUser!.getIdToken();
      if (idToken != null) {
        _currentUser = await _apiService.registerWithFirebase(
          firebaseToken: idToken,
          firstName: firstName,
          lastName: lastName,
          profilePhoto: profilePhoto,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Kayıt hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// E-posta ile giriş yap
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _firebaseUser = userCredential.user;
      
      if (_firebaseUser == null) {
        _error = 'Giriş başarısız';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // E-posta doğrulanmış mı kontrol et
      if (!_firebaseUser!.emailVerified) {
        _isLoading = false;
        notifyListeners();
        // Doğrulama ekranına yönlendirmek için true dön
        return true;
      }

      // Backend'e token gönder
      final idToken = await _firebaseUser!.getIdToken();
      if (idToken != null) {
        _currentUser = await _apiService.firebaseLogin(idToken);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Giriş hatası: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// E-posta doğrulama durumunu kontrol et
  Future<bool> checkEmailVerification() async {
    if (_firebaseUser == null) return false;
    
    await _firebaseUser!.reload();
    _firebaseUser = _firebaseAuth.currentUser;
    
    if (_firebaseUser?.emailVerified == true) {
      // Backend'e giriş yap
      final idToken = await _firebaseUser!.getIdToken();
      if (idToken != null) {
        _currentUser = await _apiService.firebaseLogin(idToken);
      }
      notifyListeners();
      return true;
    }
    
    return false;
  }

  /// Doğrulama e-postasını yeniden gönder
  Future<void> resendVerificationEmail() async {
    if (_firebaseUser != null && !_firebaseUser!.emailVerified) {
      await _firebaseUser!.sendEmailVerification();
    }
  }

  /// Çıkış yap
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await _apiService.logout();
    } catch (e) {
      // Ignore
    }

    _currentUser = null;
    _firebaseUser = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Firebase hata mesajlarını Türkçeye çevir
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Yanlış şifre';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
