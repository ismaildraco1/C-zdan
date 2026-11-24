# Supabase ile e-posta/şifre girişi ve hesaba bağlı varlıklar

Tarih: 2026-11-24
Durum: Başlandı (kullanıcı "önce e-posta/şifreyle başla" dedi)
Üst belge: `2026-11-15-cuzdan-design.md` (açık soru 1: hesap ve veri katmanı → **Supabase**, kullanıcının kararı)

## Amaç

Sahte hesap ve cihaz içi varlık deposunu Supabase ile değiştirmek: kullanıcı e-posta ve
şifreyle kayıt olur, giriş yapar; varlıkları hesabında saklanır ve her cihazdan görünür.

## Kapsam (bu tur)

- E-posta/şifre ile kayıt, giriş, çıkış, oturumun uygulama yeniden açılınca korunması.
- Şifre sıfırlama (e-postadaki bağlantı uygulamayı açar, "yeni şifre belirle" ekranı) ve
  giriş yapmış kullanıcının şifre değiştirmesi (önceki turdan kalan eksik ekran).
- E-posta doğrulaması açıksa "e-postanı doğrula" ekranı.
- Profil (ad, soyad, telefon) güncelleme. Hesap silme.
- Varlıklar Supabase tablosunda; her kullanıcı yalnızca kendininkini görür (RLS).
- Supabase ayarı verilmemişse uygulama sahte servislerle çalışmaya devam eder.

## Kapsam dışı

- Google ve Apple girişi (sonraki tur; dış hesap kurulumu ister). Düğmeler şimdilik
  sahte girişte kalır, Supabase modunda kapalı ve "Yakında" olarak gösterilir.
- Fiyat akışı: sahte kalır. Fiyat kaynağı kararı hâlâ açık.
- Çevrimdışı çalışma ve çakışma çözümü: yoksa hata gösterilir, değişiklik geri alınır.

## Kararlar (benim önerim, kullanıcı itiraz etmedi)

- **Hesap silme**: Edge Function yerine SQL fonksiyonu `delete_my_account()`
  (`security definer`, yalnızca giriş yapmış kullanıcı çağırır). `holdings` satırları
  `on delete cascade` ile gider. Daha az parça, aynı sonuç.
- **Profil alanları** (ad, soyad, telefon) ayrı tablo yerine kullanıcının `user_metadata`
  alanında tutulur. E-posta değiştirilemez (önceki turdaki karar sürer).
- **Varlık kimliği** istemcide UUID v4 üretilir (önceki `zaman-sayaç` kimliği iki kullanıcıda
  çakışabilirdi).
- **Ayarlar** (adres ve genel anahtar) koda gömülmez: `--dart-define=SUPABASE_URL=...`
  `--dart-define=SUPABASE_ANON_KEY=...`. Genel anahtar gizli değildir ama depoya girmez.
  **Hizmet anahtarı (service_role) uygulamaya hiçbir zaman konmaz.**
- **Derin bağlantı**: `io.cuzdan.app://login-callback/`. Şifre sıfırlama ve e-posta doğrulama
  e-postaları bu adrese döner.
- **Hata mesajları** Türkçe ve kullanıcıyı suçlamaz. Hesap var/yok bilgisi sızdırılmaz:
  yanlış şifre ve bilinmeyen e-posta aynı mesajı verir (Supabase da böyle davranır).

## Bu ortamda sınanabilenler

Bu ortamdan Supabase'e erişilemiyor. Supabase istemcisi, sahte bir HTTP istemcisiyle
(`http/testing.dart` `MockClient`) gerçek istek biçimleriyle sınanır: adres, gövde, başlık.
Gerçek sunucuya karşı deneme kullanıcının bilgisayarında yapılır (README'deki adımlar).

## Kullanıcıdan gerekenler (kod dışı)

1. supabase.com'da bir proje aç. Proje adresi ve genel (anon) anahtar.
2. `supabase/migrations/*.sql` dosyasını SQL editöründe çalıştır.
3. Authentication → URL Configuration: redirect adresi olarak `io.cuzdan.app://login-callback/`.
4. Authentication → E-posta doğrulamasını açık ya da kapalı bırak; uygulama ikisini de bilir.
