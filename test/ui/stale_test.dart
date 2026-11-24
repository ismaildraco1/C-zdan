import 'package:cuzdan/core/theme.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/state/market_controller.dart';
import 'package:cuzdan/ui/widgets/live_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/test_feed.dart';

Future<MarketController> pumpBadge(
  WidgetTester tester, {
  required DateTime now,
  DateTime? lastUpdate,
}) async {
  final feed = TestFeed();
  final market = MarketController(feed);
  if (lastUpdate != null) {
    feed.push({AssetKind.usd: quote('USD', 41.18, at: lastUpdate)});
  }
  addTearDown(market.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<MarketController>.value(
      value: market,
      child: MaterialApp(
        theme: buildTheme(useGoogleFonts: false),
        home: Scaffold(body: LiveBadge(now: () => now)),
      ),
    ),
  );
  return market;
}

Color? colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  final t0 = DateTime(2026, 11, 16, 14, 32);

  testWidgets('bir dakika önceki fiyat bayattır: etiket ve soluk renk',
      (tester) async {
    await pumpBadge(
      tester,
      now: DateTime(2026, 11, 16, 14, 33),
      lastUpdate: t0,
    );
    expect(find.text('Son güncelleme 14:32'), findsOneWidget);
    expect(colorOf(tester, 'Son güncelleme 14:32'), AppColors.muted);
    expect(find.textContaining('Canlı'), findsNothing);
  });

  testWidgets('taze fiyatta Canlı etiketi yeşil kalır', (tester) async {
    await pumpBadge(
      tester,
      now: t0.add(const Duration(seconds: 10)),
      lastUpdate: t0,
    );
    expect(find.text('Canlı · 14:32'), findsOneWidget);
    expect(colorOf(tester, 'Canlı · 14:32'), isNot(AppColors.muted));
  });

  testWidgets('hiç fiyat gelmediyse bekleniyor yazar', (tester) async {
    await pumpBadge(tester, now: t0);
    expect(find.text('Fiyatlar bekleniyor'), findsOneWidget);
    expect(colorOf(tester, 'Fiyatlar bekleniyor'), AppColors.muted);
  });

  testWidgets('tam 30 saniyede hâlâ taze, 31 saniyede bayat', (tester) async {
    await pumpBadge(
      tester,
      now: t0.add(const Duration(seconds: 30)),
      lastUpdate: t0,
    );
    expect(find.textContaining('Canlı'), findsOneWidget);

    await pumpBadge(
      tester,
      now: t0.add(const Duration(seconds: 31)),
      lastUpdate: t0,
    );
    expect(find.textContaining('Son güncelleme'), findsOneWidget);
  });
}
