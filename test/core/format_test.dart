import 'package:cuzdan/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatTry', () {
    test('binlik nokta ve iki ondalık basamak kullanır', () {
      expect(formatTry(415206), '₺ 415.206,00');
    });
    test('sıfırı biçimler', () {
      expect(formatTry(0), '₺ 0,00');
    });
    test('çok büyük tutarı biçimler', () {
      expect(formatTry(999999999), '₺ 999.999.999,00');
    });
  });

  test('formatRate dört ondalık basamak yazar', () {
    expect(formatRate(41.18), '41,1800');
  });

  group('formatAmount', () {
    test('tam sayıyı binlik noktayla yazar', () {
      expect(formatAmount(2500), '2.500');
    });
    test('küsuratı virgülle yazar', () {
      expect(formatAmount(40.5), '40,5');
    });
    test('çok büyük miktarı biçimler', () {
      expect(formatAmount(999999999), '999.999.999');
    });
  });

  test('formatMoney TL işareti olmadan iki ondalık yazar', () {
    expect(formatMoney(4148), '4.148,00');
  });

  test('formatPercent işaretsiz yüzde yazar', () {
    expect(formatPercent(0.62), '%0,62');
  });

  group('parseAmount', () {
    test('binlik noktalı sayıyı okur', () {
      expect(parseAmount('2.500'), 2500);
    });
    test('düz sayıyı okur', () {
      expect(parseAmount('2500'), 2500);
    });
    test('virgülü ondalık sayar', () {
      expect(parseAmount('2.500,5'), 2500.5);
    });
    test('boş girişi reddeder', () {
      expect(parseAmount(''), isNull);
    });
    test('sıfırı reddeder', () {
      expect(parseAmount('0'), isNull);
    });
    test('negatif sayıyı reddeder', () {
      expect(parseAmount('-3'), isNull);
    });
    test('harfleri reddeder', () {
      expect(parseAmount('abc'), isNull);
    });
  });
}
