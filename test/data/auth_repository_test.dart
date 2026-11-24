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
    await repo.updateProfile(UserProfile(
      firstName: 'Ayşegül',
      lastName: current.lastName,
      email: current.email,
      phone: current.phone,
    ));
    expect((await repo.currentUser())?.firstName, 'Ayşegül');
  });

  test('Google ve Apple girişi bir kullanıcı döndürür', () async {
    expect((await FakeAuthRepository().signInWithGoogle()).email, isNotEmpty);
    expect((await FakeAuthRepository().signInWithApple()).email, isNotEmpty);
  });
}
