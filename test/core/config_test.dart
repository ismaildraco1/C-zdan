import 'package:cuzdan/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adres boşsa ayarlanmış sayılmaz', () {
    expect(const AppConfig(url: '', anonKey: 'x').isConfigured, isFalse);
  });
  test('anahtar boşsa ayarlanmış sayılmaz', () {
    expect(
      const AppConfig(url: 'https://a.supabase.co', anonKey: '').isConfigured,
      isFalse,
    );
  });
  test('https olmayan adres ayarlanmış sayılmaz', () {
    expect(
      const AppConfig(url: 'http://a.supabase.co', anonKey: 'x').isConfigured,
      isFalse,
    );
  });
  test('geçerli adres ve anahtar ayarlanmış sayılır', () {
    expect(
      const AppConfig(url: 'https://a.supabase.co', anonKey: 'x').isConfigured,
      isTrue,
    );
  });
  test('derleme ayarı verilmediğinde sahte mod seçilir', () {
    expect(AppConfig.fromEnvironment.isConfigured, isFalse);
  });

  group('fiyat kaynağı', () {
    test('varsayılan sahte kaynaktır', () {
      expect(const AppConfig(url: '', anonKey: '').useHarem, isFalse);
      expect(AppConfig.fromEnvironment.useHarem, isFalse);
    });
    test('PRICE_SOURCE=harem Harem Altın seçer', () {
      expect(
        const AppConfig(url: '', anonKey: '', priceSource: 'harem').useHarem,
        isTrue,
      );
    });
    test('büyük küçük harf ve boşluk önemsizdir', () {
      expect(
        const AppConfig(url: '', anonKey: '', priceSource: ' Harem ').useHarem,
        isTrue,
      );
    });
    test('tanınmayan değer sahteye döner', () {
      expect(
        const AppConfig(
          url: '',
          anonKey: '',
          priceSource: 'bilinmiyor',
        ).useHarem,
        isFalse,
      );
    });
  });
}
