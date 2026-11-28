import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/ui/widgets/header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key, SwitchListTile;
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';
import '../support/test_feed.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// İki gram altın (10 ve 1 gr) ve bir dolar kaydı.
  Future<Harness> pumpDuplicates(WidgetTester tester) async {
    final h = await pumpApp(tester, signedIn: true);
    await h.portfolio.add(AssetKind.gramGold, 10, 'Düğün');
    await h.portfolio.add(AssetKind.usd, 100, '');
    await h.portfolio.add(AssetKind.gramGold, 1, '');
    h.feed.push({
      AssetKind.gramGold: quote('ALTIN', 4000, at: DateTime.now()),
      AssetKind.usd: quote('USDTRY', 40, at: DateTime.now()),
    });
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> toggleMerge(WidgetTester tester) async {
    await tapKey(tester, 'nav-ayarlar');
    await tapKey(tester, 'birlestir');
    await tapKey(tester, 'nav-portfoy');
  }

  testWidgets('ayar kapalıyken kayıtlar ayrı satırlardır', (tester) async {
    await pumpDuplicates(tester);
    expect(find.text('Gram Altın'), findsNWidgets(2));

    await tapKey(tester, 'nav-ayarlar');
    final tile = find.byKey(const Key('birlestir'));
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });

  testWidgets('ayar açılınca aynı tür tek satırda toplanır', (tester) async {
    final h = await pumpDuplicates(tester);
    await toggleMerge(tester);

    expect(find.text('Gram Altın'), findsOneWidget);
    expect(find.text('11 gr · 2 kayıt'), findsOneWidget);
    expect(find.text('₺ 44.000,00'), findsOneWidget);
    expect(find.text('100 USD'), findsOneWidget);
    expect(find.text('₺ 48.000,00'), findsOneWidget); // toplam değişmez
    expect(h.portfolio.holdings, hasLength(3)); // kayıtlar silinmez
  });

  testWidgets('ayar kapatılınca kayıtlar yeniden ayrılır', (tester) async {
    await pumpDuplicates(tester);
    await toggleMerge(tester);
    await toggleMerge(tester);

    expect(find.text('Gram Altın'), findsNWidgets(2));
    expect(find.text('10 gr'), findsOneWidget);
    expect(find.text('1 gr'), findsOneWidget);
  });

  testWidgets('birleşik satır toplamı ve kayıtları gösterir', (tester) async {
    await pumpDuplicates(tester);
    await toggleMerge(tester);
    await tapText(tester, 'Gram Altın');

    expect(find.text('Elindeki 11 gr'), findsOneWidget);
    expect(find.text('₺ 44.000,00'), findsOneWidget);
    expect(find.text('Kayıtlar'), findsOneWidget);
    expect(find.text('10 gr'), findsOneWidget);
    expect(find.text('Düğün'), findsOneWidget);
    expect(find.text('1 gr'), findsOneWidget);
    expect(find.text('Miktarı düzenle'), findsNothing);
  });

  testWidgets('kayda dokununca o kayıt düzenlenip silinebilir', (tester) async {
    final h = await pumpDuplicates(tester);
    await toggleMerge(tester);
    await tapText(tester, 'Gram Altın');
    await tapText(tester, '10 gr');

    expect(find.text('Elindeki 10 gr'), findsOneWidget);
    expect(find.text('Miktarı düzenle'), findsOneWidget);
    await tapText(tester, 'Varlığı sil');
    await tapText(tester, 'Sil');

    expect(find.text('Elindeki 1 gr'), findsOneWidget);
    expect(h.portfolio.holdings, hasLength(2));
  });

  testWidgets('türün son kaydı da silinince boş ekran kalmaz', (tester) async {
    final h = await pumpDuplicates(tester);
    await toggleMerge(tester);
    await tapText(tester, 'Gram Altın');
    for (final record
        in h.portfolio.holdings
            .where((x) => x.kind == AssetKind.gramGold)
            .toList()) {
      await h.portfolio.remove(record.id);
    }
    await tester.pumpAndSettle();

    expect(find.text('Bu türde varlığın kalmadı.'), findsOneWidget);
    expect(find.byType(ScreenHeader), findsOneWidget);
  });

  testWidgets('tek kayıtlı tür doğrudan kayıt detayını açar', (tester) async {
    await pumpDuplicates(tester);
    await toggleMerge(tester);
    await tapText(tester, 'Amerikan Doları');

    expect(find.text('Miktarı düzenle'), findsOneWidget);
    expect(find.text('Kayıtlar'), findsNothing);
  });

  testWidgets('bakiye gizliyken birleşik görünüm de tutar göstermez', (
    tester,
  ) async {
    await pumpDuplicates(tester);
    await toggleMerge(tester);
    await tapKey(tester, 'bakiye-gizle');

    expect(find.text('•••• gr · 2 kayıt'), findsOneWidget);
    await tapText(tester, 'Gram Altın');
    expect(find.text('Elindeki •••• gr'), findsOneWidget);
    expect(find.text('10 gr'), findsNothing);
    expect(find.textContaining(RegExp(r'₺ \d')), findsNothing);
  });
}
