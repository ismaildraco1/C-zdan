# Cüzdan

Altın ve döviz biriktirenler için iOS ve Android uygulaması. Kullanıcı elindeki
varlıkları ve miktarlarını girer, uygulama bunların toplam değerini canlı
fiyatlarla Türk Lirası olarak gösterir.

Net değer = Σ (miktar × **alış** fiyatı). Yani elindekini bozdursa alacağı tutar.
Alış maliyeti ve kâr/zarar takibi yoktur.

## Durum

Arayüz ve uygulama mantığı tamam. **Fiyat, hesap ve varlık verisi şimdilik
sahtedir**, hiçbir dış servise bağlanılmaz:

| Parça | Şimdiki uygulama | Davranışı |
|---|---|---|
| Fiyatlar | `FakePriceFeed` | Örnek fiyatlar etrafında iki saniyede bir dalgalanır. Ayarlar'da kaynak "Örnek fiyatlar" görünür. |
| Hesap ve giriş | `FakeAuthRepository` | Bellekte çalışır. Uygulama kapanınca hesaplar silinir. Google ve Apple düğmeleri sahte bir kullanıcı açar. |
| Varlıklar | `LocalHoldingsRepository` | Telefonda (`shared_preferences`) tutulur. Hesaba bağlı değildir. |

Gerçek bağlantılar ayrı bir iştir. Karar bekleyen konular için
`docs/superpowers/specs/2026-11-15-cuzdan-design.md` dosyasındaki "Açık sorular"
bölümüne bak.

## Çalıştırma

```bash
flutter pub get
flutter run          # bağlı telefonda ya da emülatörde
flutter test         # tüm testler
flutter analyze
```

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

Ekranlar yalnızca şu üç arayüzü bilir. Gerçek servis seçilince bunların yeni bir
uygulaması yazılır ve `lib/main.dart` içinde değiştirilir. Ekranlar değişmez.

- `PriceFeed` (`lib/data/price_feed.dart`): `quotes` ve `ons` akışları ve
  `sourceName`. Her `quotes` olayı yedi varlık türünün hepsini içermelidir.
- `AuthRepository` (`lib/data/auth_repository.dart`): giriş, kayıt, Google, Apple,
  şifre sıfırlama, çıkış, hesap silme, profil güncelleme.
- `HoldingsRepository` (`lib/data/holdings_repository.dart`): varlık listesini
  yükle ve kaydet. Hesap servisi seçilince sunucuya yazan bir uygulama gelir.

Fiyat kaynağı olarak düşünülen Harem Altın'ın resmi, herkese açık bir API'si
bulunamadı. Bir üçüncü taraf servis seçmeden önce lisansını, gecikmesini ve
doğruluğunu ayrıca kontrol etmek gerekir.

## Bilinen eksikler

- Karanlık tema yok. Ayarlar'daki "Görünüm" satırı pasiftir.
- Ayarlar'daki bildirim, uygulama kilidi ve bakiyeyi gizleme anahtarları ekranda
  durur ama kaydedilmez ve henüz bir işe bağlı değildir.
- "Şifreyi değiştir" ekranı yok. Profil'de e-posta ve fotoğraf değiştirilemez.
- Google ve Apple düğmeleri yer tutucudur. Resmi logo ve tasarım kuralları gerçek
  giriş bağlanırken uygulanmalıdır.
- Varlıklar hesaba değil cihaza bağlıdır. Aynı telefonda başka hesapla girilirse
  aynı varlıkları görür. Hesap silinirken cihazdaki varlıklar da silinir.
- Detay ekranında gün aralığı ve dönem seçici yok. Grafik ve "Oturum aralığı"
  uygulama açıkken gelen son 60 fiyattan çizilir.
- iOS derlemesi Linux'ta yapılamaz. İlk iOS derlemesini bir Mac'te al.
