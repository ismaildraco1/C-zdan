import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/ui/widgets/buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key;

import '../support/app_harness.dart';
import '../support/flaky_repository.dart';
import '../support/test_feed.dart';

Finder btn(String label) => find.widgetWithText(PrimaryButton, label);
bool enabled(WidgetTester t, String label) =>
    t.widget<PrimaryButton>(btn(label)).onPressed != null;

const _email = 'ayse.yilmaz@ornek.com';

Future<FakeAuthRepository> registered({bool confirm = false}) async {
  final repo = FakeAuthRepository(requireConfirmation: confirm);
  try {
    await repo.signUp(
      firstName: 'Ayşe',
      lastName: 'Yılmaz',
      email: _email,
      password: 'ornek-sifre',
    );
  } on EmailConfirmationRequired {
    // beklenen
  }
  if (!confirm) await repo.signOut();
  return repo;
}

void main() {
  group('e-posta doğrulaması', () {
    Future<Harness> signUpWithConfirmation(WidgetTester tester) async {
      final h = await pumpApp(
        tester,
        authRepo: FakeAuthRepository(requireConfirmation: true),
      );
      await tester.tap(find.text('Kayıt ol'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('ad')), 'Ayşe');
      await tester.enterText(find.byKey(const Key('soyad')), 'Yılmaz');
      await tester.enterText(find.byKey(const Key('eposta')), _email);
      await tester.enterText(find.byKey(const Key('sifre')), 'ornek-sifre');
      await tester.tap(find.byKey(const Key('kosul')));
      await tester.pumpAndSettle();
      await tester.tap(btn('Hesap oluştur'));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('kayıt doğrulama ekranını açar, hata göstermez', (
      tester,
    ) async {
      final h = await signUpWithConfirmation(tester);

      expect(find.text('E-postanı doğrula'), findsOneWidget);
      expect(find.textContaining(_email), findsOneWidget);
      expect(find.textContaining('doğrulaman gerekiyor'), findsNothing);
      expect(h.auth.user, isNull);
    });

    testWidgets('Giriş ekranına dön kök ekrana gider', (tester) async {
      await signUpWithConfirmation(tester);
      await tester.tap(btn('Giriş ekranına dön'));
      await tester.pumpAndSettle();
      expect(btn('Giriş yap'), findsOneWidget);
    });

    testWidgets('doğrulanmamış hesapla girişte açıklayıcı mesaj çıkar', (
      tester,
    ) async {
      final repo = await registered(confirm: true);
      await pumpApp(tester, authRepo: repo);
      await tester.enterText(find.byKey(const Key('eposta')), _email);
      await tester.enterText(find.byKey(const Key('sifre')), 'ornek-sifre');
      await tester.tap(btn('Giriş yap'));
      await tester.pumpAndSettle();

      expect(
        find.text('E-postanı doğrulaman gerekiyor. Gelen kutunu kontrol et.'),
        findsOneWidget,
      );
    });
  });

  group('şifre yenileme bağlantısı', () {
    Future<Harness> openRecovery(WidgetTester tester) async {
      final repo = await registered();
      final h = await pumpApp(tester, authRepo: repo);
      await repo.triggerRecovery(_email);
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('ana ekran yerine Yeni şifre belirle açılır', (tester) async {
      final h = await openRecovery(tester);
      expect(h.auth.recovering, isTrue);
      expect(find.text('Yeni şifre belirle'), findsOneWidget);
      expect(find.text('Varlıklarım'), findsNothing);
    });

    testWidgets('7 karakterlik şifre gönderilmez ve nedeni yazar', (
      tester,
    ) async {
      await openRecovery(tester);
      await tester.enterText(find.byKey(const Key('yeni')), '1234567');
      await tester.enterText(find.byKey(const Key('tekrar')), '1234567');
      await tester.pumpAndSettle();

      expect(enabled(tester, 'Şifreyi kaydet'), isFalse);
      expect(find.text('En az 8 karakter olmalı.'), findsOneWidget);
    });

    testWidgets('uyuşmayan şifreler gönderilmez ve nedeni yazar', (
      tester,
    ) async {
      await openRecovery(tester);
      await tester.enterText(find.byKey(const Key('yeni')), '12345678');
      await tester.enterText(find.byKey(const Key('tekrar')), '12345679');
      await tester.pumpAndSettle();

      expect(enabled(tester, 'Şifreyi kaydet'), isFalse);
      expect(find.text('Şifreler aynı değil.'), findsOneWidget);
    });

    testWidgets('boş alanlarda düğme pasif, neden yazılmaz', (tester) async {
      await openRecovery(tester);
      expect(enabled(tester, 'Şifreyi kaydet'), isFalse);
      expect(find.text('En az 8 karakter olmalı.'), findsNothing);
    });

    testWidgets('geçerli şifre kaydedilir ve ana ekran açılır', (tester) async {
      final h = await openRecovery(tester);
      await tester.enterText(find.byKey(const Key('yeni')), 'yeni-sifre-1');
      await tester.enterText(find.byKey(const Key('tekrar')), 'yeni-sifre-1');
      await tester.pumpAndSettle();
      await tester.tap(btn('Şifreyi kaydet'));
      await tester.pumpAndSettle();

      expect(h.auth.recovering, isFalse);
      expect(find.text('Varlıklarım'), findsOneWidget);
      await h.repo.signOut();
      expect((await h.repo.signIn(_email, 'yeni-sifre-1')).email, _email);
    });

    testWidgets('bağlantı başka bir ekran açıkken gelse de Yeni şifre açılır', (
      tester,
    ) async {
      final repo = await registered();
      await pumpApp(tester, authRepo: repo);
      await tester.tap(find.text('Şifremi unuttum'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('eposta')), _email);
      await tester.tap(btn('Sıfırlama bağlantısı gönder'));
      await tester.pumpAndSettle();
      expect(find.text('Bağlantıyı gönderdik'), findsOneWidget);

      await repo.triggerRecovery(_email);
      await tester.pumpAndSettle();

      expect(find.text('Yeni şifre belirle'), findsOneWidget);
      expect(find.text('Bağlantıyı gönderdik'), findsNothing);
    });

    testWidgets('Vazgeç ve çıkış yap Giriş ekranına döner', (tester) async {
      final h = await openRecovery(tester);
      await tester.tap(find.text('Vazgeç ve çıkış yap'));
      await tester.pumpAndSettle();

      expect(h.auth.user, isNull);
      expect(h.auth.recovering, isFalse);
      expect(btn('Giriş yap'), findsOneWidget);
    });
  });

  testWidgets(
    'Profil’den Şifreyi değiştir şifreyi günceller ve Profil’e döner',
    (tester) async {
      final repo = await registered();
      final h = await pumpApp(tester, authRepo: repo);
      await h.auth.signIn(_email, 'ornek-sifre');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-ayarlar')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ayşe Yılmaz'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Şifreyi değiştir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('yeni')), 'yeni-sifre-1');
      await tester.enterText(find.byKey(const Key('tekrar')), 'yeni-sifre-1');
      await tester.pumpAndSettle();
      await tester.tap(btn('Şifreyi kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Kullanıcı bilgileri'), findsOneWidget);
      expect(find.text('Şifren değiştirildi.'), findsOneWidget);
      await h.repo.signOut();
      expect((await h.repo.signIn(_email, 'yeni-sifre-1')).email, _email);
    },
  );

  group('sosyal giriş kapalıyken', () {
    testWidgets('Giriş’te düğmeler pasif ve yakında yazar', (tester) async {
      await pumpApp(tester, authRepo: FakeAuthRepository(socialLogin: false));
      expect(find.text('Google ve Apple ile giriş yakında.'), findsOneWidget);
      final g = tester.widget<SocialButton>(
        find.widgetWithText(SocialButton, 'Google ile devam et'),
      );
      final a = tester.widget<SocialButton>(
        find.widgetWithText(SocialButton, 'Apple ile devam et'),
      );
      expect(g.onTap, isNull);
      expect(a.onTap, isNull);
    });

    testWidgets('açıkken düğmeler çalışır ve not görünmez', (tester) async {
      await pumpApp(tester);
      expect(find.text('Google ve Apple ile giriş yakında.'), findsNothing);
    });
  });

  group('depo hataları ekranda görünür', () {
    testWidgets(
      'kaydedilemeyen varlık için Ekle ekranı hata gösterir ve açık kalır',
      (tester) async {
        final repo = FlakyHoldingsRepository();
        final h = await pumpApp(tester, signedIn: true, holdingsRepo: repo);
        h.feed.push({AssetKind.usd: quote('USD', 41.18, at: DateTime.now())});
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('nav-ekle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tur-usd')));
        await tester.enterText(find.byKey(const Key('miktar')), '100');
        await tester.pumpAndSettle();
        repo.failing = true;

        await tester.tap(btn('Portföye ekle'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Değişiklik kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
          ),
          findsOneWidget,
        );
        expect(find.text('Varlık ekle'), findsOneWidget); // ekran kapanmadı
        expect(h.portfolio.holdings, isEmpty);
        expect(enabled(tester, 'Portföye ekle'), isTrue); // tekrar denenebilir
      },
    );

    testWidgets('silinemeyen varlık için Detay açık kalır ve hata gösterir', (
      tester,
    ) async {
      final repo = FlakyHoldingsRepository();
      final h = await pumpApp(tester, signedIn: true, holdingsRepo: repo);
      await h.portfolio.add(AssetKind.usd, 100, '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amerikan Doları'));
      await tester.pumpAndSettle();
      repo.failing = true;

      await tester.tap(find.text('Varlığı sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(h.portfolio.holdings, hasLength(1));
      expect(
        find.text(
          'Değişiklik kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
        ),
        findsOneWidget,
      );
      expect(find.text('Miktarı düzenle'), findsOneWidget); // Detay açık
    });

    testWidgets('yüklenemeyen varlıklar için Portföy Tekrar dene sunar', (
      tester,
    ) async {
      final repo = FlakyHoldingsRepository()..failing = true;
      final h = await pumpApp(tester, signedIn: true, holdingsRepo: repo);
      expect(
        find.text(
          'Varlıkların yüklenemedi. Bağlantını kontrol edip tekrar dene.',
        ),
        findsOneWidget,
      );
      expect(find.text('İlk varlığını ekle'), findsNothing);

      repo.failing = false;
      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle();

      expect(h.portfolio.error, isNull);
      expect(find.text('İlk varlığını ekle'), findsOneWidget);
    });
  });
}
