# Cüzdan

Altın ve döviz biriktirenler için iOS ve Android uygulaması. Kullanıcı elindeki
varlıkları ve miktarlarını girer, uygulama bunların toplam değerini canlı
fiyatlarla Türk Lirası olarak gösterir.

Net değer = Σ (miktar × **alış** fiyatı). Yani elindekini bozdursa alacağı tutar.
Alış maliyeti ve kâr/zarar takibi yoktur.

## Durum

Arayüz ve uygulama mantığı tamam. Hesap ve varlıklar **Supabase** ile çalışır
(e-posta/şifre); Supabase ayarı verilmezse sahte servislerle açılır. Fiyatlar
**her iki durumda da sahtedir**.

| Parça | Ayar verilmişse | Ayar yoksa |
|---|---|---|
| Hesap ve giriş | `SupabaseAuthRepository` (e-posta/şifre) | `FakeAuthRepository` (bellekte, kapanınca silinir) |
| Varlıklar | `SupabaseHoldingsRepository` (hesaba bağlı, RLS) | `LocalHoldingsRepository` (telefonda) |
| Fiyatlar | `PRICE_SOURCE=harem` ise `HaremPriceFeed` (canlı), değilse `FakePriceFeed` (örnek, iki saniyede bir dalgalanır) | aynı |

Kurulum adımları ve elle doğrulama listesi: [`supabase/README.md`](supabase/README.md).
Karar bekleyen konular: `docs/superpowers/specs/2026-11-15-cuzdan-design.md`.

**Gerçek sunucuya karşı hiçbir adım denenmedi.** Supabase kodu sahte bir HTTP
istemcisiyle sınandı; gerçek davranış `supabase/README.md`'deki listeyle
doğrulanmalı.

## Çalıştırma

```bash
flutter pub get
flutter test         # tüm testler
flutter analyze

# Sahte servislerle:
flutter run

# Supabase ile:
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_...

# Canlı Harem Altın fiyatlarıyla (Supabase'li ya da Supabasesiz kullanılabilir):
flutter run --dart-define=PRICE_SOURCE=harem
```

Yalnızca genel (publishable ya da anon) anahtar kullanılır. `service_role` anahtarı
uygulamaya hiçbir zaman konmaz.

## Canlı Harem Altın fiyatları

`PRICE_SOURCE=harem` ile uygulama, Harem Altın sayfasının kullandığı Socket.IO
akışına doğrudan bağlanır (`wss://hrmsocketonly.haremaltin.com`, yalnızca `websocket`
taşıması, kimlik doğrulama yok, `price_changed` olayı). Kod: `lib/data/harem/`.

**Gerçek veriyle doğrulandı (2026-11-28).** Canlı akıştan uygulamanın kullandığı on ürünün hepsi geldi;
ilk olay 58 ürünün tamamını içeren tam bir anlık görüntü, sonrakiler yalnızca değişenleri
taşıyor. Sayılar bazen metin (`"50.6420"`), bazen sayı (`9884`) geliyor ve noktalı ondalıkla
yazılıyor; ayrıştırıcı ikisini de okur, gerçek satırlar `harem_parser_test.dart` içinde
test olarak duruyor. Kendi cihazında denemek için:

```bash
dart run tool/harem_check.dart --ham
```

Çıktı "TAMAM: tüm türler geldi." demeli. Bir sorun görürsen çıktıyı olduğu gibi paylaş.
Aynı araç `--url=ws://localhost:PORT` ile yerel bir sunucuya da bağlanabilir.

Piyasa kapalıyken (gece, hafta sonu) yeni olay gelmez; rozet "Son güncelleme" gösterir.
Bu bir hata değil, son bilinen fiyatın zamanıdır.

Ürün eşleşmesi (`lib/data/harem/harem_parser.dart`): Gram altın = `ALTIN` (**has altın**,
22 ayar değil), 22 ayar altın = `AYAR22`, gümüş = `GUMUSTRY` (ikisi de gram),
Çeyrek/Yarım/Tam = `CEYREK_YENI`/`YARIM_YENI`/`TEK_YENI`, USD/EUR/GBP =
`USDTRY`/`EURTRY`/`GBPTRY`, Ons = `ONS`. Değişim yüzdesi sitedeki gibi satış fiyatının
kapanışa göre farkıdır. Fiyatın "güncellik" zamanı, cihaza ulaştığı andır.

**İzin.** Bu akış herkese açık, belgelenmiş bir API değil; sitenin kendi sayfası için var.
Harem Altın'ın kullanım izni ya da resmi bir veri anlaşması bulunmuyor. Kişisel denemede
sorun beklenmez, ama bu fiyatları mağazadaki bir uygulamada kullanıcılara dağıtmadan
önce Harem Altın'dan izin al (iletişim: haremaltin.com → Şubeler ve İletişim, 444 4 995).
Akış haber verilmeden değişebilir ya da engellenebilir; kopunca uygulama son fiyatı tutar
ve rozet "Son güncelleme" olur.

## Kod yapısı

```
lib/core/      biçimlendirme (₺ 415.206,00), tema
lib/domain/    saf Dart: modeller, net değer ve günlük değişim hesabı
lib/data/      arayüzler ve sahte uygulamalar (fiyat, hesap, varlık deposu)
lib/state/     ChangeNotifier denetleyicileri (provider ile verilir)
lib/ui/        ekranlar (auth, home, assets, account) ve ortak parçalar
test/          her katman için testler; test/support altında test yardımcıları
```

## Gerçek servisleri bağlama

Ekranlar yalnızca şu üç arayüzü bilir. `lib/bootstrap.dart` hangi uygulamanın
kullanılacağını seçer.

- `PriceFeed` (`lib/data/price_feed.dart`): `quotes` ve `ons` akışları ve
  `sourceName`. Her `quotes` olayı o ana kadar bilinen tüm türleri içermelidir.
  Gerçeği `HaremPriceFeed` (yukarıya bak), sahtesi `FakePriceFeed`.
- `AuthRepository` (`lib/data/auth_repository.dart`): Supabase uygulaması hazır
  (`lib/data/supabase/`). Giriş yalnızca e-posta/şifre; Google ve Apple girişi
  yapılmamaya karar verildi (kullanıcının kararı, 2026-11-27).
- `HoldingsRepository` (`lib/data/holdings_repository.dart`): Supabase uygulaması hazır.

Fiyat kaynağı olarak düşünülen Harem Altın'ın resmi, herkese açık bir API'si
bulunamadı. Bir üçüncü taraf servis seçmeden önce lisansını, gecikmesini ve
doğruluğunu ayrıca kontrol etmek gerekir.

## Bilinen eksikler

- Google ve Apple girişi yok, ekranlarda da düğme yok. Sonradan eklenirse App Store kuralı gereği ikisi birlikte olmalı.
- Harem Altın akışının kullanım izni yok (bkz. yukarısı). `PRICE_SOURCE=harem` verilmezse
  fiyatlar örnektir.
- Çevrimdışı çalışma yok: bağlantı yoksa değişiklik kaydedilmez, hata gösterilir ve
  liste eski haline döner. Çıkış yapmak da bağlantı ister.
- İki cihazdan aynı anda düzenleme: en son kaydeden kazanır.
- Karanlık tema yok. Ayarlar'daki bildirim ve uygulama kilidi anahtarları ekranda
  durur ama kaydedilmez ve bir işe bağlı değildir. (Bakiyeyi gizle çalışır ve cihazda
  saklanır; Portföy'deki göz düğmesiyle aynı ayardır. "Aynı türleri birleştir" de
çalışır, varsayılan kapalıdır ve yalnızca görünümü değiştirir; kayıtlar ayrı saklanır.)
- Profil'de e-posta ve fotoğraf değiştirilemez.
- Detay ekranında gün aralığı ve dönem seçici yok. Grafik, uygulama açıkken gelen
  son 60 fiyattan çizilir.
- Sahte modda hesap silinince cihazdaki varlıklar kalır (yalnızca geliştirme modu).
- iOS derlemesi Linux'ta yapılamaz. İlk iOS derlemesini bir Mac'te al.
