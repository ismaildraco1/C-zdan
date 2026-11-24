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
| Fiyatlar | `FakePriceFeed` (örnek, iki saniyede bir dalgalanır) | aynı |
| Google / Apple girişi | kapalı ("yakında") | sahte kullanıcı açar |

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
```

Yalnızca genel (publishable ya da anon) anahtar kullanılır. `service_role` anahtarı
uygulamaya hiçbir zaman konmaz.

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
  `sourceName`. Her `quotes` olayı yedi varlık türünün hepsini içermelidir.
  **Henüz gerçeği yok**: fiyat kaynağı kararı açık.
- `AuthRepository` (`lib/data/auth_repository.dart`): Supabase uygulaması hazır
  (`lib/data/supabase/`). Google ve Apple için `supportsSocialLogin` ve
  `signInWithGoogle/Apple` doldurulacak.
- `HoldingsRepository` (`lib/data/holdings_repository.dart`): Supabase uygulaması hazır.

Fiyat kaynağı olarak düşünülen Harem Altın'ın resmi, herkese açık bir API'si
bulunamadı. Bir üçüncü taraf servis seçmeden önce lisansını, gecikmesini ve
doğruluğunu ayrıca kontrol etmek gerekir.

## Bilinen eksikler

- Google ve Apple girişi yok (Supabase modunda düğmeler pasif). Dış hesap kurulumu ister.
- Fiyatlar sahte.
- Çevrimdışı çalışma yok: bağlantı yoksa değişiklik kaydedilmez, hata gösterilir ve
  liste eski haline döner. Çıkış yapmak da bağlantı ister.
- İki cihazdan aynı anda düzenleme: en son kaydeden kazanır.
- Karanlık tema yok. Ayarlar'daki bildirim, uygulama kilidi ve bakiyeyi gizleme
  anahtarları ekranda durur ama kaydedilmez ve bir işe bağlı değildir.
- Profil'de e-posta ve fotoğraf değiştirilemez.
- Detay ekranında gün aralığı ve dönem seçici yok. Grafik, uygulama açıkken gelen
  son 60 fiyattan çizilir.
- Sahte modda hesap silinince cihazdaki varlıklar kalır (yalnızca geliştirme modu).
- iOS derlemesi Linux'ta yapılamaz. İlk iOS derlemesini bir Mac'te al.
