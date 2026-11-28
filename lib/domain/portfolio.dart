import 'asset_kind.dart';
import 'models.dart';

/// Bir kaydın TL değeri (miktar × alış). Fiyat yoksa `null`.
double? rowValue(Holding h, Map<AssetKind, Quote> quotes) {
  final quote = quotes[h.kind];
  if (quote == null) return null;
  return h.amount * quote.buy;
}

/// Kayıtları türüne göre toplar. Gruplar türün ilk görüldüğü sırada, kayıtlar
/// kendi sıralarında kalır.
List<List<Holding>> groupByKind(List<Holding> holdings) {
  final groups = <AssetKind, List<Holding>>{};
  for (final h in holdings) {
    (groups[h.kind] ??= []).add(h);
  }
  return groups.values.toList();
}

/// Aynı türden kayıtların toplam miktarı.
double totalAmount(List<Holding> records) =>
    records.fold(0, (sum, h) => sum + h.amount);

/// Aynı türden kayıtların toplam TL değeri. Fiyat yoksa `null`.
double? totalValue(List<Holding> records, Map<AssetKind, Quote> quotes) =>
    records.every((h) => quotes[h.kind] == null)
    ? null
    : netValue(records, quotes);

/// Bugünkü değişim: şu anki değerle günün açılış değeri arasındaki fark (TL)
/// ve yüzdesi. Fiyatı olmayan kayıtlar hesaba girmez.
({double amount, double percent}) dayChange(
  List<Holding> holdings,
  Map<AssetKind, Quote> quotes,
) {
  var now = 0.0;
  var open = 0.0;
  for (final h in holdings) {
    final q = quotes[h.kind];
    if (q == null) continue;
    final value = h.amount * q.buy;
    now += value;
    open += value / (1 + q.changePercent / 100);
  }
  if (open == 0) return (amount: 0, percent: 0);
  return (amount: now - open, percent: (now / open - 1) * 100);
}

/// Fiyatı bilinen tüm kayıtların toplam TL değeri.
double netValue(List<Holding> holdings, Map<AssetKind, Quote> quotes) {
  var total = 0.0;
  for (final h in holdings) {
    total += rowValue(h, quotes) ?? 0;
  }
  return total;
}
