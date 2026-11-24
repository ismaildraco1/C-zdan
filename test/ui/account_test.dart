import 'package:cuzdan/data/auth_repository.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/ui/widgets/buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key, TextField;

import '../support/app_harness.dart';

Finder btn(String label) => find.widgetWithText(PrimaryButton, label);

void main() {
  Future<Harness> openAyarlar(WidgetTester tester) async {
    final h = await pumpApp(tester, signedIn: true);
    await tester.tap(find.byKey(const Key('nav-ayarlar')));
    await tester.pumpAndSettle();
    return h;
  }

  Future<Harness> openProfil(WidgetTester tester) async {
    final h = await openAyarlar(tester);
    await tester.tap(find.text('Ayşe Yılmaz'));
    await tester.pumpAndSettle();
    return h;
  }

  group('Ayarlar', () {
    testWidgets('profil kartı ad ve e-postayı gösterir', (tester) async {
      await openAyarlar(tester);
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('ayse.yilmaz@ornek.com'), findsOneWidget);
      expect(find.text('AY'), findsOneWidget);
    });

    testWidgets('bölümleri ve satırları gösterir', (tester) async {
      await openAyarlar(tester);
      for (final t in [
        'Tercihler',
        'Güvenlik',
        'Hakkında',
        'Ana para birimi',
        'Türk Lirası (₺)',
        'Değer hesabı',
        'Alış fiyatı',
        'Fiyat bildirimleri',
        'Parmak izi / Face ID ile aç',
        'Bakiyeyi gizle',
        'Fiyat kaynağı',
        'Sürüm',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('fiyat kaynağı olarak gerçekte bağlı akışı yazar',
        (tester) async {
      await openAyarlar(tester);
      expect(find.text('Test fiyatları'), findsOneWidget);
      expect(find.text('Harem Altın'), findsNothing);
    });
  });

  group('Kullanıcı bilgileri', () {
    testWidgets('ad değişip kaydedilince Ayarlar kartında görünür',
        (tester) async {
      final h = await openProfil(tester);
      expect(find.text('Kullanıcı bilgileri'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('ad')), 'Ayşegül');
      await tester.tap(btn('Değişiklikleri kaydet'));
      await tester.pumpAndSettle();

      expect(h.auth.user?.firstName, 'Ayşegül');
      expect(find.text('Ayşegül Yılmaz'), findsOneWidget);
    });

    testWidgets('telefon kaydedilir', (tester) async {
      final h = await openProfil(tester);
      await tester.enterText(find.byKey(const Key('telefon')), '0532 000 00 00');
      await tester.tap(btn('Değişiklikleri kaydet'));
      await tester.pumpAndSettle();
      expect(h.auth.user?.phone, '0532 000 00 00');
    });

    testWidgets('boş ad kaydedilmez ve hata gösterir', (tester) async {
      final h = await openProfil(tester);
      await tester.enterText(find.byKey(const Key('ad')), '  ');
      await tester.tap(btn('Değişiklikleri kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Adını yaz.'), findsOneWidget);
      expect(h.auth.user?.firstName, 'Ayşe');
    });

    testWidgets('e-posta alanı değiştirilemez', (tester) async {
      await openProfil(tester);
      final field = tester.widget<TextField>(find.byKey(const Key('eposta')));
      expect(field.enabled, isFalse);
    });

    testWidgets('Çıkış yap Giriş ekranına döner', (tester) async {
      final h = await openProfil(tester);
      await tester.tap(find.text('Çıkış yap'));
      await tester.pumpAndSettle();

      expect(h.auth.user, isNull);
      expect(btn('Giriş yap'), findsOneWidget);
    });
  });

  group('Hesabı sil', () {
    Future<Harness> openHesapSil(WidgetTester tester) async {
      final h = await openProfil(tester);
      await h.portfolio.add(AssetKind.usd, 100, '');
      await tester.tap(find.text('Hesabı sil'));
      await tester.pumpAndSettle();
      return h;
    }

    bool enabled(WidgetTester tester) =>
        tester.widget<PrimaryButton>(btn('Hesabı kalıcı olarak sil')).onPressed !=
        null;

    testWidgets('e-posta eşleşmeden düğme pasif', (tester) async {
      await openHesapSil(tester);
      expect(find.textContaining('ayse.yilmaz@ornek.com'), findsWidgets);
      expect(enabled(tester), isFalse);

      await tester.enterText(find.byKey(const Key('onay')), 'baska@ornek.com');
      await tester.pumpAndSettle();
      expect(enabled(tester), isFalse);
    });

    testWidgets('harf ve boşluğa duyarsız eşleşince silinir, Giriş açılır',
        (tester) async {
      final h = await openHesapSil(tester);
      await tester.enterText(
          find.byKey(const Key('onay')), '  AYSE.YILMAZ@ORNEK.COM ');
      await tester.pumpAndSettle();
      expect(enabled(tester), isTrue);

      await tester.tap(btn('Hesabı kalıcı olarak sil'));
      await tester.pumpAndSettle();

      expect(h.auth.user, isNull);
      expect(btn('Giriş yap'), findsOneWidget);
      expect(h.portfolio.holdings, isEmpty);
      expect(
        () => h.repo.signIn('ayse.yilmaz@ornek.com', 'ornek-sifre'),
        throwsA(isA<AuthException>()),
      );
    });

    testWidgets('Vazgeç hesabı ve varlıkları korur', (tester) async {
      final h = await openHesapSil(tester);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(h.auth.user, isNotNull);
      expect(h.portfolio.holdings, hasLength(1));
      expect(find.text('Kullanıcı bilgileri'), findsOneWidget);
    });
  });
}
