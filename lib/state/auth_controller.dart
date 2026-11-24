import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

/// Oturum durumunu ve giriş/kayıt işlemlerini yönetir.
class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  final AuthRepository _repo;
  UserProfile? _user;
  String? _error;
  bool _busy = false;

  UserProfile? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  /// Uygulama açılırken var olan oturumu yükler.
  Future<void> restore() async {
    _user = await _repo.currentUser();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email, password));

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) =>
      _run(() => _repo.signUp(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
          ));

  Future<bool> google() => _run(_repo.signInWithGoogle);
  Future<bool> apple() => _run(_repo.signInWithApple);

  Future<bool> sendReset(String email) async {
    _begin();
    try {
      await _repo.sendPasswordReset(email);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _end();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Yazılan e-posta hesabınkiyle eşleşmezse hiçbir şey silinmez.
  Future<bool> deleteAccount(String typedEmail) async {
    final current = _user;
    if (current == null) return false;
    String norm(String s) => s.trim().toLowerCase();
    if (norm(typedEmail) != norm(current.email)) {
      _error = 'E-posta adresi eşleşmiyor.';
      notifyListeners();
      return false;
    }
    _begin();
    try {
      await _repo.deleteAccount();
      _user = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _end();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _user = await _repo.updateProfile(profile);
    notifyListeners();
  }

  Future<bool> _run(Future<UserProfile> Function() action) async {
    _begin();
    try {
      _user = await action();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _end();
    }
  }

  void _begin() {
    _busy = true;
    _error = null;
    notifyListeners();
  }

  void _end() {
    _busy = false;
    notifyListeners();
  }
}
