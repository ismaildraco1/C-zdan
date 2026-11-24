import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/ui/widgets/buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key, TextField;

import '../support/app_harness.dart';
import '../support/test_feed.dart';

Finder saveButton(String label) => find.widgetWithText(PrimaryButton, label);

void main() {
  Future<Harness> openEkle(WidgetTester tester) async {
    final h = await pumpApp(tester, signedIn: true);
    h.feed.push({
      AssetKind.usd: quote('USD', 41.18, at: DateTime.now()),
      AssetKind.gramGold: quote('GRAM', 4148, at: DateTime.now()),
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-ekle')));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> pickUsd(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tur-usd')));
    await tester.pumpAndSettle();
  }

  group('Varlık ekle', () {
    testWidgets('USD ve 2.500 için önizleme 102.950,00 TL gösterir',
        (tester) async {
      await openEkle(tester);
      await pickUsd(tester);
      await tester.enterText(find.byKey(const Key('miktar')), '2.500');
      await tester.pumpAndSettle();

      expect(find.text('₺ 102.950,00'), findsOneWidget);
      expect(find.textContaining('1 USD = ₺ 41,18'), findsOneWidget);
    });

    for (final c in [
      ('boş', '', 'Önce bir miktar yaz.'),
      ('sıfır', '0', 'Miktar 0’dan büyük bir sayı olmalı.'),
      ('harf', 'abc', 'Miktar 0’dan büyük bir sayı olmalı.'),
      ('negatif', '-5', 'Miktar 0’dan büyük bir sayı olmalı.'),
    ]) {
      testWidgets('${c.$1} miktarda düğme pasif ve neden yazılı', (tester) async {
        final h = await openEkle(tester);
        await pickUsd(tester);
        await tester.enterText(find.byKey(const Key('miktar')), c.$2);
        await tester.pumpAndSettle();

        expect(tester.widget<PrimaryButton>(saveButton('Portföye ekle')).onPressed,
            isNull);
        expect(find.text(c.$3), findsOneWidget);
        expect(h.portfolio.holdings, isEmpty);
      });
    }

    testWidgets('eklenince Portföy’e dönülür ve toplam artar', (tester) async {
      final h = await openEkle(tester);
      await pickUsd(tester);
      await tester.enterText(find.byKey(const Key('miktar')), '100');
      await tester.enterText(find.byKey(const Key('not')), 'Tatil');
      await tester.pumpAndSettle();
      await tester.tap(saveButton('Portföye ekle'));
      await tester.pumpAndSettle();

      expect(h.portfolio.holdings.single.kind, AssetKind.usd);
      expect(h.portfolio.holdings.single.note, 'Tatil');
      expect(find.text('Varlıklarım'), findsOneWidget);
      expect(find.text('₺ 4.118,00'), findsWidgets);
    });

    testWidgets('fiyat yokken önizleme tire gösterir ve eklenebilir',
        (tester) async {
      final h = await pumpApp(tester, signedIn: true);
      await tester.tap(find.byKey(const Key('nav-ekle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tur-eur')));
      await tester.enterText(find.byKey(const Key('miktar')), '10');
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      await tester.tap(saveButton('Portföye ekle'));
      await tester.pumpAndSettle();
      expect(h.portfolio.holdings, hasLength(1));
    });

    testWidgets('aynı türden iki kayıt iki satır olur', (tester) async {
      final h = await pumpApp(tester, signedIn: true);
      await h.portfolio.add(AssetKind.usd, 100, '');
      await h.portfolio.add(AssetKind.usd, 50, '');
      await tester.pumpAndSettle();
      expect(find.text('Amerikan Doları'), findsNWidgets(2));
    });
  });

  group('Döviz detayı', () {
    Future<Harness> openDetay(WidgetTester tester) async {
      final h = await pumpApp(tester, signedIn: true);
      await h.portfolio.add(AssetKind.usd, 2500, '');
      h.feed.push({AssetKind.usd: quote('USD', 41.0, at: DateTime.now())});
      h.feed.push({AssetKind.usd: quote('USD', 41.18, at: DateTime.now())});
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amerikan Doları'));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('miktar, değer ve alış/satış fiyatını gösterir', (tester) async {
      await openDetay(tester);
      expect(find.text('Elindeki 2.500 USD'), findsOneWidget);
      expect(find.text('₺ 102.950,00'), findsOneWidget);
      expect(find.text('41,1800'), findsOneWidget);
      expect(find.text('42,1800'), findsOneWidget);
      expect(find.text('41,0000 – 41,1800'), findsOneWidget);
      expect(find.byKey(const Key('grafik')), findsOneWidget);
    });

    testWidgets('yeterli veri yokken grafik yerine bilgi gösterir',
        (tester) async {
      final h = await pumpApp(tester, signedIn: true);
      await h.portfolio.add(AssetKind.usd, 100, '');
      h.feed.push({AssetKind.usd: quote('USD', 41.18, at: DateTime.now())});
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amerikan Doları'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('grafik')), findsNothing);
      expect(find.text('Grafik için fiyat bekleniyor'), findsOneWidget);
    });

    testWidgets('Varlığı sil onay ister, Vazgeç kaydı korur', (tester) async {
      final h = await openDetay(tester);
      await tester.tap(find.text('Varlığı sil'));
      await tester.pumpAndSettle();
      expect(find.text('Varlığı sil?'), findsOneWidget);

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(h.portfolio.holdings, hasLength(1));
    });

    testWidgets('Varlığı sil onaylanınca kayıt kalkar ve Portföy’e dönülür',
        (tester) async {
      final h = await openDetay(tester);
      await tester.tap(find.text('Varlığı sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(h.portfolio.holdings, isEmpty);
      expect(find.text('İlk varlığını ekle'), findsOneWidget);
    });

    testWidgets('Miktarı düzenle mevcut değerle açılır ve kaydeder',
        (tester) async {
      final h = await openDetay(tester);
      await tester.tap(find.text('Miktarı düzenle'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byKey(const Key('miktar'))).controller!.text,
          '2.500');
      await tester.enterText(find.byKey(const Key('miktar')), '3000');
      await tester.pumpAndSettle();
      await tester.tap(saveButton('Değişiklikleri kaydet'));
      await tester.pumpAndSettle();

      expect(h.portfolio.holdings.single.amount, 3000);
      expect(find.text('Elindeki 3.000 USD'), findsOneWidget);
    });
  });
}
