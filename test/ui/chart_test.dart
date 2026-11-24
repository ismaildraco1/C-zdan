import 'package:cuzdan/ui/assets/chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Size;

void main() {
  const size = Size(100, 50);

  test('iki değerin altından az nokta üretmez', () {
    expect(chartPoints(const [], size, pad: 5), isEmpty);
    expect(chartPoints(const [1], size, pad: 5), isEmpty);
  });

  test('en küçük değer altta, en büyük üstte', () {
    final pts = chartPoints(const [10, 20, 15], size, pad: 5);
    expect(pts[0].dy, 45); // en küçük: alt kenar - pad
    expect(pts[1].dy, 5); // en büyük: üst kenar + pad
    expect(pts[2].dy, closeTo(25, 0.001)); // ortası
  });

  test('x noktaları kenar boşluğu içinde eşit aralıklı', () {
    final pts = chartPoints(const [1, 2, 3], size, pad: 5);
    expect(pts[0].dx, 5);
    expect(pts[1].dx, 50);
    expect(pts[2].dx, 95);
  });

  test('tüm değerler eşitse düz çizgi ortada çizilir', () {
    final pts = chartPoints(const [7, 7, 7], size, pad: 5);
    expect(pts.map((p) => p.dy).toSet(), {25.0});
  });
}
