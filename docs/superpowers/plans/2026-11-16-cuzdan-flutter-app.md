# Cüzdan Flutter Uygulaması Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tasarımdaki 11 ekranı çalışan bir Flutter uygulaması olarak kurmak. Fiyat, giriş ve varlık verisi arayüzün arkasında sahte (yerel) uygulamalarla çalışır. Gerçek bağlantılar sonraki planda takılır.

**Architecture:** Üç katman. `domain/` saf Dart (modeller ve net değer hesabı), `data/` arayüzler ve sahte uygulamalar (fiyat akışı, giriş, varlık deposu), `ui/` ekranlar. Durum `ChangeNotifier` denetleyicileriyle tutulur ve `provider` ile verilir. Gerçek servis (hesap, fiyat) seçilince yalnızca `data/` altında yeni bir uygulama yazılır, ekranlar değişmez.

**Tech Stack:** Flutter (kararlı sürüm), Dart, `provider`, `shared_preferences`, `intl`, `google_fonts`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-15-cuzdan-design.md`. Ekran tasarımı: https://claude.ai/artifact/YHBj1PB7cWPrqVB3fWMTkF (özel bağlantı).

## Global Constraints

- Paket adı `cuzdan`, hedef platformlar yalnızca Android ve iOS. Proje deponun kökünde kurulur.
- Net değer = Σ (miktar × **alış** fiyatı). Alış fiyatı yoksa o varlık toplama girmez, satırda "—" görünür.
- Ana para birimi yalnızca TL. Kâr/zarar ve alış maliyeti takibi yok.
- Portföye eklenebilen varlıklar: `gramGold`, `quarterGold`, `halfGold`, `fullGold`, `usd`, `eur`, `gbp`. Ons yalnızca Piyasa'da görünür.
- Metinler Türkçe. Para: `₺ 415.206,00` (binlik nokta, ondalık virgül, iki hane). Kur: dört ondalık (`41,1800`). Yüzde: `%0,62`.
- Renkler: zemin `#F2F4F1`, koyu yeşil `#0E3B31`, altın `#C8A24A`, yazı `#10211C`, soluk yazı `#5E6B66`, artış `#1F7A4D`, düşüş `#A8322A`. Yazı tipi Inter. Tek açık tema.
- Dokunma hedefleri en az 44 px. Her form alanında görünür etiket.
- Harem Altın'a veya herhangi bir dış servise bu planda bağlanılmaz. Ağ çağrısı yok (yalnızca Google Fonts).

## Review Focus

- Hiç varlık yokken Portföy: toplam `₺ 0,00` ve "İlk varlığını ekle" boş durumu. Çökme yok.
- Fiyat henüz gelmemişken varlık satırı `—` gösterir. Toplam `0` gibi yanlış bir sayıya dönmez.
- Miktar girişi: `2.500`, `2500`, `2.500,5`, boş, `0`, negatif, harf. Geçersizse ekleme düğmesi pasif ve neden yazılı.
- Fiyat akışı kesilirse son değer korunur ve "Son güncelleme 14:32" etiketi soluk renkle görünür.
- Aynı türden ikinci varlık eklenince ayrı satır olur, toplam ikisini de sayar.
- Hesabı sil onayı: e-posta büyük/küçük harf ve baştaki/sondaki boşluğa duyarsız eşleşir. Eşleşmeden düğme pasif.
- Çok büyük miktar (`999999999`) taşma yapmadan biçimlenir ve satıra sığar.

---

## File Structure

```
lib/main.dart                         uygulama girişi, provider kurulumu
lib/app.dart                          MaterialApp, rotalar, giriş durumuna göre ilk ekran
lib/core/format.dart                  formatTry, formatRate, formatPercent, parseAmount
lib/core/theme.dart                   AppColors, buildTheme()
lib/domain/asset_kind.dart            AssetKind enum ve görünen adlar
lib/domain/models.dart                Quote, Holding, UserProfile
lib/domain/portfolio.dart             netValue, rowValue
lib/data/price_feed.dart              PriceFeed arayüzü + FakePriceFeed
lib/data/auth_repository.dart         AuthRepository arayüzü + FakeAuthRepository
lib/data/holdings_repository.dart     HoldingsRepository arayüzü + LocalHoldingsRepository
lib/state/market_controller.dart      canlı fiyatlar, son güncelleme zamanı
lib/state/portfolio_controller.dart   varlıklar, toplam, ekle/düzenle/sil
lib/state/auth_controller.dart        oturum, profil, giriş/kayıt/çıkış/silme
lib/ui/widgets/                       ortak parçalar (alt menü, alanlar, düğmeler)
lib/ui/auth/                          giris, kayit, sifre, sifre_gonderildi
lib/ui/home/                          shell (alt menü), portfoy, piyasa, ayarlar
lib/ui/assets/                        varlik_ekle, detay
lib/ui/account/                       profil, hesap_sil
test/                                 yukarıdaki her dosya için *_test.dart
```

---

### Task 1: Proje iskeleti, tema ve biçimlendirme

**Files:**
- Create: Flutter projesi (`flutter create --org com.cuzdan --project-name cuzdan --platforms=android,ios .`), `lib/core/theme.dart`, `lib/core/format.dart`
- Modify: `pubspec.yaml` (provider, shared_preferences, intl, google_fonts)
- Test: `test/core/format_test.dart`

**Interfaces:**
- Produces: `String formatTry(double v)`, `String formatRate(double v)`, `String formatPercent(double v)` (işaretsiz), `double? parseAmount(String s)` (null = geçersiz), `class AppColors` (yukarıdaki sabitler), `ThemeData buildTheme()`.

- [ ] **Step 1: Write the failing test.** `formatTry(415206)` → `'₺ 415.206,00'`; `formatTry(0)` → `'₺ 0,00'`; `formatTry(999999999)` → `'₺ 999.999.999,00'`; `formatRate(41.18)` → `'41,1800'`; `formatPercent(0.62)` → `'%0,62'`; `parseAmount('2.500')` → `2500`; `parseAmount('2500')` → `2500`; `parseAmount('2.500,5')` → `2500.5`; `parseAmount('')`, `parseAmount('0')`, `parseAmount('-3')`, `parseAmount('abc')` → `null`.
- [ ] **Step 2: Run** `flutter test test/core/format_test.dart`. Expected: FAIL (dosya yok).
- [ ] **Step 3: Implement** `format.dart` (`intl` ile `tr_TR`; `parseAmount` binlik noktayı atar, virgülü ondalık sayar) ve `theme.dart`.
- [ ] **Step 4: Run** aynı komut. Expected: PASS. Ardından `flutter analyze` temiz.
- [ ] **Step 5: Commit** `feat: Flutter iskeleti, tema ve TL biçimlendirme`.

### Task 2: Alan modelleri ve net değer hesabı

**Files:**
- Create: `lib/domain/asset_kind.dart`, `lib/domain/models.dart`, `lib/domain/portfolio.dart`
- Test: `test/domain/portfolio_test.dart`

**Interfaces:**
- Produces: `enum AssetKind { gramGold, quarterGold, halfGold, fullGold, usd, eur, gbp }` (her biri `label` ve `unit` taşır: `Gram Altın`/`gr`, `Çeyrek Altın`/`adet`, `Amerikan Doları`/`USD`, …); `class Quote { final String symbol; final double buy, sell, changePercent; final DateTime updatedAt; }`; `class Holding { final String id; final AssetKind kind; final double amount; final String note; }`; `double? rowValue(Holding h, Map<AssetKind, Quote> q)`; `double netValue(List<Holding> hs, Map<AssetKind, Quote> q)`.

- [ ] **Step 1: Write the failing test.** Spec örneği: gram 40 @4148, çeyrek 8 @6940, USD 2500 @41,18, EUR 1200 @48,06, GBP 600 @55,24 → `netValue` `closeTo(415206.00, 0.005)`. Ek testler: boş liste → `0`; fiyatı olmayan varlık için `rowValue` → `null` ve `netValue` onu saymaz; aynı türden iki `Holding` ikisi de sayılır.
- [ ] **Step 2: Run** `flutter test test/domain/portfolio_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** modelleri ve iki fonksiyonu (`rowValue` = `amount * quote.buy`).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: alan modelleri ve net değer hesabı`.

### Task 3: Veri arayüzleri ve sahte uygulamalar

**Files:**
- Create: `lib/data/price_feed.dart`, `lib/data/auth_repository.dart`, `lib/data/holdings_repository.dart`
- Test: `test/data/holdings_repository_test.dart`, `test/data/auth_repository_test.dart`, `test/data/price_feed_test.dart`

**Interfaces:**
- Consumes: `Quote`, `Holding`, `AssetKind` (Task 2).
- Produces:
  - `abstract class PriceFeed { Stream<Map<AssetKind, Quote>> get quotes; Stream<Quote> get ons; }` ve `FakePriceFeed({Duration tick})` (tasarımdaki örnek fiyatlarla başlar, her `tick`te küçük rastgele oynar, `dispose()` var).
  - `abstract class HoldingsRepository { Future<List<Holding>> load(); Future<void> save(List<Holding> h); }` ve `LocalHoldingsRepository` (`shared_preferences`, JSON).
  - `abstract class AuthRepository { Future<UserProfile?> currentUser(); Future<UserProfile> signIn(String email, String password); Future<UserProfile> signUp({required String firstName, lastName, email, password}); Future<UserProfile> signInWithGoogle(); Future<UserProfile> signInWithApple(); Future<void> sendPasswordReset(String email); Future<void> signOut(); Future<void> deleteAccount(); Future<UserProfile> updateProfile(UserProfile p); }` ve `FakeAuthRepository` (bellekte tek kullanıcı; yanlış şifre `AuthException('Şifre hatalı')`).
  - `class UserProfile { String firstName, lastName, email, phone; }` (models.dart'a eklenir) ve `class AuthException implements Exception { final String message; }`.

- [ ] **Step 1: Write the failing tests.** Depo: `save` sonra `load` aynı listeyi döndürür; boş depoda `load` → `[]`. Auth: kayıt sonrası `currentUser` dolu; yanlış şifre `AuthException`; `signOut` sonrası `currentUser` → `null`; `deleteAccount` sonrası aynı e-postayla `signIn` başarısız. Fiyat akışı: ilk olay yedi türü de içerir ve `FakePriceFeed` `dispose` sonrası olay üretmez.
- [ ] **Step 2: Run** `flutter test test/data`. Expected: FAIL.
- [ ] **Step 3: Implement** arayüzleri ve sahte uygulamaları. `shared_preferences` testte `SharedPreferences.setMockInitialValues({})`.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: veri arayüzleri ve sahte uygulamalar`.

### Task 4: Durum denetleyicileri

**Files:**
- Create: `lib/state/market_controller.dart`, `lib/state/portfolio_controller.dart`, `lib/state/auth_controller.dart`
- Test: `test/state/*_test.dart`

**Interfaces:**
- Consumes: Task 3 arayüzleri, Task 2 `netValue`/`rowValue`.
- Produces:
  - `MarketController(PriceFeed)`: `Map<AssetKind, Quote> quotes`, `Quote? ons`, `DateTime? lastUpdate`, `bool isStale(DateTime now, {Duration after = const Duration(seconds: 30)})`.
  - `PortfolioController(HoldingsRepository, MarketController)`: `List<Holding> holdings`, `double total`, `Future<void> add(AssetKind k, double amount, String note)`, `Future<void> update(String id, double amount, String note)`, `Future<void> remove(String id)`, `double? valueOf(Holding h)`.
  - `AuthController(AuthRepository)`: `UserProfile? user`, `String? error`, `bool busy`, `Future<bool> signIn(email, password)`, `Future<bool> signUp(...)`, `Future<bool> google()`, `Future<bool> apple()`, `Future<bool> sendReset(email)`, `Future<void> signOut()`, `Future<bool> deleteAccount(String typedEmail)` (e-posta eşleşmezse `false`, hiçbir şey silinmez; eşleşme küçük/büyük harf ve baştaki/sondaki boşluğa duyarsız), `Future<void> saveProfile(UserProfile)`.

- [ ] **Step 1: Write the failing tests.** Varlık ekle/sil/güncelle depoya yazılır; `total` fiyat gelince değişir; fiyat yokken `valueOf` → `null`; `isStale` 31 sn sonra `true`, 5 sn sonra `false`; `deleteAccount('  AYSE@ornek.com ')` kullanıcı e-postası `ayse@ornek.com` iken `true`, farklı adreste `false`.
- [ ] **Step 2: Run** `flutter test test/state`. Expected: FAIL.
- [ ] **Step 3: Implement** denetleyicileri (`ChangeNotifier`, akış aboneliği `dispose`'ta iptal).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: durum denetleyicileri`.

### Task 5: Uygulama kabuğu ve giriş akışı (4 ekran)

**Files:**
- Create: `lib/main.dart`, `lib/app.dart`, `lib/ui/widgets/fields.dart`, `lib/ui/widgets/buttons.dart`, `lib/ui/auth/giris.dart`, `kayit.dart`, `sifre.dart`, `sifre_gonderildi.dart`
- Test: `test/ui/auth_flow_test.dart`

**Interfaces:**
- Consumes: `AuthController` (Task 4), tema (Task 1).
- Produces: rotalar `'/giris'`, `'/kayit'`, `'/sifre'`, `'/sifre-gonderildi'`, `'/'` (kabuk); `LabeledField` (etiketli alan), `PrimaryButton`, `SocialButton({required String label, required VoidCallback onTap})`; `class Validators { static String? email(String v); static String? password(String v); }` (`password`: en az 8 karakter).

- [ ] **Step 1: Write the failing widget tests.** Oturum yokken uygulama Giriş'i açar. Geçersiz e-postayla "Giriş yap" hata gösterir ve oturum açmaz. Kayıt'ta koşul kutusu işaretli değilken "Hesap oluştur" pasif; 7 karakterlik şifre "En az 8 karakter olmalı." hatası verir. "Şifremi unuttum" → e-posta → "Bağlantıyı gönderdik" ekranı ve metinde girilen adres. Giriş başarılı olunca `'/'` açılır.
- [ ] **Step 2: Run** `flutter test test/ui/auth_flow_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** ekranları tasarımdaki metin ve yerleşimle. Google/Apple düğmeleri `AuthController.google()`/`apple()` çağırır (yer tutucu görünüm, tasarım notu: resmi düğmeler sonra).
- [ ] **Step 4: Run.** Expected: PASS. `flutter analyze` temiz.
- [ ] **Step 5: Commit** `feat: giriş, kayıt ve şifre sıfırlama ekranları`.

### Task 6: Portföy ve Piyasa

**Files:**
- Create: `lib/ui/home/shell.dart`, `portfoy.dart`, `piyasa.dart`, `lib/ui/widgets/bottom_nav.dart`
- Test: `test/ui/home_test.dart`

**Interfaces:**
- Consumes: `PortfolioController`, `MarketController`, `formatTry`, `formatRate`, `formatPercent`.
- Produces: `HomeShell` (Portföy / Piyasa / Ekle / Ayarlar sekmeleri; "Ekle" `'/ekle'` rotasını açar); `PortfoyScreen`, `PiyasaScreen`.

- [ ] **Step 1: Write the failing widget tests.** Spec örnek verisiyle Portföy `₺ 415.206,00` gösterir ve beş satır listeler. Varlık yokken `₺ 0,00` ve "İlk varlığını ekle". Fiyat yokken satır değeri `—`. Piyasa'da filtre "Altın" yalnızca altın satırlarını bırakır. `isStale` doğruyken "Son güncelleme" etiketi görünür.
- [ ] **Step 2: Run** `flutter test test/ui/home_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** ekranları. Satıra dokunma `'/detay'` rotasını `Holding` ile açar.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: Portföy ve Piyasa ekranları`.

### Task 7: Varlık ekle ve döviz detayı

**Files:**
- Create: `lib/ui/assets/varlik_ekle.dart`, `lib/ui/assets/detay.dart`
- Test: `test/ui/assets_test.dart`

**Interfaces:**
- Consumes: `PortfolioController.add/update/remove`, `parseAmount`, `formatTry`.
- Produces: rotalar `'/ekle'`, `'/detay'` (argüman: `Holding`).

- [ ] **Step 1: Write the failing widget tests.** USD seçili, `2.500` yazılınca önizleme `₺ 102.950,00` (alış 41,18). `0`, boş, `abc` için "Portföye ekle" pasif ve altında neden yazılı. Eklenince Portföy'e dönülür ve toplam artar. Detay'da "Varlığı sil" varlığı kaldırır. İki kez USD eklemek iki satır üretir.
- [ ] **Step 2: Run** `flutter test test/ui/assets_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** ekranları. Detay grafiği `CustomPainter` ile çizilir; veri `MarketController` içinde tutulan son 60 örnektir (bu görev `MarketController`'a `List<double> history(AssetKind)` ekler).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: varlık ekle ve detay ekranları`.

### Task 8: Ayarlar, kullanıcı bilgileri ve hesap silme

**Files:**
- Create: `lib/ui/home/ayarlar.dart`, `lib/ui/account/profil.dart`, `lib/ui/account/hesap_sil.dart`
- Test: `test/ui/account_test.dart`

**Interfaces:**
- Consumes: `AuthController`, `Validators`.
- Produces: rotalar `'/profil'`, `'/hesap-sil'`.

- [ ] **Step 1: Write the failing widget tests.** Profil'de ad değişip "Değişiklikleri kaydet" `saveProfile` çağırır ve Ayarlar'daki kartta yeni ad görünür. "Çıkış yap" Giriş'e döner. Hesap sil: e-posta eşleşmeden "Hesabı kalıcı olarak sil" pasif; `'  AYSE.YILMAZ@ORNEK.COM '` ile aktif ve sonra Giriş'e döner, oturum yok.
- [ ] **Step 2: Run** `flutter test test/ui/account_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** ekranları. "Görünüm: Sistem" satırı pasif ve soluk gösterilir (karanlık tema ilk sürümde yok).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: ayarlar, profil ve hesap silme`.

### Task 9: Bayat fiyat etiketi, yönerge ve son doğrulama

**Files:**
- Create: `README.md`
- Modify: `lib/ui/home/portfoy.dart`, `piyasa.dart` (etiket zaten Task 6'da; burada yalnızca soluk renk ve metin son haline getirilir)
- Test: `test/ui/stale_test.dart`

**Interfaces:**
- Consumes: `MarketController.isStale`, `lastUpdate`.

- [ ] **Step 1: Write the failing test.** `lastUpdate` 14:32, şimdi 14:33 → etiket "Son güncelleme 14:32" ve soluk renk (`AppColors.muted`); taze veride "Canlı" etiketi.
- [ ] **Step 2: Run** `flutter test test/ui/stale_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** etiket mantığı. README: çalıştırma (`flutter run`), test (`flutter test`), sahte uygulamaların nerede olduğu ve gerçek bağlantı için hangi arayüzlerin uygulanacağı.
- [ ] **Step 4: Run** `flutter analyze && flutter test`. Expected: analiz temiz, tüm testler PASS. Ardından `flutter build apk --debug` derlenir (Android SDK varsa; yoksa bu adım atlanır ve rapora yazılır).
- [ ] **Step 5: Commit** `feat: bayat fiyat etiketi ve README`.

---

## Kapsam dışı (sonraki plan)

Gerçek `PriceFeed` (Harem Altın veya üçüncü taraf), gerçek `AuthRepository` (Google/Apple dahil), sunucuda varlık depolama, resmi Google/Apple düğmeleri, "Şifreyi değiştir" ekranı, karanlık tema. Hepsi spec'teki açık sorulara bağlı.
