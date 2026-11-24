import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../auth_repository.dart';
import 'error_messages.dart';

/// Supabase Auth ile e-posta/şifre girişi. Ad, soyad ve telefon kullanıcının
/// `user_metadata` alanında tutulur. Google ve Apple bu sürümde kapalıdır.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client, {
    this.redirectTo = 'io.cuzdan.app://login-callback/',
  });

  final sb.SupabaseClient _client;

  /// Şifre sıfırlama ve e-posta doğrulama bağlantılarının döneceği adres.
  final String redirectTo;

  sb.GoTrueClient get _auth => _client.auth;

  UserProfile _profile(sb.User u) {
    final m = u.userMetadata ?? const <String, dynamic>{};
    String field(String key) => (m[key] as String?) ?? '';
    return UserProfile(
      firstName: field('first_name'),
      lastName: field('last_name'),
      email: u.email ?? '',
      phone: field('phone'),
    );
  }

  /// Her Supabase/ağ hatasını Türkçe bir [AuthException]'a çevirir.
  Future<T> _guard<T>(Future<T> Function() action, {String? email}) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } catch (e) {
      if (email != null &&
          e is sb.AuthException &&
          e.code == 'email_not_confirmed') {
        throw EmailConfirmationRequired(email);
      }
      throw AuthException(turkishAuthMessage(e));
    }
  }

  @override
  Future<UserProfile?> currentUser() async {
    final u = _auth.currentUser;
    return u == null ? null : _profile(u);
  }

  @override
  Future<UserProfile> signIn(String email, String password) {
    final mail = email.trim();
    return _guard(() async {
      final r = await _auth.signInWithPassword(email: mail, password: password);
      final u = r.user;
      if (u == null) {
        throw const AuthException('Bir şeyler ters gitti. Tekrar dene.');
      }
      return _profile(u);
    }, email: mail);
  }

  @override
  Future<UserProfile> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    final mail = email.trim();
    return _guard(() async {
      final r = await _auth.signUp(
        email: mail,
        password: password,
        emailRedirectTo: redirectTo,
        data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
      );
      // Oturum yoksa e-posta doğrulaması bekleniyor (Supabase varsayılanı).
      // Zaten kayıtlı bir adres de aynı yanıtı alır; hesap var/yok bilgisi sızmaz.
      if (r.session == null) throw EmailConfirmationRequired(mail);
      return _profile(r.user!);
    });
  }

  @override
  bool get supportsSocialLogin => false;

  @override
  Future<UserProfile> signInWithGoogle() async =>
      throw const AuthException('Google ile giriş yakında gelecek.');

  @override
  Future<UserProfile> signInWithApple() async =>
      throw const AuthException('Apple ile giriş yakında gelecek.');

  @override
  Future<void> sendPasswordReset(String email) => _guard(
    () => _auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo),
  );

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_my_account');
    } catch (_) {
      throw const AuthException(
        'Hesap silinemedi. Bağlantını kontrol edip tekrar dene.',
      );
    }
    // Hesap artık yok; yerel oturumu kapat. Sunucu reddederse de yerelde çıkış yap.
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) => _guard(() async {
    final r = await _auth.updateUser(
      sb.UserAttributes(
        data: {
          'first_name': profile.firstName,
          'last_name': profile.lastName,
          'phone': profile.phone,
        },
      ),
    );
    final u = r.user;
    return u == null ? profile : _profile(u);
  });

  @override
  Future<void> updatePassword(String newPassword) =>
      _guard(() => _auth.updateUser(sb.UserAttributes(password: newPassword)));

  @override
  Stream<void> get sessionChanged => _auth.onAuthStateChange
      .where(
        (s) =>
            s.event == sb.AuthChangeEvent.signedIn ||
            s.event == sb.AuthChangeEvent.signedOut ||
            s.event == sb.AuthChangeEvent.userUpdated,
      )
      .map((_) {});

  @override
  Stream<void> get passwordRecovery => _auth.onAuthStateChange
      .where((s) => s.event == sb.AuthChangeEvent.passwordRecovery)
      .map((_) {});
}
