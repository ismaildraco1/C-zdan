# Cüzdan: tasarım belgesi

Tarih: 2026-11-15
Durum: Onay bekliyor

## Amaç ve neden

Cüzdan, altın ve döviz biriktiren kişilerin elindeki varlıkların toplam
değerini tek ekranda, canlı fiyatlarla görmesini sağlayan bir iOS ve
Android uygulamasıdır.

Kullanıcı elindeki varlıkları ve miktarlarını girer (ör. 40 gr gram altın,
8 çeyrek, 2.500 USD). Uygulama bunları Harem Altın fiyatlarıyla Türk
Lirasına çevirip tek bir net değer olarak gösterir. Değer fiyat değiştikçe
kendiliğinden güncellenir.

Bu belgedeki amaç ve kapsam kararları kullanıcıdan gelmiştir. Kararın
yanında "benim kararım" yazan yerler önerim olarak yazılmıştır ve onaylanmadıkça
kesin değildir.

## Hedefler

- Kullanıcı uygulamayı açtığında toplam net değeri ve varlık listesini
  hemen görür.
- Fiyatlar canlı akar. Elle yenileme gerekmez.
- Aynı hesapla birden fazla cihazdan girilebilir. Varlıklar hesapta tutulur.
- iOS ve Android için tek kod tabanı: **Flutter** (kullanıcının kararı).
- Giriş yöntemleri: e-posta/şifre, Google ve Apple (kullanıcının kararı).

## Hedef olmayanlar

- Alış fiyatı, kâr/zarar veya getiri takibi. Net değer yalnızca güncel
  fiyat üzerinden hesaplanır (kullanıcının kararı).
- Gerçek para hareketi, banka bağlantısı, alım satım.
- TL dışında ana para birimi. İlk sürümde yalnızca TL.

## Anti-hedefler

Teknik olarak çalışsa bile şunlar başarısızlık sayılır:

- Gecikmeli ya da eski fiyatı canlıymış gibi göstermek. Veri bayatsa
  ekran bunu açıkça belirtmeli.
- Fiyat kaynağının kullanım koşullarını ihlal etmek (bkz. Kısıtlar).

## Kısıtlar

- **Fiyat kaynağı Harem Altın.** Resmi, herkese açık bir API bulunamadı.
  Siteden veri kazımak kullanım koşullarına aykırı olabilir ve site
  değişince bozulur. Üçüncü taraf servisler (ör. altinapi, Hasfiyat)
  Harem Altın fiyatlarını sunduklarını söylüyor, ancak bu beyanlar
  doğrulanmadı. Lisans, gecikme ve doğruluk her adayda ayrıca kontrol
  edilmeli.
- Fiyatlar doğrudan telefona çekilmez. Araya bir sunucu girer: fiyatları
  toplar, uygulamaya canlı iletir.
- Apple, uygulamada Google gibi başka bir sosyal giriş varsa Apple ile
  girişi de zorunlu tutar. İkisi birlikte tutulur.
- Google ve Apple düğmeleri resmi logo ve tasarım kurallarıyla yapılmalıdır.
  Tasarımdaki düğmeler yer tutucudur.
- Geliştirme ortamı bulutta. Harem Altın alan adı bu ortamdan açılamıyor
  (403). Veri bağlantısı kullanıcının bilgisayarında kurulacak.

## Yaklaşımlar

Uygulama tarafı kararlı: Flutter. Açık olan, hesap ve veri katmanı.

| | Yaklaşım | Artısı | Eksisi |
|---|---|---|---|
| A | Hazır servis (ör. Supabase veya Firebase) hesaplar, giriş ve varlıklar için + küçük bir fiyat servisi | Google/Apple girişi hazır gelir, az kod, hızlı | Bir dış servise bağımlılık |
| B | Kendi sunucumuz (hesaplar, giriş, varlıklar, fiyat) | Tam kontrol | Giriş ve güvenliği kendimiz yazarız, uzun sürer |
| C | Hesapsuz, yalnızca cihazda | En basit | Çoklu cihaz yok, giriş ekranları anlamsız kalır |

**Önerim: A.** Giriş ekranlarını (Google, Apple, e-posta) hazır bir servis
çözer. Yazacağımız tek özel parça, fiyatları toplayıp ileten küçük
servis olur. C, kullanıcının istediği giriş ve hesap ekranlarıyla
çelişir. B bu proje için gereğinden ağır.

**Karar kullanıcıda ve bilgisayara geçtiğinde verilecek.** Bu belge
hangisinin seçileceğini kesinleştirmez.

## Ekranlar

Tasarım, 11 ekranlık bir tuvalde hazır (özel bağlantı, paylaşım gerekir):
https://claude.ai/artifact/YHBj1PB7cWPrqVB3fWMTkF

1. Portföy: toplam net değer, bugünkü değişim, varlık listesi
2. Piyasa: canlı alış/satış tablosu, Tümü / Altın / Döviz filtresi
3. Varlık ekle: tür, miktar, not, anlık değer önizlemesi
4. Döviz detayı: değer, bugünkü grafik, alış/satış, düzenle ve sil
5. Ayarlar: tercihler, güvenlik, hakkında
6. Kullanıcı bilgileri: ad, soyad, e-posta, telefon, şifre, çıkış
7. Giriş yap
8. Hesap oluştur
9. Şifremi unuttum
10. Bağlantı gönderildi
11. Hesabı sil (e-posta ile onay)

Kayıt eksik: Şifreyi değiştir ekranı çizilmedi.

## Verilen kararlar

- **Net değer = Σ (miktar × alış fiyatı).** Elindekini bozdursa alacağı
  tutarı gösterir (benim kararım, kullanıcı itiraz etmedi).
- **Desteklenen varlıklar:** Gram, Çeyrek, Yarım, Tam altın; USD, EUR, GBP.
  Ons yalnızca Piyasa ekranında fiyat olarak görünür, portföye eklenmez.
  Altın türlerini ben ekledim, kullanıcı yalnızca döviz mi altın da mı
  sorusuna cevap vermedi. Tasarımı görüp kaldırmadı.
- **Görünüm:** koyu yeşil ve altın sarısı vurgu, Inter yazı tipi, tek
  açık tema. Karanlık tema yok.
- Ana para birimi TL. Ayarlarda gösterilir, seçilemez.

## Builder'a bırakılanlar

- Flutter içindeki durum yönetimi, klasör yapısı ve paket seçimleri.
- Canlı fiyatın uygulamaya nasıl taşındığı (WebSocket, SSE vb.).
- Tasarımdaki "Sistem" görünüm seçeneği: karanlık tema ilk sürümde yok,
  bu satır ya kaldırılır ya pasif bırakılır.

## Açık sorular (kullanıcının cevabı gerekiyor)

1. Hesap ve veri katmanı: A, B veya C? (öneri: A)
2. Fiyat kaynağı: hangi üçüncü taraf servis, ya da Harem Altın ile
   doğrudan bir anlaşma var mı? Lisans ve doğruluk kontrolü
   bilgisayardan yapılacak.
3. Fiyat bayatlarsa ekran ne göstermeli? (öneri: "Son güncelleme 14:32"
   etiketi ve soluk renk)
