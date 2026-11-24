import 'package:cuzdan/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeAuthRepository> registered() async {
  final repo = FakeAuthRepository();
  await repo.signUp(
    firstName: 'Ayşe',
    lastName: 'Yılmaz',
    email: 'ayse.yilmaz@ornek.com',
    password: 'ornek-sifre',
  );
  return repo;
}

void main() {
  test('kayıttan sonra currentUser dolu olur', () async {
    final repo = await registered();
    final user = await repo.currentUser();
    expect(user?.email, 'ayse.yilmaz@ornek.com');
    expect(user?.firstName, 'Ayşe');
  });

  test('yanlış şifre AuthException fırlatır', () async {
    final repo = await registered();
    await repo.signOut();
    expect(
      () => repo.signIn('ayse.yilmaz@ornek.com', 'yanlis'),
      throwsA(isA<AuthException>()),
    );
  });

  test('e-posta büyük küçük harfe duyarsızdır', () async {
    final repo = await registered();
    await repo.signOut();
    final user = await repo.signIn(' AYSE.YILMAZ@ornek.com ', 'ornek-sifre');
    expect(user.firstName, 'Ayşe');
  });

  test('signOut sonrası currentUser null olur', () async {
    final repo = await registered();
    await repo.signOut();
    expect(await repo.currentUser(), isNull);
  });

  test('deleteAccount sonrası aynı bilgilerle giriş yapılamaz', () async {
    final repo = await registered();
    await repo.deleteAccount();
    expect(await repo.currentUser(), isNull);
    expect(
      () => repo.signIn('ayse.yilmaz@ornek.com', 'ornek-sifre'),
      throwsA(isA<AuthException>()),
    );
  });

  test('aynı e-postayla ikinci kayıt reddedilir', () async {
    final repo = await registered();
    expect(
      () => repo.signUp(
        firstName: 'Başka',
        lastName: 'Kişi',
        email: 'ayse.yilmaz@ornek.com',
        password: 'baska-sifre',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('updateProfile oturumdaki kullanıcıyı günceller', () async {
    final repo = await registered();
    final current = (await repo.currentUser())!;
    await repo.updateProfile(
      UserProfile(
        firstName: 'Ayşegül',
        lastName: current.lastName,
        email: current.email,
        phone: current.phone,
      ),
    );
    expect((await repo.currentUser())?.firstName, 'Ayşegül');
  });

  test('Google ve Apple girişi bir kullanıcı döndürür', () async {
    expect((await FakeAuthRepository().signInWithGoogle()).email, isNotEmpty);
    expect((await FakeAuthRepository().signInWithApple()).email, isNotEmpty);
  });

  group('e-posta doğrulaması', () {
    test('requireConfirmation açıkken kayıt oturum açmaz', () async {
      final repo = FakeAuthRepository(requireConfirmation: true);
      await expectLater(
        repo.signUp(
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          password: '12345678',
        ),
        throwsA(isA<EmailConfirmationRequired>()),
      );
      expect(await repo.currentUser(), isNull);
    });

    test('doğrulanmamış hesap giriş yapamaz, doğrulanınca yapar', () async {
      final repo = FakeAuthRepository(requireConfirmation: true);
      try {
        await repo.signUp(
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          password: '12345678',
        );
      } on EmailConfirmationRequired {
        // beklenen
      }
      await expectLater(
        repo.signIn('a@b.com', '12345678'),
        throwsA(isA<AuthException>()),
      );
      repo.confirm('a@b.com');
      expect((await repo.signIn('a@b.com', '12345678')).email, 'a@b.com');
    });
  });

  group('şifre yenileme', () {
    test('triggerRecovery kullanıcıyı oturuma alır ve olay yayar', () async {
      final repo = await registered();
      await repo.signOut();
      final events = <void>[];
      final sub = repo.passwordRecovery.listen(events.add);

      await repo.triggerRecovery('ayse.yilmaz@ornek.com');
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect((await repo.currentUser())?.email, 'ayse.yilmaz@ornek.com');
      await sub.cancel();
    });

    test(
      'updatePassword yeni şifreyi geçerli, eskisini geçersiz yapar',
      () async {
        final repo = await registered();
        await repo.updatePassword('yeni-sifre-1');
        await repo.signOut();

        expect(
          (await repo.signIn('ayse.yilmaz@ornek.com', 'yeni-sifre-1')).email,
          'ayse.yilmaz@ornek.com',
        );
        await repo.signOut();
        await expectLater(
          repo.signIn('ayse.yilmaz@ornek.com', 'ornek-sifre'),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('8 karakterden kısa yeni şifre reddedilir', () async {
      final repo = await registered();
      await expectLater(
        repo.updatePassword('kisa'),
        throwsA(isA<AuthException>()),
      );
    });

    test('oturum yokken updatePassword reddedilir', () async {
      final repo = FakeAuthRepository();
      await expectLater(
        repo.updatePassword('yeni-sifre-1'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  test('sosyal giriş sahte uygulamada varsayılan olarak açıktır', () {
    expect(FakeAuthRepository().supportsSocialLogin, isTrue);
    expect(FakeAuthRepository(socialLogin: false).supportsSocialLogin, isFalse);
  });
}
