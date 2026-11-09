# SHAMS — texniki audit, faza 1–2 və Bilgi Oyunu

İş 8 noyabrda başlanıb; yekun yoxlamalar 9 noyabr 2026. İstifadəçinin əlavə etdiyi plana uyğun növbəti AdMob/Premium/Auth fazaları təsdiqdən sonra aparılacaq. Bu mərhələ production təsdiqi deyil və yeni Play AAB buraxılışı deyil. Mövcud yayımlanmış 1.8.2 AAB dəyişdirilmir.

## Faza 1 — audit nəticələri

| Sahə | Fakt və qərar |
|---|---|
| Texnologiya | HTML/CSS/JavaScript veb tətbiq + native Java WebView Android qabığı; Capacitor/React deyil. Gradle/AGP 8.13.2, Java 17 dili, compile/target API 36, min API 26. Paket `com.shams.play`, daxili Java namespace `app.shams.mobile`. |
| Safe area | Insets WebView-in özünə padding kimi verilirdi; WebView sərhədləri/vh/visual viewport eyni usable sahəni ölçmürdü. Kamera kəsiyi ayrıca nəzərə alınmırdı, API 26–29 yolu yox idi və ilkin insets yenə uşağa ötürülürdü. Faza 2-də düzəldildi. |
| AdMob | Mövcud Gradle-də Mobile Ads/UMP SDK-sı və istehsal reklam ID-ləri yoxdur. Banner işləyirmiş kimi göstərilmir. Adaptive banner, consent və server Premium ilə əlaqə faza 3-dədir; real App ID/Ad Unit ID tələb olunur. |
| Premium | Billing 9.1.0 və `shams_premium_yearly`, native alış/bərpa və server yoxlama kodu var. Canlı config sorğusu: Google=false, Apple=false, backend base plan qaytarmır. Console-dakı məhsulun/base planın aktivliyi bu mərhələdə təsdiqlənməyib. Satınalma/renewal/refund/lisenziya testi aparılmış sayılmır. Native premium UI config-də köhnə `app.shams.mobile` sabiti də faza 4-də uyğunlaşdırılmalıdır. |
| Auth | Supabase e-poçt girişi, refresh və yadda saxlanan sessiya var. Canlı Auth ayarı Google=false, email=true, auto-confirm=true. Google OAuth client/redirect və native geri dönüş axını faza 5-də qurulmalıdır. Sessiya hazırda WebView localStorage-da saxlanır; Android Keystore ilə qorunan token saxlanması ayrıca işdir. Heç bir real hesab silinməyib. |
| Əsas funksiyalar | Mövcud geniş `check.cjs` Quran, dua CRUD, namaz təlimatı, oruc gündəliyi, alt naviqasiya, beş dil və offline namaz vaxtlarını yoxlayir. Fiziki cihazda fon azanı/vidcet və Android 10–16 matrisi hələ yoxlanmayıb; bunlar faza 6–7 qəbul şərtləridir. Ayrı hədis kitabxanası və qəza namazı modulunun hazır olduğu iddia edilmir. |
| Məlumatlar | Köhnə nəticələr, dördüncü səviyyəyədək açılmış irəliləyiş, dua/namaz/oruc qeydləri saxlanır. Yeni quiz tarixçəsi hesab üzrə ayrı açarlarda, qonaq tarixçəsi ayrıca saxlanır. Qonaq tarixçəsinin hesaba birləşdirilməsi açıq seçimdir. |

## Faza 2 — tətbiq olunan düzəliş

- `MainActivity.java`: native FrameLayout shell sistem barı, display cutout və IME-in birləşmiş insets-ini alır. WebView həqiqi azaldılmış sahədə ölçülür; öz daxili padding-i böyüdülmür. API 30+ və API 26–29 ayrı yolları var. Uşağa sıfırlanmış insets ötürülür ki, WebView CSS/IME sahəsini ikinci dəfə əlavə etməsin.
- `InsetsBounds.java`: status bar, kamera kəsiyi, navigation və klaviatura boşluqlarını toplamaq əvəzinə maksimum kənarı götürür. Dönmə və klaviatura bağlandıqda padding əvvəlki dəyərə yığılmır, yenidən hesablanır.
- `safe-layout.js/css`: yalnız Android qabığında aşağı menyunun ölçülmüş hündürlüyü ayrılır. Böyük sistem şriftlərində başlıq və naviqasiya sətir aça bilir. WebView sistemin fontScale parametrini text zoom-a tətbiq edir. Veb/iOS CSS safe-area davranışı saxlanır.
- Yoxlama: Java inset sınaqları, API 36 native yığım və lint. **Real Android 10–16 cihazları, müxtəlif WebView versiyaları, kamera kəsiyi və 3-button/gesture rejimlərinin ekran sınaqları bu mühitdə yoxdur.** Bu matrisi tam keçmiş saymırıq.

Rəsmi əsas: [WebView insets](https://developer.android.com/develop/ui/views/layout/webapps/understand-window-insets), [edge-to-edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge). WebView-ə artıq idarə olunmuş insets-in sıfırlanması ikiqat boşluğun qarşısını alır; bu yalnız görünüşə sabit padding əlavə etmək deyil.

## Əlavə təsdiqlənmiş iş — Bilgi Oyunu

Ətraflı müqavilə və nəticələr: [QUIZ-UPGRADE.md](QUIZ-UPGRADE.md). Köhnə seçim hər sessiyada eyni 10 suallıq kateqoriya hovuzunu yenidən qarışdırırdı; server də göstərilmə tarixçəsini nəzərə almadan çətinlik/random əsasında seçirdi. Dəqiq eyni məzmunlu sual ID-ləri üçün ayrıca deduplikasiya yox idi. Bu səbəblər aradan qaldırıldı.

Yeni server tarixçəsi/RLS/RPC-ləri mövcud Supabase layihəsinə əlavə edilib, ilkin 80 payload köçürülüb. Köhnə tətbiq üçün əvvəlki RPC imzası saxlanıb və yeni bank ID-ləri köhnə paketə göndərilmir. SQL rollback sınağı real istifadəçi məlumatını saxlamadan bitdi; ictimai katalog HTTP 200/80, anonim tarixçə HTTP 401 qaytardı.

**Veb/native mənbə dəyişiklikləri hazırda kompüterdədir; GitHub Pages və Play-də yayımlanmır.** İstifadəçinin faza 1–2-dən sonra təsdiq gözləmə tələbi saxlanır. Faza 8-də bütün razılaşdırılmış düzəlişlər bir yeni, istifadə olunmamış versionCode ilə buraxılmalıdır.

## Sonrakı fazalar — təsdiq gözləyir

3. AdMob + UMP/test reklamları + adaptive banner; reklam ID-ləri və məqsədli regionlar lazımdır. Dini oxu ekranlarında yerləşmə ayrıca nəzərdən keçirilməlidir.
4. Play Console məhsul/base plan/offer, xidmət hesabı API icazələri, RTDN və real License Testing. Şəxsi açarlar ictimai repoya daxil edilməməlidir.
5. Google/Supabase OAuth və native callback, qorunan token anbarı, offline/persistent auth.
6. Bildiriş/azan/vidcet və beş dil cihaz yoxlamaları.
7. RLS, təhlükəsizlik, performans və tam cihaz regressiyası; lazım olan məxfilik/Data safety yenilənməsi.
8. Yeni imzalı AAB, Internal testing və real mağaza yoxlamaları. Bütün şərtlər keçmədən production-ready deyilmir.

## 9 noyabr — növbəti fazalara istifadəçi təsdiqi
İstifadəçi qalan fazaları və son versiyanı hazırlamağa təsdiq verdi. 1.9.0 nəticələri RELEASE-1.9.md və PLAY-CONSOLE-1.9.md-dədir. AdMob/native auth kodu və imzalı APK/AAB tamamlanıb. Canlı reklam telefon təsdiqinə, real Billing mağaza/API ayarlarına bağlı qalır; fiziki cihaz və real alış sınaqları tamamlanmış sayılmır. Əvvəlki “təsdiq gözləyir” hissələri ilkin audit tarixçəsidir.
