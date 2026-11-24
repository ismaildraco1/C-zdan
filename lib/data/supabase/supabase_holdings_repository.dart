import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../domain/asset_kind.dart';
import '../../domain/models.dart';
import '../holdings_repository.dart';

/// Varlıkları Supabase'deki `holdings` tablosunda tutar. Satır düzeyinde güvenlik
/// (RLS) sayesinde her kullanıcı yalnızca kendi satırlarını okur ve yazar;
/// `user_id` sunucuda `auth.uid()` ile doldurulur, istemci göndermez.
class SupabaseHoldingsRepository implements HoldingsRepository {
  SupabaseHoldingsRepository(this._client);

  final sb.SupabaseClient _client;

  static const _nilUuid = '00000000-0000-0000-0000-000000000000';

  @override
  Future<List<Holding>> load() async {
    final rows = await _client
        .from('holdings')
        .select('id,kind,amount,note')
        .order('created_at', ascending: true)
        .order('id', ascending: true);

    final result = <Holding>[];
    for (final row in rows) {
      final kind = AssetKind.values.asNameMap()[row['kind']];
      if (kind == null) continue; // bilinmeyen tür: çökme yerine atla
      final amount = row['amount'];
      result.add(
        Holding(
          id: row['id'] as String,
          kind: kind,
          amount: amount is num ? amount.toDouble() : double.parse('$amount'),
          note: (row['note'] as String?) ?? '',
        ),
      );
    }
    return result;
  }

  /// Verilen listeyi sunucuya yansıtır: hepsini yazar, listede olmayanları siler.
  /// Silme yalnızca kullanıcının kendi satırlarını etkiler (RLS).
  @override
  Future<void> save(List<Holding> holdings) async {
    if (holdings.isNotEmpty) {
      await _client.from('holdings').upsert([
        for (final h in holdings)
          {'id': h.id, 'kind': h.kind.name, 'amount': h.amount, 'note': h.note},
      ], onConflict: 'id');
    }
    final table = _client.from('holdings');
    if (holdings.isEmpty) {
      await table.delete().neq('id', _nilUuid);
    } else {
      await table.delete().not('id', 'in', [for (final h in holdings) h.id]);
    }
  }
}
