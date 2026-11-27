import 'package:cuzdan/ui/widgets/buttons.dart';
import 'package:cuzdan/ui/widgets/fields.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key;

import '../support/app_harness.dart';

Finder button(String label) => find.widgetWithText(PrimaryButton, label);

void main() {
  group('Validators', () {
    test('e-posta biçimini denetler', () {
      expect(Validators.email('ayse@ornek.com'), isNull);
      expect(Validators.email('  ayse@ornek.com '), isNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
    test('şifre en az 8 karakter ister', () {
      expect(Validators.password('1234567'), 'En az 8 karakter olmalı.');
      expect(Validators.password('12345678'), isNull);
    });
  });

  testWidgets('oturum yokken Giriş ekranı açılır', (tester) async {
    await pumpApp(tester);
    expect(find.text('Cüzdan'), findsOneWidget);
    expect(button('Giriş yap'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
    expect(find.text('veya'), findsNothing);
  });

  testWidgets('geçersiz e-postayla giriş hata gösterir ve oturum açmaz', (
    tester,
  ) async {
    final h = await pumpApp(tester, registered: true);
    await tester.enterText(find.byKey(const Key('eposta')), 'abc');
    await tester.enterText(find.byKey(const Key('sifre')), 'ornek-sifre');
    await tester.tap(button('Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.text('Geçerli bir e-posta adresi yaz.'), findsOneWidget);
    expect(h.auth.user, isNull);
  });

  testWidgets('yanlış şifre hata mesajı gösterir', (tester) async {
    await pumpApp(tester, registered: true);
    await tester.enterText(
      find.byKey(const Key('eposta')),
      'ayse.yilmaz@ornek.com',
    );
    await tester.enterText(find.byKey(const Key('sifre')), 'yanlis-sifre');
    await tester.tap(button('Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.text('Şifre hatalı.'), findsOneWidget);
  });

  testWidgets('Girişteki şifre hatası Kayıt ekranında görünmez', (
    tester,
  ) async {
    await pumpApp(tester, registered: true);
    await tester.enterText(
      find.byKey(const Key('eposta')),
      'ayse.yilmaz@ornek.com',
    );
    await tester.enterText(find.byKey(const Key('sifre')), 'yanlis-sifre');
    await tester.tap(button('Giriş yap'));
    await tester.pumpAndSettle();
    expect(find.text('Şifre hatalı.'), findsOneWidget);

    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();
    expect(find.text('Şifre hatalı.'), findsNothing);
  });

  testWidgets('doğru bilgilerle giriş ana ekranı açar', (tester) async {
    final h = await pumpApp(tester, registered: true);
    await tester.enterText(
      find.byKey(const Key('eposta')),
      'ayse.yilmaz@ornek.com',
    );
    await tester.enterText(find.byKey(const Key('sifre')), 'ornek-sifre');
    await tester.tap(button('Giriş yap'));
    await tester.pumpAndSettle();

    expect(h.auth.user, isNotNull);
    expect(find.text('Varlıklarım'), findsOneWidget);
    expect(button('Giriş yap'), findsNothing);
  });

  testWidgets('oturum açıkken uygulama doğrudan ana ekranla açılır', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    expect(find.text('Varlıklarım'), findsOneWidget);
  });

  group('Kayıt', () {
    Future<void> openKayit(WidgetTester tester) async {
      await tester.tap(find.text('Kayıt ol'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      String password = 'ornek-sifre',
    }) async {
      await tester.enterText(find.byKey(const Key('ad')), 'Ayşe');
      await tester.enterText(find.byKey(const Key('soyad')), 'Yılmaz');
      await tester.enterText(
        find.byKey(const Key('eposta')),
        'ayse.yilmaz@ornek.com',
      );
      await tester.enterText(find.byKey(const Key('sifre')), password);
    }

    testWidgets('koşul kutusu işaretli değilken Hesap oluştur pasif', (
      tester,
    ) async {
      await pumpApp(tester);
      await openKayit(tester);
      expect(
        tester.widget<PrimaryButton>(button('Hesap oluştur')).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('kosul')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PrimaryButton>(button('Hesap oluştur')).onPressed,
        isNotNull,
      );
    });

    testWidgets('7 karakterlik şifre hata verir', (tester) async {
      final h = await pumpApp(tester);
      await openKayit(tester);
      await fill(tester, password: 'kisa123');
      await tester.tap(find.byKey(const Key('kosul')));
      await tester.pumpAndSettle();
      await tester.tap(button('Hesap oluştur'));
      await tester.pumpAndSettle();

      expect(find.text('En az 8 karakter olmalı.'), findsWidgets);
      expect(h.auth.user, isNull);
    });

    testWidgets('başarılı kayıt ana ekranı açar', (tester) async {
      final h = await pumpApp(tester);
      await openKayit(tester);
      await fill(tester);
      await tester.tap(find.byKey(const Key('kosul')));
      await tester.pumpAndSettle();
      await tester.tap(button('Hesap oluştur'));
      await tester.pumpAndSettle();

      expect(h.auth.user?.email, 'ayse.yilmaz@ornek.com');
      expect(find.text('Varlıklarım'), findsOneWidget);
      expect(button('Hesap oluştur'), findsNothing);
    });

    testWidgets('Giriş yap bağlantısı Giriş ekranına döner', (tester) async {
      await pumpApp(tester);
      await openKayit(tester);
      await tester.tap(find.text('Giriş yap').last);
      await tester.pumpAndSettle();
      expect(button('Giriş yap'), findsOneWidget);
    });
  });

  testWidgets('Şifremi unuttum akışı gönderildi ekranını gösterir', (
    tester,
  ) async {
    await pumpApp(tester, registered: true);
    await tester.tap(find.text('Şifremi unuttum'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('eposta')),
      'ayse.yilmaz@ornek.com',
    );
    await tester.tap(button('Sıfırlama bağlantısı gönder'));
    await tester.pumpAndSettle();

    expect(find.text('Bağlantıyı gönderdik'), findsOneWidget);
    expect(find.textContaining('ayse.yilmaz@ornek.com'), findsOneWidget);

    await tester.tap(button('Giriş ekranına dön'));
    await tester.pumpAndSettle();
    expect(button('Giriş yap'), findsOneWidget);
  });

  testWidgets('Şifremi unuttum geçersiz e-postayla ilerlemez', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Şifremi unuttum'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('eposta')), 'abc');
    await tester.tap(button('Sıfırlama bağlantısı gönder'));
    await tester.pumpAndSettle();

    expect(find.text('Geçerli bir e-posta adresi yaz.'), findsOneWidget);
    expect(find.text('Bağlantıyı gönderdik'), findsNothing);
  });

  testWidgets('Kayıt ekranında da Google, Apple ve "veya" yok', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
    expect(find.text('veya'), findsNothing);
    expect(button('Hesap oluştur'), findsOneWidget);
  });
}
