import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/state/market_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_feed.dart';

void main() {
  final t0 = DateTime(2026, 11, 16, 14, 32);

  test('fiyat olayı gelince quotes ve lastUpdate güncellenir', () {
    final feed = TestFeed();
    final market = MarketController(feed);
    expect(market.quotes, isEmpty);
    expect(market.lastUpdate, isNull);

    feed.push({AssetKind.usd: quote('USD', 41.18, at: t0)});

    expect(market.quotes[AssetKind.usd]!.buy, 41.18);
    expect(market.lastUpdate, t0);
    market.dispose();
  });

  test('ons fiyatı ayrı tutulur', () {
    final feed = TestFeed();
    final market = MarketController(feed);
    feed.pushOns(quote('ONS', 3120.40, at: t0));
    expect(market.ons?.buy, 3120.40);
    market.dispose();
  });

  test('isStale 31 sn sonra true, 5 sn sonra false', () {
    final feed = TestFeed();
    final market = MarketController(feed);
    feed.push({AssetKind.usd: quote('USD', 41.18, at: t0)});

    expect(market.isStale(t0.add(const Duration(seconds: 5))), isFalse);
    expect(market.isStale(t0.add(const Duration(seconds: 31))), isTrue);
    market.dispose();
  });

  test('hiç veri gelmediyse bayat sayılır', () {
    final market = MarketController(TestFeed());
    expect(market.isStale(t0), isTrue);
    market.dispose();
  });

  group('history', () {
    test('alış fiyatlarını sırayla biriktirir', () {
      final feed = TestFeed();
      final market = MarketController(feed);
      expect(market.history(AssetKind.usd), isEmpty);

      for (final v in [41.0, 41.1, 41.2]) {
        feed.push({AssetKind.usd: quote('USD', v, at: t0)});
      }

      expect(market.history(AssetKind.usd), [41.0, 41.1, 41.2]);
      expect(market.history(AssetKind.eur), isEmpty);
      market.dispose();
    });

    test('en fazla 60 örnek tutar, en eskisini atar', () {
      final feed = TestFeed();
      final market = MarketController(feed);
      for (var i = 0; i < 65; i++) {
        feed.push({AssetKind.usd: quote('USD', 40.0 + i, at: t0)});
      }
      final h = market.history(AssetKind.usd);
      expect(h, hasLength(60));
      expect(h.first, 45.0);
      expect(h.last, 104.0);
      market.dispose();
    });
  });

  test('dinleyicilere haber verir', () {
    final feed = TestFeed();
    final market = MarketController(feed);
    var calls = 0;
    market.addListener(() => calls++);
    feed.push({AssetKind.usd: quote('USD', 41.18, at: t0)});
    expect(calls, 1);
    market.dispose();
  });
}
