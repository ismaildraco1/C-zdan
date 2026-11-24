import 'asset_kind.dart';
import 'models.dart';

/// Bir kaydın TL değeri (miktar × alış). Fiyat yoksa `null`.
double? rowValue(Holding h, Map<AssetKind, Quote> quotes) {
  final quote = quotes[h.kind];
  if (quote == null) return null;
  return h.amount * quote.buy;
}

/// Fiyatı bilinen tüm kayıtların toplam TL değeri.
double netValue(List<Holding> holdings, Map<AssetKind, Quote> quotes) {
  var total = 0.0;
  for (final h in holdings) {
    total += rowValue(h, quotes) ?? 0;
  }
  return total;
}
