import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat('#,##0.00', 'tr_TR');
final NumberFormat _rate = NumberFormat('0.0000', 'tr_TR');
final NumberFormat _pct = NumberFormat('0.00', 'tr_TR');

/// `415206` -> `₺ 415.206,00`
String formatTry(double v) => '₺ ${_money.format(v)}';

/// `41.18` -> `41,1800`
String formatRate(double v) => _rate.format(v);

/// `0.62` -> `%0,62` (işaretsiz; yön ayrıca gösterilir)
String formatPercent(double v) => '%${_pct.format(v.abs())}';

/// Kullanıcının yazdığı miktarı okur. Nokta binlik, virgül ondalık ayracıdır.
/// Geçersiz, sıfır, negatif veya sonsuz değerde `null` döner.
double? parseAmount(String input) {
  final cleaned = input.trim().replaceAll('.', '').replaceAll(',', '.');
  final v = double.tryParse(cleaned);
  if (v == null || !v.isFinite || v <= 0) return null;
  return v;
}
