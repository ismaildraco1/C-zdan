import '../domain/models.dart';

export '../domain/models.dart' show UserProfile;

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
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
  Future<UserProfile> signInWithGoogle();
  Future<UserProfile> signInWithApple();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<UserProfile> updateProfile(UserProfile profile);
}

class _Account {
  _Account(this.password, this.profile);
  String password;
  UserProfile profile;
}

/// Bellekte çalışan sahte hesap servisi. Uygulama kapanınca hesaplar silinir.
class FakeAuthRepository implements AuthRepository {
  final Map<String, _Account> _accounts = {};
  String? _currentKey;

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
    _accounts[key] = _Account(password, profile);
    _currentKey = key;
    return profile;
  }

  Future<UserProfile> _social(String firstName, String lastName) async {
    const email = 'ayse.yilmaz@ornek.com';
    final existing = _accounts[email];
    if (existing != null) {
      _currentKey = email;
      return existing.profile;
    }
    return signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: 'sosyal-giris',
    );
  }

  @override
  Future<UserProfile> signInWithGoogle() => _social('Ayşe', 'Yılmaz');

  @override
  Future<UserProfile> signInWithApple() => _social('Ayşe', 'Yılmaz');

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
