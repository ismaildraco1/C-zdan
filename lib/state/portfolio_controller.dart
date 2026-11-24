import 'package:flutter/foundation.dart';

import '../data/holdings_repository.dart';
import '../domain/asset_kind.dart';
import '../domain/models.dart';
import '../domain/portfolio.dart';
import 'market_controller.dart';

/// Kullanıcının varlıklarını ve toplam net değerini tutar.
class PortfolioController extends ChangeNotifier {
  PortfolioController(this._repo, this._market) {
    _market.addListener(notifyListeners);
  }

  final HoldingsRepository _repo;
  final MarketController _market;
  List<Holding> _holdings = const [];
  int _counter = 0;

  List<Holding> get holdings => _holdings;
  double get total => netValue(_holdings, _market.quotes);

  double? valueOf(Holding h) => rowValue(h, _market.quotes);

  Future<void> load() async {
    _holdings = List.unmodifiable(await _repo.load());
    notifyListeners();
  }

  Future<void> add(AssetKind kind, double amount, String note) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
    await _commit([
      ..._holdings,
      Holding(id: id, kind: kind, amount: amount, note: note),
    ]);
  }

  Future<void> update(String id, double amount, String note) => _commit([
        for (final h in _holdings)
          h.id == id ? h.copyWith(amount: amount, note: note) : h,
      ]);

  Future<void> remove(String id) =>
      _commit([for (final h in _holdings) if (h.id != id) h]);

  Future<void> _commit(List<Holding> next) async {
    _holdings = List.unmodifiable(next);
    notifyListeners();
    await _repo.save(next);
  }

  @override
  void dispose() {
    _market.removeListener(notifyListeners);
    super.dispose();
  }
}
