import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/ui/widgets/buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key;

import '../support/app_harness.dart';
import '../support/test_feed.dart';

void main() {
  Future<Harness> pumpWithPrices(WidgetTester tester) async {
    final h = await pumpApp(tester, signedIn: true);
    final now = DateTime.now();
    h.feed.push({
      AssetKind.gramGold: quote('ALTIN', 4148, at: now),
      AssetKind.gold22: quote('AYAR22', 3800, at: now),
      AssetKind.silver: quote('GUMUSTRY', 52.4, at: now),
      AssetKind.usd: quote('USDTRY', 41.18, at: now),
    });
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('gümüş eklenir, gram fiyatıyla değerlenir', (tester) async {
    final h = await pumpWithPrices(tester);
    await tapKey(tester, 'nav-ekle');
    await tapKey(tester, 'tur-silver');
    await tester.enterText(find.byKey(const Key('miktar')), '100');
    await tester.pumpAndSettle();

    expect(find.textContaining('1 gr = ₺ 52,40'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Portföye ekle'));
    await tester.pumpAndSettle();

    expect(h.portfolio.holdings.single.kind, AssetKind.silver);
    expect(find.text('Gümüş'), findsOneWidget);
    expect(find.text('Ag'), findsOneWidget);
    expect(find.text('₺ 5.240,00'), findsWidgets);
  });

  testWidgets('22 ayar eklenir ve toplamı etkiler', (tester) async {
    final h = await pumpWithPrices(tester);
    await tapKey(tester, 'nav-ekle');
    await tapKey(tester, 'tur-gold22');
    await tester.enterText(find.byKey(const Key('miktar')), '20');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Portföye ekle'));
    await tester.pumpAndSettle();

    expect(h.portfolio.holdings.single.kind, AssetKind.gold22);
    expect(find.text('22 Ayar Altın'), findsOneWidget);
    expect(find.text('₺ 76.000,00'), findsWidgets);
  });

  testWidgets('gümüş detayında fiyat iki ondalıkla yazılır', (tester) async {
    final h = await pumpWithPrices(tester);
    await h.portfolio.add(AssetKind.silver, 100, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gümüş'));
    await tester.pumpAndSettle();

    expect(find.text('52,40'), findsOneWidget);
    expect(find.text('52,4000'), findsNothing);
  });

  testWidgets('Piyasa’da Altın ve Gümüş filtreleri ayrıdır', (tester) async {
    await pumpWithPrices(tester);
    await tapKey(tester, 'nav-piyasa');
    expect(find.text('22 Ayar Altın'), findsOneWidget);

    await tapKey(tester, 'filtre-gold');
    expect(find.text('22 Ayar Altın'), findsOneWidget);
    expect(find.text('52,40'), findsNothing);

    await tapKey(tester, 'filtre-silver');
    expect(find.text('52,40'), findsOneWidget);
    expect(find.text('22 Ayar Altın'), findsNothing);
    expect(find.text('USD / TL'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
