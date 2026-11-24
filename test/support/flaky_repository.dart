import 'package:cuzdan/data/holdings_repository.dart';
import 'package:cuzdan/domain/models.dart';

/// `failing` açıkken `load` ve `save` ağ hatası gibi fırlatır.
class FlakyHoldingsRepository implements HoldingsRepository {
  bool failing = false;
  int saves = 0;
  List<Holding> _data = [];

  @override
  Future<List<Holding>> load() async {
    if (failing) throw Exception('ağ yok');
    return List.of(_data);
  }

  @override
  Future<void> save(List<Holding> holdings) async {
    if (failing) throw Exception('ağ yok');
    saves++;
    _data = List.of(holdings);
  }
}
