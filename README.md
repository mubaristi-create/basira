# Bəsirə — cari veb versiya

Tətbiq telefon ekranlarına uyğun veb/PWA kimi hazırlanıb.

## Yeniliklər
- #F8F4E9 açıq krem fon, #064E3B yaşıl başlıqlar və #D4AF37 qızılı vurğuları.
- Bəsirə Pro təqdimatı: reklamsız istifadə, $1.99 USD. Ödəniş provayderi qoşulmayıb; alış və avtomatik gəlir bölgüsü aktiv deyil. Gəlirin 20%-nin yardım üçün ayrılması haqqında mətn tətbiq sahibinin verdiyi təqdimat mətnidir.
- Azərbaycan, türk, rus, ingilis və ərəb interfeysi. Ərəb dili üçün RTL görünüş. Quran tərcüməsi seçilən dilə görə yüklənir.
- 14 dualıq kitabxanada çoxdilli axtarış. Günün duası kitabxanadan yerli tarixə görə gündəlik dəyişir; bu, xaricdən hər gün yeni dua yüklənməsi deyil.
- Təsbeh hər toxunuşda bütün ekranı yeniləmir. Sayğac və muncuqlar animasiyalı yenilənir; saylar ayrıca saxlanır. Titrəyiş yalnız Vibration API və cihaz tərəfindən dəstəklənəndə işləyir.
- 249 ölkə/ərazi kodu, Open-Meteo/GeoNames ilə dünya üzrə yaşayış məntəqəsi axtarışı, koordinat və saat qurşağı ilə AlAdhan vaxtları. Axtarış nəticələrinin əhatəsi xidmətin məlumat bazasından asılıdır. Hesablama metodu və ikindi qaydası seçilə bilər.
- Namaz təlimatında iri, geyimli insan sxemləri, hərəkət izahları və iki məzhəb seçimi.
- Geri düyməsi tətbiqdaxili əvvəlki bölməni saxlayır; birbaşa daxil olmuş səhifələr üçün məntiqi üst bölməyə qaytarır.

## Saxlanma və internet
Qeydlər bu brauzerdə saxlanılır. Yeni şəhər axtarışı, tarix üçün namaz vaxtları, yeni Quran mətni və audio internet tələb edir. Tətbiq bir dəfə HTTPS ilə uğurla açıldıqdan sonra əsas ekranlar, dua kitabxanası və namaz təlimatı oflayn açılır. Bildirişlər tətbiq açıq olduqda işləyir.

## Yoxlama
17 bölmə; iki məzhəbdə 10 namaz ardıcıllığı; sayğacın ekranı yeniləməməsi; titrəyiş API çağırışları; beş dil; dua axtarışı və gündəlik seçim; şəhər/saat qurşağı sorğuları; oflayn keş; şəhər dəyişmə yarış vəziyyətləri yoxlanılıb. Beş Quran mətn xidməti canlı sorğu ilə yoxlanılıb. Brauzerdə London axtarışı, London saat qurşağı üzrə vaxtlar, ərəb RTL axtarışı və 320×568/390×844 ekranlar yoxlanılıb. Fiziki telefon titrəyişi və real ödəniş yoxlanılmayıb.


## Kompüterdə işə salmaq

Node.js 20 və ya daha yenisini quraşdırın. Bu qovluqda terminal açın:

```sh
npm start
```

Brauzerdə göstərilən localhost keçidini açın. Kitabxana quraşdırmaq və build etmək lazım deyil.

Yoxlama üçün `npm test` işlədin.

## GitHub Pages

Repozitoriyada Settings → Pages → Source hissəsində GitHub Actions seçin. Sonra Actions → Deploy to GitHub Pages → Run workflow işlədin. Yayımlama keçidini uğurlu workflow-nun github-pages environment nəticəsindən götürün.

Bu ixracda əvvəlki hosting xidmətinin identifikatorları və giriş açarları yoxdur. `dist/` qovluğu başqa statik HTTPS hostinqdə də yayımlana bilər.
