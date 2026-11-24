
import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/data/supabase/supabase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_supabase.dart';

const _redirect = 'io.cuzdan.app://login-callback/';

void main() {
  late FakeSupabase fake;
  late SupabaseAuthRepository repo;

  setUp(() {
    fake = FakeSupabase();
    repo = SupabaseAuthRepository(fake.client);
  });

  Future<void> signedIn() async {
    fake.on('POST /auth/v1/token', (_) => json(sessionJson()));
    await repo.signIn('ayse@ornek.com', '12345678');
  }

  group('signUp', () {
    test('doğrulama açıkken oturum gelmez: EmailConfirmationRequired', () async {
      fake.on('POST /auth/v1/signup', (_) => json({
            ...userJson(),
            'confirmation_sent_at': '2026-11-24T10:00:01Z',
          }));

      await expectLater(
        repo.signUp(
          firstName: 'Ayşe',
          lastName: 'Yılmaz',
          email: ' ayse@ornek.com ',
          password: '12345678',
        ),
        throwsA(
          isA<EmailConfirmationRequired>().having(
            (e) => e.email,
            'email',
            'ayse@ornek.com',
          ),
        ),
      );
      expect(await repo.currentUser(), isNull);
    });

    test('istek gövdesi e-posta, şifre ve profil alanlarını taşır', () async {
      fake.on('POST /auth/v1/signup', (_) => json(sessionJson()));
      await repo.signUp(
        firstName: ' Ayşe ',
        lastName: 'Yılmaz',
        email: ' ayse@ornek.com ',
        password: '12345678',
      );

      final call = fake.to('POST', '/auth/v1/signup').single;
      expect(call.body!['email'], 'ayse@ornek.com');
      expect(call.body!['password'], '12345678');
      expect(call.body!['data'], {'first_name': 'Ayşe', 'last_name': 'Yılmaz'});
      expect(call.url.queryParameters['redirect_to'], _redirect);
      expect(call.headers['apikey'], 'anon-key');
    });

    test('oturum gelirse kullanıcı profili döner', () async {
      fake.on('POST /auth/v1/signup', (_) => json(sessionJson()));
      final user = await repo.signUp(
        firstName: 'Ayşe',
        lastName: 'Yılmaz',
        email: 'ayse@ornek.com',
        password: '12345678',
      );
      expect(user.email, 'ayse@ornek.com');
      expect(user.firstName, 'Ayşe');
      expect((await repo.currentUser())?.email, 'ayse@ornek.com');
    });

    test('var olan e-posta Türkçe mesajla reddedilir', () async {
      fake.on('POST /auth/v1/signup', (_) => json(
            errorJson('user_already_exists', 'User already registered', 422),
            422,
          ));
      await expectLater(
        repo.signUp(
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          password: '12345678',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Bu e-posta ile zaten bir hesap var.',
        )),
      );
    });
  });

  group('signIn', () {
    test('şifre ile giriş yapar ve profili döndürür', () async {
      fake.on('POST /auth/v1/token', (_) => json(sessionJson(
            user: userJson(phone: '0532 000 00 00'),
          )));

      final user = await repo.signIn(' ayse@ornek.com ', '12345678');

      final call = fake.to('POST', '/auth/v1/token').single;
      expect(call.url.queryParameters['grant_type'], 'password');
      expect(call.body!['email'], 'ayse@ornek.com');
      expect(call.body!['password'], '12345678');
      expect(user.lastName, 'Yılmaz');
      expect(user.phone, '0532 000 00 00');
    });

    test('yanlış bilgiler tek ve genel bir mesaj verir', () async {
      fake.on('POST /auth/v1/token', (_) => json(
            errorJson('invalid_credentials', 'Invalid login credentials', 400),
            400,
          ));
      await expectLater(
        repo.signIn('ayse@ornek.com', 'yanlis'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'E-posta ya da şifre hatalı.',
        )),
      );
      expect(await repo.currentUser(), isNull);
    });

    test('doğrulanmamış e-posta EmailConfirmationRequired fırlatır', () async {
      fake.on('POST /auth/v1/token', (_) => json(
            errorJson('email_not_confirmed', 'Email not confirmed', 400),
            400,
          ));
      await expectLater(
        repo.signIn('ayse@ornek.com', '12345678'),
        throwsA(isA<EmailConfirmationRequired>()),
      );
    });

    test('ağ yokken çökmez, bağlantı mesajı verir', () async {
      fake.on('POST /auth/v1/token', (_) => throw http.ClientException('yok'));
      await expectLater(
        repo.signIn('ayse@ornek.com', '12345678'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Bağlantı kurulamadı. İnternetini kontrol et.',
        )),
      );
    });
  });

  test('sendPasswordReset e-postayı ve yönlendirme adresini yollar', () async {
    fake.on('POST /auth/v1/recover', (_) => json({}));
    await repo.sendPasswordReset(' ayse@ornek.com ');

    final call = fake.to('POST', '/auth/v1/recover').single;
    expect(call.body!['email'], 'ayse@ornek.com');
    expect(call.url.queryParameters['redirect_to'], _redirect);
  });

  test('signOut oturumu kapatır', () async {
    await signedIn();
    fake.on('POST /auth/v1/logout', (_) => http.Response('', 204));
    await repo.signOut();
    expect(await repo.currentUser(), isNull);
  });

  group('deleteAccount', () {
    test('SQL fonksiyonunu çağırır ve oturumu kapatır', () async {
      await signedIn();
      fake.on('POST /rest/v1/rpc/delete_my_account', (_) => http.Response('', 204));
      fake.on('POST /auth/v1/logout', (_) => http.Response('', 204));

      await repo.deleteAccount();

      final rpc = fake.to('POST', '/rest/v1/rpc/delete_my_account').single;
      expect(rpc.headers['authorization'], 'Bearer access-token');
      expect(await repo.currentUser(), isNull);
    });

    test('sunucu başarısızsa hata verir ve oturum açık kalır', () async {
      await signedIn();
      fake.on('POST /rest/v1/rpc/delete_my_account', (_) => json(
            {'message': 'boom', 'code': 'XX000'},
            500,
          ));

      await expectLater(
        repo.deleteAccount(),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Hesap silinemedi. Bağlantını kontrol edip tekrar dene.',
        )),
      );
      expect(await repo.currentUser(), isNotNull);
      expect(fake.to('POST', '/auth/v1/logout'), isEmpty);
    });
  });

  test('updateProfile ad, soyad ve telefonu user_metadata olarak yazar', () async {
    await signedIn();
    fake.on('PUT /auth/v1/user', (_) => json(userJson(
          first: 'Ayşegül',
          phone: '0532 000 00 00',
        )));

    final user = await repo.updateProfile(const UserProfile(
      firstName: 'Ayşegül',
      lastName: 'Yılmaz',
      email: 'ayse@ornek.com',
      phone: '0532 000 00 00',
    ));

    final call = fake.to('PUT', '/auth/v1/user').single;
    expect(call.body!['data'], {
      'first_name': 'Ayşegül',
      'last_name': 'Yılmaz',
      'phone': '0532 000 00 00',
    });
    expect(call.body!.containsKey('email'), isFalse);
    expect(user.firstName, 'Ayşegül');
  });

  group('updatePassword', () {
    test('yeni şifreyi yollar', () async {
      await signedIn();
      fake.on('PUT /auth/v1/user', (_) => json(userJson()));
      await repo.updatePassword('yeni-sifre-1');
      expect(fake.to('PUT', '/auth/v1/user').single.body!['password'], 'yeni-sifre-1');
    });

    test('zayıf şifre Türkçe mesajla reddedilir', () async {
      await signedIn();
      fake.on('PUT /auth/v1/user', (_) => json(
            errorJson('weak_password', 'Password is too weak', 422),
            422,
          ));
      await expectLater(
        repo.updatePassword('12345678'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Şifre çok zayıf. Daha uzun ya da daha karmaşık bir şifre dene.',
        )),
      );
    });
  });

  test('şifre yenileme bağlantısı (PKCE kodu) passwordRecovery olayı yayar',
      () async {
    fake.on('POST /auth/v1/recover', (_) => json({}));
    final events = <void>[];
    final sub = repo.passwordRecovery.listen(events.add);

    // Kullanıcı "şifremi unuttum" der, e-postadaki bağlantı uygulamayı kodla açar.
    await repo.sendPasswordReset('ayse@ornek.com');
    fake.on('POST /auth/v1/token', (_) => json(sessionJson()));
    await fake.client.auth.getSessionFromUrl(Uri.parse('$_redirect?code=abc123'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(fake.to('POST', '/auth/v1/token').single.url.queryParameters['grant_type'],
        'pkce');
    expect(events, hasLength(1));
    expect((await repo.currentUser())?.email, 'ayse@ornek.com');
    await sub.cancel();
  });

  test('Google ve Apple bu sürümde kapalıdır', () async {
    await expectLater(repo.signInWithGoogle(), throwsA(isA<AuthException>()));
    await expectLater(repo.signInWithApple(), throwsA(isA<AuthException>()));
  });
}
