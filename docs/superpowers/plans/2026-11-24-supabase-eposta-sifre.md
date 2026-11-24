# Supabase e-posta/şifre Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (kullanıcı satır içi yürütmeyi seçti). Steps use checkbox syntax.

**Goal:** Sahte hesap ve cihaz içi varlık deposunu Supabase (e-posta/şifre) ile değiştirmek; arayüz arayüzlerin arkasında kalır.

**Architecture:** `AuthRepository` ve `HoldingsRepository` arayüzlerinin Supabase uygulamaları `lib/data/supabase/` altında. `main.dart`, ayar verilmişse bunları, verilmemişse sahteleri kurar. Oturum değişince varlıklar yeniden yüklenir. Testler `MockClient` ile istek biçimini doğrular.

**Tech Stack:** `supabase_flutter`, `http` (testte `MockClient`), mevcut Flutter yığını.

**Spec:** `docs/superpowers/specs/2026-11-24-supabase-eposta-sifre-design.md`

## Global Constraints

- Hizmet anahtarı (service_role) kodda, testte ve belgede **yok**. Yalnızca adres ve genel anahtar, `--dart-define` ile.
- Mevcut 136 test yeşil kalır. Metinler Türkçe. Önceki turun Global Constraints'i geçerli.
- Supabase hatası ham metinle kullanıcıya gösterilmez; Türkçe karşılığa çevrilir.
- Yanlış şifre ve bilinmeyen e-posta aynı mesajı verir.
- Derin bağlantı: `io.cuzdan.app://login-callback/`.

## Review Focus

- E-posta doğrulaması açıkken kayıt oturum açmaz: "e-postanı doğrula" gösterilir, hata değil.
- Ağ yokken giriş/kayıt/kaydetme: çökme yok, anlaşılır mesaj; varlık eklenemediyse liste eski haline döner.
- Çıkış yapan kullanıcının varlıkları ekranda ve bellekte kalmaz; başka hesapla girince onun varlıkları gelir.
- Şifre sıfırlama bağlantısıyla gelen oturum normal girişten ayrılır: yeni şifre belirlenene kadar ana ekran açılmaz.
- Yeni şifre 8 karakterden kısa ya da iki alan uyuşmuyorsa gönderilmez.
- Hesap silme sunucuda başarısız olursa kullanıcı çıkış yapmış gibi davranılmaz.

---

### Task 1: Ayar, bağımlılık, SQL şeması, UUID

**Files:** Create `lib/core/config.dart`, `lib/domain/ids.dart`, `supabase/migrations/20261124000000_init.sql`, `supabase/README.md`; Modify `pubspec.yaml` (yapıldı), `lib/state/portfolio_controller.dart`.
Test: `test/core/config_test.dart`, `test/domain/ids_test.dart`.

**Interfaces:**
- Produces: `class AppConfig { const AppConfig({required String url, required String anonKey}); bool get isConfigured; static const fromEnvironment }` (`isConfigured` her ikisi doluysa ve url `https://` ile başlıyorsa); `String newId()` (UUID v4, küçük harf, 36 karakter).

- [ ] Test: `AppConfig(url:'',anonKey:'x').isConfigured` false; `url:'http://x'` false; geçerli ikisi true. `newId()` 1000 çağrıda benzersiz ve `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$` eşleşir.
- [ ] Çalıştır, FAIL gör. Uygula (`Random.secure`). PASS.
- [ ] `PortfolioController.add` kimliği `newId()` ile üretir (mevcut testler yeşil).
- [ ] SQL: `holdings` (id uuid pk, user_id uuid default auth.uid() → auth.users on delete cascade, kind text check 7 tür, amount numeric check > 0, note text, created_at), RLS açık, dört politika `auth.uid() = user_id`; `delete_my_account()`; `revoke ... from public, anon`; `grant execute ... to authenticated`.
- [ ] Commit.

### Task 2: Arayüz genişletmesi, sahte uygulama, AuthController

**Files:** Modify `lib/data/auth_repository.dart`, `lib/state/auth_controller.dart`. Test: `test/data/auth_repository_test.dart`, `test/state/auth_controller_test.dart`.

**Interfaces:**
- Produces: `class EmailConfirmationRequired extends AuthException`; `AuthRepository.updatePassword(String newPassword)`; `AuthRepository.passwordRecovery` (`Stream<void>`); `FakeAuthRepository({bool requireConfirmation=false})` ve `FakeAuthRepository.triggerRecovery()`; `AuthController.confirmationEmail` (`String?`), `AuthController.recovering` (`bool`), `Future<bool> updatePassword(String)`.
- `AuthController.signUp`: `EmailConfirmationRequired` yakalanırsa `false` döner, `confirmationEmail` dolar, `error` boş kalır.

- [ ] Testler: `requireConfirmation` ile `signUp` `EmailConfirmationRequired` fırlatır ve oturum açmaz; controller `confirmationEmail` doldurur, `error` null; `triggerRecovery` sonrası `recovering` true; `updatePassword` sonrası `recovering` false ve yeni şifreyle giriş olur; kısa şifre (`<8`) `AuthException` fırlatır.
- [ ] FAIL, uygula, PASS. Commit.

### Task 3: SupabaseAuthRepository

**Files:** Create `lib/data/supabase/supabase_auth_repository.dart`, `lib/data/supabase/error_messages.dart`. Test: `test/data/supabase/supabase_auth_repository_test.dart`, `test/data/supabase/error_messages_test.dart`.

**Interfaces:**
- Consumes: Task 2 arayüzü. Produces: `SupabaseAuthRepository(SupabaseClient client, {String redirectTo = 'io.cuzdan.app://login-callback/'})`; `String turkishAuthMessage(Object error)`.
- Çeviri: `invalid_credentials` → "E-posta ya da şifre hatalı."; `user_already_exists`/`email_exists` → "Bu e-posta ile zaten bir hesap var."; `email_not_confirmed` → "E-postanı doğrulaman gerekiyor. Gelen kutunu kontrol et."; `weak_password` → "Şifre çok zayıf. Daha uzun ya da daha karmaşık bir şifre dene."; `over_request_rate_limit`/`over_email_send_rate_limit` → "Çok fazla deneme yapıldı. Biraz sonra tekrar dene."; ağ hatası (`AuthRetryableFetchException`, `SocketException`, `ClientException`) → "Bağlantı kurulamadı. İnternetini kontrol et."; bilinmeyen → "Bir şeyler ters gitti. Tekrar dene."

- [ ] Testler (`SupabaseClient('https://test.supabase.co','anon',httpClient: MockClient(...))`): `signUp` `POST /auth/v1/signup` gövdesinde `email`, `password`, `data.first_name`, `data.last_name` ve `redirect_to` sorgusu; oturumsuz yanıt `EmailConfirmationRequired`; oturumlu yanıt `UserProfile`. `signIn` `POST /auth/v1/token?grant_type=password`; 400 `invalid_credentials` → Türkçe `AuthException`. `sendPasswordReset` `POST /auth/v1/recover` ve `redirect_to`. `deleteAccount` `POST /rest/v1/rpc/delete_my_account` sonra oturum kapanır; sunucu hatasında `AuthException` ve oturum açık kalır. `updateProfile` `PUT /auth/v1/user` gövdesi `data.first_name/last_name/phone`. Ağ hatası → bağlantı mesajı.
- [ ] FAIL, uygula, PASS. Commit.

### Task 4: SupabaseHoldingsRepository ve hata geri alma

**Files:** Create `lib/data/supabase/supabase_holdings_repository.dart`; Modify `lib/state/portfolio_controller.dart`. Test: `test/data/supabase/supabase_holdings_repository_test.dart`, `test/state/portfolio_controller_test.dart`.

**Interfaces:**
- Produces: `SupabaseHoldingsRepository(SupabaseClient client)`; `PortfolioController.error` (`String?`), `PortfolioController.reset()` (listeyi ve hatayı temizler, depoya yazmaz).
- `save(list)`: önce `upsert` (tüm satırlar, `onConflict: id`), sonra listede olmayanları siler. Boş liste tüm kullanıcı satırlarını siler.
- `PortfolioController._commit`: depo hata fırlatırsa liste önceki haline döner, `error = 'Değişiklik kaydedilemedi. Bağlantını kontrol edip tekrar dene.'`, ve `add/update/remove` hata yutmaz ama çökertmez (`Future<bool>` döner; `true` başarı).

- [ ] Testler: `load` `GET /rest/v1/holdings` satırlarını `Holding`'e çevirir (`amount` sayı ya da metin olarak gelebilir: `"2500.5"`); `save` upsert gövdesi ve silme isteği; ağ hatasında `save` fırlatır. Controller: depo fırlatınca `holdings` eski, `error` dolu, `add` `false` döner; `reset()` boşaltır.
- [ ] FAIL, uygula, PASS. Commit.

### Task 5: Bağlama (main, oturum değişince varlıklar)

**Files:** Modify `lib/main.dart`, `lib/app.dart`, `test/support/app_harness.dart`. Test: `test/ui/session_test.dart`.

- [ ] Testler: oturum açılınca `PortfolioController.load()` çağrılır ve o hesabın varlıkları görünür; çıkışta liste boşalır; başka hesapla girişte öncekinin varlıkları görünmez.
- [ ] `_Root` oturum değişimini dinler: kullanıcı varsa `load()`, yoksa `reset()`.
- [ ] `main.dart`: `AppConfig.fromEnvironment.isConfigured` ise `Supabase.initialize`, `SupabaseAuthRepository`, `SupabaseHoldingsRepository`; değilse sahteler. `AuthController.restore()` oturumu geri yükler.
- [ ] Commit.

### Task 6: Arayüz (doğrulama, yeni şifre, şifre değiştir, yakında)

**Files:** Create `lib/ui/auth/dogrulama.dart`, `lib/ui/auth/yeni_sifre.dart`; Modify `lib/app.dart`, `lib/ui/auth/kayit.dart`, `lib/ui/auth/giris.dart`, `lib/ui/account/profil.dart`, `lib/ui/assets/varlik_ekle.dart`, `lib/ui/assets/detay.dart`. Test: `test/ui/supabase_ui_test.dart`.

**Interfaces:** `DogrulamaScreen(email)` (rota `/dogrulama`), `YeniSifreScreen({required bool recovery})` (rota `/sifre-degistir`), `_Root`: `auth.recovering` ise `YeniSifreScreen(recovery: true)`.

- [ ] Testler: `requireConfirmation` ile kayıt `DogrulamaScreen` açar ("E-postanı doğrula", adres görünür, hata metni yok); `triggerRecovery` ana ekran yerine "Yeni şifre" gösterir; 7 karakterlik ya da uyuşmayan şifre gönderilmez ve neden yazar; geçerli şifre sonrası ana ekran; Profil "Şifreyi değiştir" satırı `YeniSifreScreen(recovery:false)` açar; varlık kaydedilemezse (`FailingHoldingsRepository`) Ekle ekranında hata mesajı görünür ve ekran kapanmaz.
- [ ] FAIL, uygula, PASS. Commit.

### Task 7: Platform ayarı ve belgeler

**Files:** Modify `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `README.md`; `supabase/README.md`.

- [ ] Android: `io.cuzdan.app` şeması için `intent-filter` (`android:exported="true"`, `VIEW`, `DEFAULT`, `BROWSABLE`). iOS: `CFBundleURLTypes` şeması `io.cuzdan.app`. İki dosya da iyi biçimli olmalı (`python3 -c xml.dom.minidom` ile doğrulanır).
- [ ] README: Supabase kurulumu (proje, SQL, redirect adresi, doğrulama), çalıştırma (`--dart-define`), sahteye geri dönüş, bilinen eksikler güncellenir (Google/Apple, çevrimdışı).
- [ ] Tüm testler, analiz, commit, push.

---

## Kapsam dışı

Google ve Apple girişi, gerçek fiyat akışı, çevrimdışı mod, e-posta değiştirme.
