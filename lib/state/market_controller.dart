import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/price_feed.dart';
import '../domain/asset_kind.dart';
import '../domain/models.dart';

/// Canlı fiyatları tutar ve ekranlara haber verir.
class MarketController extends ChangeNotifier {
  MarketController(this._feed) {
    _quotesSub = _feed.quotes.listen(_onQuotes);
    _onsSub = _feed.ons.listen((q) {
      _ons = q;
      _touch(q.updatedAt);
      notifyListeners();
    });
  }

  final PriceFeed _feed;
  StreamSubscription<Map<AssetKind, Quote>>? _quotesSub;
  StreamSubscription<Quote>? _onsSub;
  Map<AssetKind, Quote> _quotes = const {};
  Quote? _ons;
  DateTime? _lastUpdate;

  Map<AssetKind, Quote> get quotes => _quotes;
  Quote? get ons => _ons;
  DateTime? get lastUpdate => _lastUpdate;

  /// Son güncellemeden bu yana `after` geçtiyse (ya da hiç veri gelmediyse) true.
  bool isStale(DateTime now, {Duration after = const Duration(seconds: 30)}) {
    final last = _lastUpdate;
    if (last == null) return true;
    return now.difference(last) > after;
  }

  void _onQuotes(Map<AssetKind, Quote> m) {
    _quotes = Map.unmodifiable(m);
    for (final q in m.values) {
      _touch(q.updatedAt);
    }
    notifyListeners();
  }

  void _touch(DateTime at) {
    final last = _lastUpdate;
    if (last == null || at.isAfter(last)) _lastUpdate = at;
  }

  @override
  void dispose() {
    _quotesSub?.cancel();
    _onsSub?.cancel();
    _feed.dispose();
    super.dispose();
  }
}
