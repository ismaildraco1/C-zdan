import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

const _network = 'Bağlantı kurulamadı. İnternetini kontrol et.';
const _rateLimit = 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.';
const _generic = 'Bir şeyler ters gitti. Tekrar dene.';

/// Supabase ve ağ hatalarını kullanıcıya gösterilecek Türkçe mesaja çevirir.
/// Ham sunucu metni ve iç ayrıntı asla gösterilmez. Yanlış şifre ile bilinmeyen
/// e-posta aynı mesajı verir, böylece hangi e-postaların kayıtlı olduğu sızmaz.
String turkishAuthMessage(Object error) {
  if (error is sb.AuthRetryableFetchException) return _network;
  if (error is SocketException || error is http.ClientException) return _network;
  if (error is sb.AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-posta ya da şifre hatalı.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Bu e-posta ile zaten bir hesap var.';
      case 'email_not_confirmed':
        return 'E-postanı doğrulaman gerekiyor. Gelen kutunu kontrol et.';
      case 'weak_password':
        return 'Şifre çok zayıf. Daha uzun ya da daha karmaşık bir şifre dene.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return _rateLimit;
    }
    if (error.statusCode == '429') return _rateLimit;
  }
  return _generic;
}
