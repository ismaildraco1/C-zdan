import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Değerleri `size` içine, kenarlardan `pad` boşlukla yerleştirir. En küçük
/// değer altta, en büyük üstte olur; tüm değerler eşitse çizgi ortadadır.
/// İki değerden azı çizilemez, boş liste döner.
List<Offset> chartPoints(List<double> values, Size size, {double pad = 8}) {
  if (values.length < 2) return const [];
  final lo = values.reduce((a, b) => a < b ? a : b);
  final hi = values.reduce((a, b) => a > b ? a : b);
  final range = hi - lo;
  final w = size.width - 2 * pad;
  final h = size.height - 2 * pad;
  return [
    for (var i = 0; i < values.length; i++)
      Offset(
        pad + i / (values.length - 1) * w,
        range == 0 ? size.height / 2 : pad + (1 - (values[i] - lo) / range) * h,
      ),
  ];
}

/// Fiyat geçmişi çizgi grafiği: ince ızgara, alanlı çizgi, altın renkli uç nokta.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        key: const Key('grafik'),
        painter: _ChartPainter(values),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = chartPoints(values, size);
    if (pts.length < 2) return;

    final grid = Paint()
      ..color = const Color(0xFFE8ECE9)
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        grid,
      );
    }

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.green.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(pts.last, 6, Paint()..color = Colors.white);
    canvas.drawCircle(pts.last, 4.5, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.values != values;
}
