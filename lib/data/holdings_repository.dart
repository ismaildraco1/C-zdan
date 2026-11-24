import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/asset_kind.dart';
import '../domain/models.dart';

abstract class HoldingsRepository {
  Future<List<Holding>> load();
  Future<void> save(List<Holding> holdings);
}

/// Varlıkları telefonda (`shared_preferences`) JSON olarak tutar.
/// Gerçek hesap servisi seçilince bunun yerine sunucuya yazan bir uygulama gelir.
class LocalHoldingsRepository implements HoldingsRepository {
  static const _key = 'holdings';

  @override
  Future<List<Holding>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          Holding(
            id: item['id'] as String,
            kind: AssetKind.values.byName(item['kind'] as String),
            amount: (item['amount'] as num).toDouble(),
            note: (item['note'] as String?) ?? '',
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<Holding> holdings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([
        for (final h in holdings)
          {
            'id': h.id,
            'kind': h.kind.name,
            'amount': h.amount,
            'note': h.note,
          },
      ]),
    );
  }
}
