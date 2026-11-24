import 'package:cuzdan/domain/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final v4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('newId UUID v4 biçiminde ve küçük harfle üretir', () {
    for (var i = 0; i < 50; i++) {
      expect(newId(), matches(v4));
    }
  });

  test('newId 1000 çağrıda tekrar etmez', () {
    expect({for (var i = 0; i < 1000; i++) newId()}, hasLength(1000));
  });
}
