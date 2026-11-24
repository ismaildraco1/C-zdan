import 'dart:math';

final Random _secure = Random.secure();

/// UUID v4 (küçük harf, 36 karakter). Varlık kimlikleri istemcide üretilir;
/// iki kullanıcıda aynı kimliğin çıkması pratikte imkânsızdır.
String newId() {
  final b = List<int>.generate(16, (_) => _secure.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // sürüm 4
  b[8] = (b[8] & 0x3f) | 0x80; // varyant
  String h(int from, int to) =>
      [for (var i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0')]
          .join();
  return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
}
