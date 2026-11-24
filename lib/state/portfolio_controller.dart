import 'package:flutter/foundation.dart';

import '../data/holdings_repository.dart';
import '../domain/asset_kind.dart';
import '../domain/ids.dart';
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
  String? _error;
  bool _loadFailed = false;

  /// Her `load`/`reset` sayacı artırır; geç gelen eski sonuç yok sayılır
  /// (çıkış yapıp başka hesapla girince öncekinin varlıkları görünmesin).
  int _generation = 0;

  List<Holding> get holdings => _holdings;

  /// Son işlem başarısız olduysa kullanıcıya gösterilecek mesaj.
  String? get error => _error;

  /// Varlıklar yüklenemedi (liste bilinmiyor): Portföy "Tekrar dene" sunar.
  bool get loadFailed => _loadFailed;
  double get total => netValue(_holdings, _market.quotes);

  double? valueOf(Holding h) => rowValue(h, _market.quotes);

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final loaded = await _repo.load();
      if (generation != _generation) return;
      _holdings = List.unmodifiable(loaded);
      _error = null;
      _loadFailed = false;
    } catch (_) {
      if (generation != _generation) return;
      _loadFailed = true;
      _error = 'Varlıkların yüklenemedi. Bağlantını kontrol edip tekrar dene.';
    }
    notifyListeners();
  }

  /// Oturum kapanınca listeyi ve hatayı temizler. Depoya yazmaz.
  void reset() {
    _generation++;
    _holdings = const [];
    _error = null;
    _loadFailed = false;
    notifyListeners();
  }

  /// Değişiklikler başarılıysa `true` döner. Depo hata verirse liste eski haline
  /// döner, [error] dolar ve `false` döner.
  Future<bool> add(AssetKind kind, double amount, String note) async {
    final id = newId();
    return _commit([
      ..._holdings,
      Holding(id: id, kind: kind, amount: amount, note: note),
    ]);
  }

  Future<bool> update(String id, double amount, String note) => _commit([
    for (final h in _holdings)
      h.id == id ? h.copyWith(amount: amount, note: note) : h,
  ]);

  Future<bool> remove(String id) => _commit([
    for (final h in _holdings)
      if (h.id != id) h,
  ]);

  Future<bool> _commit(List<Holding> next) async {
    final previous = _holdings;
    _holdings = List.unmodifiable(next);
    _error = null;
    notifyListeners();
    try {
      await _repo.save(next);
      return true;
    } catch (_) {
      _holdings = previous;
      _error = 'Değişiklik kaydedilemedi. Bağlantını kontrol edip tekrar dene.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _market.removeListener(notifyListeners);
    super.dispose();
  }
}
