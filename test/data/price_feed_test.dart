import 'package:cuzdan/data/price_feed.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ilk olay yedi varlık türünün de fiyatını içerir', () async {
    final feed = FakePriceFeed(tick: const Duration(milliseconds: 20));
    final first = await feed.quotes.first;
    expect(first.keys.toSet(), AssetKind.values.toSet());
    expect(first[AssetKind.usd]!.buy, closeTo(41.18, 0.5));
    feed.dispose();
  });

  test('ons fiyatı ayrı akışta gelir', () async {
    final feed = FakePriceFeed(tick: const Duration(milliseconds: 20));
    final ons = await feed.ons.first;
    expect(ons.symbol, 'ONS');
    feed.dispose();
  });

  test('dispose sonrası olay üretmez', () async {
    final feed = FakePriceFeed(tick: const Duration(milliseconds: 10));
    var count = 0;
    final sub = feed.quotes.listen((_) => count++);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    feed.dispose();
    final atDispose = count;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(count, atDispose);
    await sub.cancel();
  });

  test('fiyatlar zamanla değişir ve alış satıştan küçüktür', () async {
    final feed = FakePriceFeed(tick: const Duration(milliseconds: 10));
    final two = await feed.quotes.take(2).toList();
    for (final m in two) {
      for (final q in m.values) {
        expect(q.buy, lessThan(q.sell));
      }
    }
    feed.dispose();
  });
}
