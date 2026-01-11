import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart' as app_models;
import 'api_service.dart';
import 'supabase_service.dart';

/// Auth Provider - Firebase ile kullanıcı oturum yönetimi
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId kaldırıldı - google-services.json'dan otomatik okunacak
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

  /// Google ile giriş yap (Firebase + Supabase sync)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Google hesap seçimi
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        _error = 'Giriş iptal edildi';
        notifyListeners();
        return false;
      }

      // 2. Google authentication
      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        _isLoading = false;
        _error = 'Google kimlik doğrulama hatası: ${e.toString()}';
        notifyListeners();
        return false;
      }

      // 3. Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase ile giriş yap
      final UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      } catch (e) {
        _isLoading = false;
        _error = 'Firebase giriş hatası: ${e.toString()}';
        notifyListeners();
        return false;
      }

      _firebaseUser = userCredential.user;

      // 5. Firebase user kontrolü
      if (_firebaseUser == null) {
        _isLoading = false;
        _error = 'Kullanıcı bilgileri alınamadı';
        notifyListeners();
        return false;
      }

      // 6. Email kontrolü (null safety)
      if (_firebaseUser!.email == null || _firebaseUser!.email!.isEmpty) {
        _isLoading = false;
        _error = 'Email bilgisi alınamadı. Lütfen farklı bir hesap deneyin.';
        notifyListeners();
        return false;
      }

      // 7. SUPABASE SYNC - KRİTİK!
      bool supabaseSyncSuccess = false;
      String? supabaseError;

      try {
        final supabaseService = SupabaseService();

        print('🔄 Supabase sync başlatılıyor: ${_firebaseUser!.uid}');

        final result = await supabaseService.syncUserFromFirebase(
          firebaseUid: _firebaseUser!.uid,
          email: _firebaseUser!.email!,
          username: _firebaseUser!.email!.split('@').first,
          displayName:
              _firebaseUser!.displayName, // Sadece username oluşturmak için
          avatarUrl: _firebaseUser!.photoURL,
        );

        if (result != null) {
          print('✅ Supabase sync başarılı!');
          supabaseSyncSuccess = true;
        } else {
          print('❌ Supabase sync sonuç null!');
          supabaseError = 'Veritabanı senkronizasyonu başarısız';
        }
      } catch (e) {
        print('❌ Supabase sync hatası: $e');
        supabaseError = e.toString();
      }

      // 8. Supabase sync başarısız olduysa KULLANICIYI BİLGİLENDİR
      if (!supabaseSyncSuccess) {
        _isLoading = false;
        _error =
            supabaseError ??
            'Veritabanı bağlantı hatası. Lütfen tekrar deneyin.';

        // Firebase'den çıkış yap (temizlik)
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        _firebaseUser = null;

        notifyListeners();
        return false;
      }

      // 9. Local user model oluştur
      _currentUser = app_models.User(
        id: 0,
        username: _firebaseUser!.email!.split('@').first,
        email: _firebaseUser!.email!,
        firstName: _firebaseUser!.displayName?.split(' ').first ?? 'Kullanıcı',
        lastName:
            _firebaseUser!.displayName?.split(' ').skip(1).join(' ') ?? '',
        profilePhoto: _firebaseUser!.photoURL,
        isAdminUser: false,
      );

      print('✅ Giriş tamamlandı: ${_currentUser!.email}');

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Firebase specific errors
      _isLoading = false;
      _error = _getFirebaseErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      // Genel hatalar
      _isLoading = false;
      _error = 'Beklenmeyen hata: ${e.toString()}';
      print('❌ Sign in genel hatası: $e');
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
      print('📝 Kayıt işlemi başlatılıyor...');
      print('   - Email: $email');
      print('   - İsim: $firstName $lastName');

      // 1. Firebase'de kullanıcı oluştur
      final UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Firebase kayıt başarılı');
      } on FirebaseAuthException catch (e) {
        print('❌ Firebase kayıt hatası: ${e.code}');
        _isLoading = false;
        _error = _getFirebaseErrorMessage(e.code);
        notifyListeners();
        return false;
      }

      _firebaseUser = userCredential.user;

      // 2. Firebase user kontrolü
      if (_firebaseUser == null) {
        _error = 'Firebase kullanıcı oluşturulamadı';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Firebase'de display name güncelle
      try {
        await _firebaseUser!.updateDisplayName('$firstName $lastName');
        print('✅ Display name güncellendi');
      } catch (e) {
        print('⚠️ Display name güncellenemedi: $e');
        // Devam et, kritik değil
      }

      // 4. E-posta doğrulama gönder
      try {
        await _firebaseUser!.sendEmailVerification();
        print('✅ Doğrulama emaili gönderildi');
      } catch (e) {
        print('⚠️ Doğrulama emaili gönderilemedi: $e');
        // Devam et, kritik değil
      }

      // 5. SUPABASE SYNC - KRİTİK!
      bool supabaseSyncSuccess = false;
      String? supabaseError;

      try {
        final supabaseService = SupabaseService();

        print('🔄 Supabase sync başlatılıyor (kayıt)...');

        // Display name oluştur (ad + soyad)
        final displayName = '$firstName $lastName'.trim();

        final result = await supabaseService.syncUserFromFirebase(
          firebaseUid: _firebaseUser!.uid,
          email: email,
          username: email.split('@').first,
          displayName: displayName.isNotEmpty
              ? displayName
              : null, // Username oluşturmak için
          avatarUrl: null, // Fotoğraf daha sonra eklenebilir
        );

        if (result != null) {
          print('✅ Supabase kayıt başarılı!');
          supabaseSyncSuccess = true;
        } else {
          print('❌ Supabase sync sonuç null!');
          supabaseError = 'Veritabanı kaydı oluşturulamadı';
        }
      } catch (e) {
        print('❌ Supabase sync exception: $e');
        supabaseError = e.toString();
      }

      // 6. Supabase sync başarısız olduysa GERİ AL
      if (!supabaseSyncSuccess) {
        _isLoading = false;
        _error =
            'Veritabanı senkronizasyonu başarısız: ${supabaseError ?? "Bilinmeyen hata"}';

        print('🔙 Firebase kullanıcısı siliniyor (rollback)...');

        // Firebase kullanıcısını sil (cleanup)
        try {
          await _firebaseUser!.delete();
          print('✅ Rollback tamamlandı');
        } catch (deleteError) {
          print('⚠️ Firebase kullanıcı silinemedi: $deleteError');
        }

        _firebaseUser = null;
        notifyListeners();
        return false;
      }

      // 7. Local user model oluştur
      _currentUser = app_models.User(
        id: 0,
        username: email.split('@').first,
        email: email,
        firstName: firstName,
        lastName: lastName,
        profilePhoto: null,
        isAdminUser: false,
      );

      print('✅ Kayıt işlemi tamamlandı!');
      print('   - Firebase UID: ${_firebaseUser!.uid}');
      print('   - Email: $email');

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Firebase specific errors
      print('❌ Firebase Auth Exception: ${e.code}');
      _isLoading = false;
      _error = _getFirebaseErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      // Genel hatalar
      print('❌ Kayıt genel hatası: $e');
      print('Stack trace: $stackTrace');
      _error = 'Kayıt hatası: ${e.toString()}';
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

  /// Firebase hata kodlarını kullanıcı dostu mesajlara çevir
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      // Google Sign-In errors
      case 'account-exists-with-different-credential':
        return 'Bu email başka bir yöntemle kullanılıyor';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri';
      case 'operation-not-allowed':
        return 'Google girişi etkinleştirilmemiş';
      case 'user-disabled':
        return 'Hesap devre dışı bırakılmış';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'network-request-failed':
        return 'İnternet bağlantısını kontrol edin';

      // Email/Password errors
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın';
      case 'wrong-password':
        return 'Yanlış şifre';

      default:
        return 'Giriş hatası: $code';
    }
  }
}
