import 'dart:async';

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

/// `load` çağrıları ancak elle tamamlanınca biter (yarış koşulu testleri için).
class SlowLoadRepository implements HoldingsRepository {
  final List<Completer<List<Holding>>> _loads = [];

  void finish(List<Holding> value) => finishAt(_loads.length - 1, value);
  void finishAt(int index, List<Holding> value) =>
      _loads[index].complete(value);

  @override
  Future<List<Holding>> load() {
    final c = Completer<List<Holding>>();
    _loads.add(c);
    return c.future;
  }

  @override
  Future<void> save(List<Holding> holdings) async {}
}
