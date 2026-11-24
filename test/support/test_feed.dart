import 'dart:async';

import 'package:cuzdan/data/price_feed.dart';
import 'package:cuzdan/domain/asset_kind.dart';
import 'package:cuzdan/domain/models.dart';

/// Testlerde olayları elle göndermek için kullanılan akış.
class TestFeed implements PriceFeed {
  final _quotes = StreamController<Map<AssetKind, Quote>>.broadcast(sync: true);
  final _ons = StreamController<Quote>.broadcast(sync: true);

  @override
  String get sourceName => 'Test fiyatları';

  @override
  Stream<Map<AssetKind, Quote>> get quotes => _quotes.stream;

  @override
  Stream<Quote> get ons => _ons.stream;

  void push(Map<AssetKind, Quote> m) => _quotes.add(m);
  void pushOns(Quote q) => _ons.add(q);

  @override
  void dispose() {
    _quotes.close();
    _ons.close();
  }
}

Quote quote(String symbol, double buy,
        {DateTime? at, double change = 0.1}) =>
    Quote(
      symbol: symbol,
      buy: buy,
      sell: buy + 1,
      changePercent: change,
      updatedAt: at ?? DateTime(2026, 11, 16, 14, 32),
    );
