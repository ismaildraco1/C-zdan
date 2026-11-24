import 'dart:io';

import 'package:cuzdan/data/supabase/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  String msg(Object e) => turkishAuthMessage(e);

  test('yanlış şifre ve bilinmeyen e-posta aynı mesajı verir', () {
    expect(
      msg(
        const sb.AuthApiException(
          'x',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      ),
      'E-posta ya da şifre hatalı.',
    );
  });

  test('var olan hesap', () {
    for (final code in ['user_already_exists', 'email_exists']) {
      expect(
        msg(sb.AuthApiException('x', statusCode: '422', code: code)),
        'Bu e-posta ile zaten bir hesap var.',
        reason: code,
      );
    }
  });

  test('doğrulanmamış e-posta', () {
    expect(
      msg(
        const sb.AuthApiException(
          'x',
          statusCode: '400',
          code: 'email_not_confirmed',
        ),
      ),
      'E-postanı doğrulaman gerekiyor. Gelen kutunu kontrol et.',
    );
  });

  test('zayıf şifre', () {
    expect(
      msg(
        const sb.AuthApiException(
          'x',
          statusCode: '422',
          code: 'weak_password',
        ),
      ),
      'Şifre çok zayıf. Daha uzun ya da daha karmaşık bir şifre dene.',
    );
  });

  test('istek sınırı', () {
    for (final code in [
      'over_request_rate_limit',
      'over_email_send_rate_limit',
    ]) {
      expect(
        msg(sb.AuthApiException('x', statusCode: '429', code: code)),
        'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.',
        reason: code,
      );
    }
    expect(
      msg(const sb.AuthApiException('x', statusCode: '429')),
      'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.',
    );
  });

  test('ağ hataları bağlantı mesajı verir', () {
    const network = 'Bağlantı kurulamadı. İnternetini kontrol et.';
    expect(msg(sb.AuthRetryableFetchException()), network);
    expect(msg(const SocketException('yok')), network);
    expect(msg(http.ClientException('yok')), network);
  });

  test('bilinmeyen hata ham metni göstermez', () {
    const generic = 'Bir şeyler ters gitti. Tekrar dene.';
    expect(msg(StateError('içerideki ayrıntı')), generic);
    expect(
      msg(const sb.AuthApiException('SQL hatası xyz', statusCode: '500')),
      generic,
    );
  });
}
