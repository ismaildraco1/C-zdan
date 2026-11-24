import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AuthController> signedUp() async {
  final c = AuthController(FakeAuthRepository());
  final ok = await c.signUp(
    firstName: 'Ayşe',
    lastName: 'Yılmaz',
    email: 'ayse@ornek.com',
    password: 'ornek-sifre',
  );
  expect(ok, isTrue);
  return c;
}

void main() {
  test('başarılı kayıt kullanıcıyı ayarlar', () async {
    final c = await signedUp();
    expect(c.user?.email, 'ayse@ornek.com');
    expect(c.error, isNull);
  });

  test('yanlış şifre false döner ve hata mesajı yazar', () async {
    final c = await signedUp();
    await c.signOut();
    final ok = await c.signIn('ayse@ornek.com', 'yanlis');
    expect(ok, isFalse);
    expect(c.error, 'Şifre hatalı.');
    expect(c.user, isNull);
  });

  test('başarılı girişten sonra eski hata temizlenir', () async {
    final c = await signedUp();
    await c.signOut();
    await c.signIn('ayse@ornek.com', 'yanlis');
    await c.signIn('ayse@ornek.com', 'ornek-sifre');
    expect(c.error, isNull);
    expect(c.user, isNotNull);
  });

  test(
    'deleteAccount e-posta eşleşirse (harf ve boşluktan bağımsız) true',
    () async {
      final c = await signedUp();
      final ok = await c.deleteAccount('  AYSE@ORNEK.COM ');
      expect(ok, isTrue);
      expect(c.user, isNull);
    },
  );

  test('deleteAccount e-posta eşleşmezse false ve hesap silinmez', () async {
    final c = await signedUp();
    final ok = await c.deleteAccount('baska@ornek.com');
    expect(ok, isFalse);
    expect(c.user, isNotNull);
    await c.signOut();
    expect(await c.signIn('ayse@ornek.com', 'ornek-sifre'), isTrue);
  });

  test('saveProfile kullanıcıyı günceller', () async {
    final c = await signedUp();
    await c.saveProfile(
      UserProfile(
        firstName: 'Ayşegül',
        lastName: 'Yılmaz',
        email: 'ayse@ornek.com',
        phone: '0532 000 00 00',
      ),
    );
    expect(c.user?.firstName, 'Ayşegül');
    expect(c.user?.phone, '0532 000 00 00');
  });

  test('signOut kullanıcıyı temizler', () async {
    final c = await signedUp();
    await c.signOut();
    expect(c.user, isNull);
  });

  test('restore oturumdaki kullanıcıyı yükler', () async {
    final repo = FakeAuthRepository();
    await repo.signUp(
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.com',
      password: '12345678',
    );
    final c = AuthController(repo);
    expect(c.user, isNull);
    await c.restore();
    expect(c.user?.email, 'a@b.com');
  });

  test('sendReset hata yoksa true döner', () async {
    final c = AuthController(FakeAuthRepository());
    expect(await c.sendReset('a@b.com'), isTrue);
  });

  test('google ve apple girişi kullanıcıyı ayarlar', () async {
    final g = AuthController(FakeAuthRepository());
    expect(await g.google(), isTrue);
    expect(g.user, isNotNull);
    final a = AuthController(FakeAuthRepository());
    expect(await a.apple(), isTrue);
    expect(a.user, isNotNull);
  });

  group('e-posta doğrulaması ve şifre yenileme', () {
    test(
      'doğrulama gerekiyorsa signUp false döner, hata değil bilgi bırakır',
      () async {
        final c = AuthController(FakeAuthRepository(requireConfirmation: true));
        final ok = await c.signUp(
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          password: '12345678',
        );
        expect(ok, isFalse);
        expect(c.confirmationEmail, 'a@b.com');
        expect(c.error, isNull);
        expect(c.user, isNull);
      },
    );

    test('yenileme bağlantısı recovering ve user ayarlar', () async {
      final repo = FakeAuthRepository();
      await repo.signUp(
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        password: '12345678',
      );
      await repo.signOut();
      final c = AuthController(repo);
      expect(c.recovering, isFalse);

      await repo.triggerRecovery('a@b.com');
      await Future<void>.delayed(Duration.zero);

      expect(c.recovering, isTrue);
      expect(c.user?.email, 'a@b.com');
    });

    test('updatePassword başarılıysa recovering kapanır', () async {
      final repo = FakeAuthRepository();
      await repo.signUp(
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        password: '12345678',
      );
      await repo.signOut();
      final c = AuthController(repo);
      await repo.triggerRecovery('a@b.com');
      await Future<void>.delayed(Duration.zero);

      expect(await c.updatePassword('yeni-sifre-1'), isTrue);
      expect(c.recovering, isFalse);
    });

    test('kısa şifre updatePassword false döner ve hata yazar', () async {
      final c = await signedUp();
      expect(await c.updatePassword('kisa'), isFalse);
      expect(c.error, isNotNull);
    });
  });
}
