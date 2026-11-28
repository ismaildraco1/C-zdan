# Supabase kurulumu

Cüzdan, hesaplar için Supabase Auth'u (e-posta/şifre), varlıklar için Postgres'i
kullanır. Bu klasör veritabanı şemasını içerir. Aşağıdaki adımlar senin
bilgisayarında ve Supabase panelinde yapılır; kodu yazan ortamdan Supabase'e
erişilemediği için burada **hiçbiri gerçek sunucuya karşı denenmedi**.

## 1. Proje aç

[supabase.com](https://supabase.com) üzerinde yeni bir proje aç. Project Settings →
API sayfasından iki değeri al:

- **Project URL** (`https://xxxx.supabase.co`)
- **Publishable key** (`sb_publishable_...`) ya da eski adıyla **anon key**

**`service_role` / secret anahtarı uygulamaya, depoya ya da sohbete koyma.**
Uygulamanın ona ihtiyacı yok.

## 2. Şemayı kur

SQL Editor'de `migrations/` altındaki dosyaların tamamını **ad sırasıyla** çalıştır:
önce `20261124000000_init.sql`, sonra `20261128000000_add_gold22_silver.sql`
(22 ayar altın ve gümüş türlerine izin verir; bu ikincisi henüz hiçbir Postgres'te
sınanmadı). İlk dosya şunları oluşturur:

- `public.holdings` tablosu (kullanıcının varlıkları) ve satır düzeyinde güvenlik:
  herkes yalnızca kendi satırlarını görür, ekler, değiştirir ve siler.
- `public.delete_my_account()` fonksiyonu: giriş yapmış kullanıcı kendi hesabını
  siler; varlıkları `on delete cascade` ile birlikte gider.

Bu SQL, Supabase'i taklit eden bir iskelet üzerinde yerel Postgres 16'da sınandı
(`tests/run_local.sh`): bir kullanıcı ötekinin satırını göremez, değiştiremez, silemez,
başkası adına ekleyemez ve kimliğini kullanarak upsert ile ele geçiremez; miktar 0 ve
bilinmeyen tür reddedilir; `anon` rolü hesabı silemez; hesap silme yalnızca çağıranı
ve satırlarını siler. İskelet gerçek Supabase değildir, bu yüzden aşağıdaki elle doğrulama
listesi yine de gereklidir. Kendi bilgisayarında tekrarlamak için (yerel Postgres gerekir):

    ./supabase/tests/run_local.sh

## 3. Yönlendirme adresini ekle

Authentication → URL Configuration → **Redirect URLs** listesine ekle:

    io.cuzdan.app://login-callback/

Şifre sıfırlama ve e-posta doğrulama bağlantıları bu adresle uygulamayı açar.
(Android ve iOS tarafındaki ayar projede hazır.)

## 4. E-posta doğrulaması

Authentication → Providers → Email → **Confirm email**: açık ya da kapalı
bırakabilirsin, uygulama ikisini de bilir.

- Açıksa kayıttan sonra "E-postanı doğrula" ekranı çıkar.
- Kapalıysa kayıt doğrudan giriş yapar.

Supabase'in varsayılan e-posta servisi saatte çok az e-posta gönderebilir.
Gerçek kullanıcılar için Authentication → SMTP Settings'ten kendi SMTP servisini bağla.

## 5. Uygulamayı çalıştır

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

İki değerden biri eksikse uygulama sahte hesap ve cihaz içi varlıklarla açılır.
Canlı fiyatlar için ayrıca `--dart-define=PRICE_SOURCE=harem` ekle (bkz. ana README).

## 6. Elle doğrulama listesi

Kod, sahte bir HTTP istemcisiyle sınandı: istekler doğru biçimde gidiyor, yanıtlar
doğru işleniyor. Gerçek sunucunun davranışını şu adımlarla sen doğrula:

1. **Kayıt** (doğrulama açıkken): e-posta gelir, bağlantı uygulamayı açar,
   sonra giriş yapılır.
2. **Varlık ekle**: Table Editor → `holdings` tablosunda satır görünür,
   `user_id` dolu gelir.
3. **Gizlilik**: ikinci bir hesapla giriş yap; birinci hesabın varlıkları görünmez.
4. **Cihazlar arası**: aynı hesapla başka cihazda giriş yap; varlıklar gelir.
5. **Şifremi unuttum**: e-postadaki bağlantı "Yeni şifre belirle" ekranını açar,
   yeni şifreyle giriş yapılır.
6. **Şifreyi değiştir**: Profil → Şifreyi değiştir.
7. **Hesabı sil**: Authentication → Users ve `holdings` tablosundan kayıtlar gider.
8. **Uçak modu**: varlık eklemeyi dene; hata görünür, liste eski haline döner.

Bir adım beklediğin gibi çalışmazsa hata mesajını ve hangi adımda olduğunu söyle.
