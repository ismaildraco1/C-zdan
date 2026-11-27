import 'dart:async';

import '../domain/models.dart';

export '../domain/models.dart' show UserProfile;

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Kayıt oldu ama e-posta doğrulaması bekleniyor; oturum açılmadı.
/// Bu bir hata değil, kullanıcıya "e-postanı doğrula" gösterilir.
class EmailConfirmationRequired extends AuthException {
  const EmailConfirmationRequired(this.email)
    : super('E-postanı doğrulaman gerekiyor. Gelen kutunu kontrol et.');

  final String email;
}

abstract class AuthRepository {
  Future<UserProfile?> currentUser();
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Oturumdaki kullanıcının şifresini değiştirir (şifre yenileme bağlantısıyla
  /// gelen oturum da buna dahildir).
  Future<void> updatePassword(String newPassword);

  /// Oturum uygulamanın dışında değişti: süresi doldu, başka yerden iptal edildi
  /// ya da bir e-posta bağlantısı oturum açtı. Dinleyen [currentUser]'ı yeniden okur.
  Stream<void> get sessionChanged;

  /// E-postadaki şifre yenileme bağlantısı uygulamayı açıp oturum kurduğunda
  /// bir olay yayar.
  Stream<void> get passwordRecovery;
}

class _Account {
  _Account(this.password, this.profile, {this.confirmed = true});
  String password;
  UserProfile profile;
  bool confirmed;
}

/// Bellekte çalışan sahte hesap servisi. Uygulama kapanınca hesaplar silinir.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.requireConfirmation = false});

  /// Açıksa kayıt oturum açmaz ve e-posta doğrulaması ister (Supabase'in
  /// varsayılan davranışı).
  final bool requireConfirmation;
  final Map<String, _Account> _accounts = {};
  final StreamController<void> _recovery = StreamController<void>.broadcast();
  final StreamController<void> _sessionChanged =
      StreamController<void>.broadcast();
  String? _currentKey;

  @override
  Stream<void> get sessionChanged => _sessionChanged.stream;

  /// Testlerde oturumun dışarıdan sona ermesini taklit eder.
  void endSession() {
    _currentKey = null;
    _sessionChanged.add(null);
  }

  /// Testlerde başka yerden (ör. doğrulama bağlantısıyla) oturum açılmasını taklit eder.
  void startSession(String email) {
    _currentKey = _key(email);
    _sessionChanged.add(null);
  }

  /// Testlerde e-posta doğrulamasını elle tamamlar.
  void confirm(String email) => _accounts[_key(email)]?.confirmed = true;

  /// Testlerde şifre yenileme bağlantısına tıklanmasını taklit eder.
  Future<void> triggerRecovery(String email) async {
    final key = _key(email);
    if (!_accounts.containsKey(key)) return;
    _currentKey = key;
    _recovery.add(null);
  }

  @override
  Stream<void> get passwordRecovery => _recovery.stream;

  static String _key(String email) => email.trim().toLowerCase();

  @override
  Future<UserProfile?> currentUser() async =>
      _currentKey == null ? null : _accounts[_currentKey]?.profile;

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final account = _accounts[_key(email)];
    if (account == null) {
      throw const AuthException('Bu e-posta ile kayıtlı hesap yok.');
    }
    if (account.password != password) {
      throw const AuthException('Şifre hatalı.');
    }
    if (!account.confirmed) {
      throw EmailConfirmationRequired(account.profile.email);
    }
    _currentKey = _key(email);
    return account.profile;
  }

  @override
  Future<UserProfile> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final key = _key(email);
    if (_accounts.containsKey(key)) {
      throw const AuthException('Bu e-posta ile zaten bir hesap var.');
    }
    final profile = UserProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
    );
    _accounts[key] = _Account(
      password,
      profile,
      confirmed: !requireConfirmation,
    );
    if (requireConfirmation) throw EmailConfirmationRequired(profile.email);
    _currentKey = key;
    return profile;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => _currentKey = null;

  @override
  Future<void> deleteAccount() async {
    final key = _currentKey;
    if (key == null) throw const AuthException('Oturum açık değil.');
    _accounts.remove(key);
    _currentKey = null;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final key = _currentKey;
    final account = key == null ? null : _accounts[key];
    if (account == null) throw const AuthException('Oturum açık değil.');
    if (newPassword.length < 8) {
      throw const AuthException('Şifre en az 8 karakter olmalı.');
    }
    account.password = newPassword;
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final key = _currentKey;
    final account = key == null ? null : _accounts[key];
    if (key == null || account == null) {
      throw const AuthException('Oturum açık değil.');
    }
    account.profile = profile;
    return profile;
  }
}
