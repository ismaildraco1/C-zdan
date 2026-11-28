import 'package:cuzdan/domain/asset_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Key, SwitchListTile;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_test.dart' show pumpWithSamplePortfolio;

const eye = Key('bakiye-gizle');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> tapEye(WidgetTester tester) async {
    await tester.tap(find.byKey(eye));
    await tester.pumpAndSettle();
  }

  testWidgets('göz düğmesi toplamı, satır tutarlarını ve miktarları gizler', (
    tester,
  ) async {
    await pumpWithSamplePortfolio(tester);
    await tapEye(tester);

    expect(find.text('₺ 415.206,00'), findsNothing);
    expect(find.text('₺ 102.950,00'), findsNothing);
    expect(find.text('2.500 USD'), findsNothing);
    expect(find.text('40 gr'), findsNothing);
    expect(find.textContaining('₺ '), findsNWidgets(7));
    expect(find.textContaining(RegExp(r'₺ \d')), findsNothing);
    expect(find.text('•••• USD'), findsOneWidget);
    // Yüzde değişim ve varlık adları görünmeye devam eder.
    expect(find.text('▲ %0,21'), findsOneWidget);
    expect(find.text('Amerikan Doları'), findsOneWidget);
  });

  testWidgets('ikinci dokunuş tutarları geri getirir', (tester) async {
    await pumpWithSamplePortfolio(tester);
    await tapEye(tester);
    await tapEye(tester);

    expect(find.text('₺ 415.206,00'), findsOneWidget);
    expect(find.text('2.500 USD'), findsOneWidget);
  });

  testWidgets('Ayarlar anahtarı ile göz düğmesi aynı ayarı kullanır', (
    tester,
  ) async {
    await pumpWithSamplePortfolio(tester);
    await tapEye(tester);

    await tester.tap(find.byKey(const Key('nav-ayarlar')));
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('gizle'));
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-portfoy')));
    await tester.pumpAndSettle();
    expect(find.text('₺ 415.206,00'), findsOneWidget);
  });

  testWidgets('gizliyken Detay ekranı da tutarı ve miktarı göstermez', (
    tester,
  ) async {
    final h = await pumpWithSamplePortfolio(tester);
    expect(h.portfolio.holdings.any((x) => x.kind == AssetKind.usd), isTrue);
    await tapEye(tester);

    await tester.tap(find.text('Amerikan Doları'));
    await tester.pumpAndSettle();

    expect(find.text('Elindeki •••• USD'), findsOneWidget);
    expect(find.textContaining('2.500'), findsNothing);
    expect(find.textContaining('102.950'), findsNothing);
    expect(find.textContaining(RegExp(r'₺ \d')), findsNothing);
  });
}
