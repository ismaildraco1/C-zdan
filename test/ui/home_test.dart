import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key;

import '../support/app_harness.dart';
import '../support/test_feed.dart';

Map<AssetKind, Quote> allQuotes({DateTime? at}) => {
  AssetKind.gramGold: quote('GRAM', 4148, at: at, change: 0.84),
  AssetKind.quarterGold: quote('CEYREK', 6940, at: at, change: 0.79),
  AssetKind.halfGold: quote('YARIM', 13880, at: at),
  AssetKind.fullGold: quote('TAM', 27760, at: at),
  AssetKind.usd: quote('USD', 41.18, at: at, change: 0.21),
  AssetKind.eur: quote('EUR', 48.06, at: at, change: -0.12),
  AssetKind.gbp: quote('GBP', 55.24, at: at, change: 0.33),
};

Future<Harness> pumpWithSamplePortfolio(WidgetTester tester) async {
  final h = await pumpApp(tester, signedIn: true);
  await h.portfolio.add(AssetKind.gramGold, 40, '');
  await h.portfolio.add(AssetKind.quarterGold, 8, '');
  await h.portfolio.add(AssetKind.usd, 2500, '');
  await h.portfolio.add(AssetKind.eur, 1200, '');
  await h.portfolio.add(AssetKind.gbp, 600, '');
  h.feed.push(allQuotes(at: DateTime.now()));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('Portföy', () {
    testWidgets('örnek veriyle toplam ve beş satırı gösterir', (tester) async {
      await pumpWithSamplePortfolio(tester);

      expect(find.text('₺ 415.206,00'), findsOneWidget);
      for (final name in [
        'Gram Altın',
        'Çeyrek Altın',
        'Amerikan Doları',
        'Euro',
        'İngiliz Sterlini',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('₺ 102.950,00'), findsOneWidget);
      expect(find.text('2.500 USD'), findsOneWidget);
      expect(find.text('40 gr'), findsOneWidget);
    });

    testWidgets('satırda günlük değişim yönüyle görünür', (tester) async {
      await pumpWithSamplePortfolio(tester);
      expect(find.text('▲ %0,21'), findsOneWidget);
      expect(find.text('▼ %0,12'), findsOneWidget);
    });

    testWidgets('varlık yokken sıfır ve boş durum gösterir', (tester) async {
      await pumpApp(tester, signedIn: true);
      expect(find.text('₺ 0,00'), findsOneWidget);
      expect(find.text('İlk varlığını ekle'), findsOneWidget);
    });

    testWidgets('fiyat yokken satır değeri tire olur, çökme olmaz', (
      tester,
    ) async {
      final h = await pumpApp(tester, signedIn: true);
      await h.portfolio.add(AssetKind.usd, 100, '');
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('₺ 0,00'), findsOneWidget);
    });

    testWidgets('çok büyük miktar taşma yapmaz', (tester) async {
      final h = await pumpApp(tester, signedIn: true);
      await h.portfolio.add(AssetKind.usd, 999999999, '');
      h.feed.push(allQuotes(at: DateTime.now()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('999.999.999 USD'), findsOneWidget);
    });

    testWidgets('fiyat bayatsa Son güncelleme etiketi görünür', (tester) async {
      final h = await pumpApp(tester, signedIn: true);
      h.feed.push(
        allQuotes(at: DateTime.now().subtract(const Duration(minutes: 2))),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Son güncelleme'), findsWidgets);
      expect(find.textContaining('Canlı'), findsNothing);
    });

    testWidgets('fiyat tazeyse Canlı etiketi görünür', (tester) async {
      final h = await pumpApp(tester, signedIn: true);
      h.feed.push(allQuotes(at: DateTime.now()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Canlı'), findsWidgets);
      expect(find.textContaining('Son güncelleme'), findsNothing);
    });
  });

  group('Piyasa', () {
    Future<Harness> openPiyasa(WidgetTester tester) async {
      final h = await pumpApp(tester, signedIn: true);
      h.feed.push(allQuotes(at: DateTime.now()));
      h.feed.pushOns(quote('ONS', 3120.40, at: DateTime.now(), change: -0.15));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-piyasa')));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('Tümü filtresi altın ve dövizi birlikte gösterir', (
      tester,
    ) async {
      await openPiyasa(tester);
      expect(find.text('Gram Altın'), findsOneWidget);
      expect(find.text('Ons Altın'), findsOneWidget);
      expect(find.text('USD / TL'), findsOneWidget);
      expect(find.text('41,1800'), findsOneWidget);
      expect(find.text('4.148,00'), findsOneWidget);
    });

    testWidgets('Altın filtresi yalnızca altın satırlarını bırakır', (
      tester,
    ) async {
      await openPiyasa(tester);
      await tester.tap(find.text('Altın'));
      await tester.pumpAndSettle();

      expect(find.text('Gram Altın'), findsOneWidget);
      expect(find.text('Ons Altın'), findsOneWidget);
      expect(find.text('USD / TL'), findsNothing);
      expect(find.text('EUR / TL'), findsNothing);
    });

    testWidgets('Döviz filtresi yalnızca dövizi bırakır', (tester) async {
      await openPiyasa(tester);
      await tester.tap(find.text('Döviz'));
      await tester.pumpAndSettle();

      expect(find.text('USD / TL'), findsOneWidget);
      expect(find.text('Gram Altın'), findsNothing);
    });

    testWidgets('fiyat gelmemişse satırlar tire gösterir', (tester) async {
      await pumpApp(tester, signedIn: true);
      await tester.tap(find.byKey(const Key('nav-piyasa')));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
