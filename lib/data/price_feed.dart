import 'dart:async';
import 'dart:math';

import '../domain/asset_kind.dart';
import '../domain/models.dart';

abstract class PriceFeed {
  /// Ayarlar'da "Fiyat kaynağı" olarak gösterilen ad. Sahte akış kendini
  /// açıkça "Örnek fiyatlar" diye adlandırır.
  String get sourceName;

  /// Yedi portföy türünün güncel fiyatları. Her olay tüm türleri içerir.
  Stream<Map<AssetKind, Quote>> get quotes;

  /// Ons altın fiyatı (yalnızca Piyasa ekranında gösterilir).
  Stream<Quote> get ons;

  void dispose();
}

class _Base {
  const _Base(this.symbol, this.buy, this.spread, this.openChange);
  final String symbol;
  final double buy;
  final double spread;

  /// Günün açılışına göre başlangıç değişimi (yüzde).
  final double openChange;
}

const _bases = <AssetKind, _Base>{
  AssetKind.gramGold: _Base('GRAM', 4148, 4, 0.84),
  AssetKind.quarterGold: _Base('CEYREK', 6940, 20, 0.79),
  AssetKind.halfGold: _Base('YARIM', 13880, 40, 0.80),
  AssetKind.fullGold: _Base('TAM', 27760, 80, 0.78),
  AssetKind.usd: _Base('USD', 41.18, 0.04, 0.21),
  AssetKind.eur: _Base('EUR', 48.06, 0.08, -0.12),
  AssetKind.gbp: _Base('GBP', 55.24, 0.12, 0.33),
};
const _onsBase = _Base('ONS', 3120.40, 1, -0.15);

/// Gerçek bir kaynağa bağlanmadan, örnek fiyatlar etrafında dalgalanan sahte akış.
class FakePriceFeed implements PriceFeed {
  FakePriceFeed({this.tick = const Duration(seconds: 2), int? seed})
      : _random = Random(seed) {
    _quotes = StreamController.broadcast(onListen: () {
      _start();
      scheduleMicrotask(() {
        if (!_quotes.isClosed) _quotes.add(_snapshot());
      });
    });
    _ons = StreamController.broadcast(onListen: () {
      _start();
      scheduleMicrotask(() {
        if (!_ons.isClosed) _ons.add(_onsQuote());
      });
    });
  }

  final Duration tick;
  final Random _random;
  late final StreamController<Map<AssetKind, Quote>> _quotes;
  late final StreamController<Quote> _ons;
  Timer? _timer;
  final Map<AssetKind, double> _buy = {
    for (final e in _bases.entries) e.key: e.value.buy,
  };
  double _onsBuy = _onsBase.buy;

  @override
  String get sourceName => 'Örnek fiyatlar';

  @override
  Stream<Map<AssetKind, Quote>> get quotes => _quotes.stream;

  @override
  Stream<Quote> get ons => _ons.stream;

  void _start() {
    _timer ??= Timer.periodic(tick, (_) {
      for (final k in _buy.keys) {
        _buy[k] = _walk(_buy[k]!, _bases[k]!.buy);
      }
      _onsBuy = _walk(_onsBuy, _onsBase.buy);
      if (!_quotes.isClosed) _quotes.add(_snapshot());
      if (!_ons.isClosed) _ons.add(_onsQuote());
    });
  }

  double _walk(double current, double anchor) {
    final step = (_random.nextDouble() - 0.5) * 0.0008;
    final next = current * (1 + step);
    // Başlangıç değerinden %2'den fazla uzaklaşmasın.
    return next.clamp(anchor * 0.98, anchor * 1.02);
  }

  Quote _make(_Base b, double buy) {
    final open = b.buy / (1 + b.openChange / 100);
    return Quote(
      symbol: b.symbol,
      buy: buy,
      sell: buy + b.spread,
      changePercent: (buy / open - 1) * 100,
      updatedAt: DateTime.now(),
    );
  }

  Map<AssetKind, Quote> _snapshot() => {
        for (final e in _buy.entries) e.key: _make(_bases[e.key]!, e.value),
      };

  Quote _onsQuote() => _make(_onsBase, _onsBuy);

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _quotes.close();
    _ons.close();
  }
}
