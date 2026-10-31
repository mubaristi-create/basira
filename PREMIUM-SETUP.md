# SHAMS Premium + Xeyriyyə Fondu

## Bu yeniləmənin faylları

Yeni: `backend/server.cjs`, `backend/store.cjs`, `backend/google.cjs`, `backend/admin-password.cjs`, `backend/config.example`, `backend/premium.test.cjs`, `dist/premium.js`, `dist/premium.css`, `dist/admin.html`, `dist/admin.js`, `PREMIUM-SETUP.md`.

Yenilənən: `dist/enhancements.js`, `dist/cosmic.js`, `dist/index.html`, `dist/sw.js`, `check.cjs`, `.gitignore`, `README.md`, `INTEGRATION.md`; GitHub ixracında əlavə olaraq `package.json` və `serve.cjs`. Əvvəlki funksiyalara aid digər fayllar dəyişdirilməyib. İxracın hamısı `outputs/basira-github/` qovluğundadır.

## Hazır olan və aktivləşdirmə həddi

Mövcud layihə statik PWA idi; backend, admin, server hesabları və Android layihəsi yox idi. Əlavə npm paketi olmadan Node.js 24 + daxili SQLite serveri və qorunan admin panel əlavə edildi. Mövcud ibadət qeydləri dəyişdirilmir. İnteqrasiya TWA üçün rəsmi Digital Goods + Payment Request API yolundan istifadə edir. Android layihəsi/AAB, real Play məhsulu, xidmət hesabı, HTTPS server və RTDN sazlanmadan real alış edilmir. API açarı, package ID və satış uydurulmayıb. GitHub Pages yalnız statik hostdur və bu backend-i işlətmir; bu versiya canlı maliyyə sistemi kimi Pages-ə yayımlanmayıb.

## Lokal açılış və test

Node.js 24+: `node backend/server.cjs` (və ya ixrac paketində `npm start`). Premium: `http://127.0.0.1:4173/#pro`, admin: `http://127.0.0.1:4173/admin.html`. Açarlar olmadan fond boş real bazadan sıfır göstərir, alış bağlıdır, admin şifrəsi təyin edilmədən giriş bağlıdır. Seed/demo satış yoxdur. Testlər yalnız yaddaşdakı ayrıca bazaya sintetik fixture yazır.

`node check.cjs` mövcud 22 bölmə və funksiyaları; `node --test backend/premium.test.cjs` Premium/fond təhlükəsizliyini yoxlayır. Real Play Sandbox / fiziki Android testi açarlar və AAB olmadığı üçün keçirilməyib.

## Server sazlaması

`backend/config.example` bütün boş sahələri göstərir. `.env`, `backend/config.local`, xidmət hesabı JSON-u, SQLite və şifrələmə açarını Git-ə əlavə etməyin. Server `dist/` xaricini HTTP ilə təqdim etmir; məlumat və credential yollarının `dist/` içində olması rədd edilir.

- HTTPS domenini `SHAMS_ORIGIN`-ə yazın (sonunda `/` olmadan). Tətbiq və `/api/` eyni origin-də Node serverə yönəlsin. `NODE_ENV=production`, `SHAMS_HOST=127.0.0.1` və HTTPS reverse proxy istifadə edin. Domen məlum deyil, nümunə domen doldurulmayıb.
- `SHAMS_DATA_DIR`: qalıcı, web root xaricində, yalnız server prosesinin yaza bildiyi qovluq. SQLite WAL-a görə tək qalıcı disk üzərində server işlədin; serverless/keçici disk uyğun deyil. DB-ni, WAL-ı və açarı uyğun snapshot/SQLite backup üsulu ilə ehtiyatlayın.
- `SHAMS_DATA_KEY`: kriptoqrafik təsadüfi 32 baytın base64 təqdimatı. Mövcud bazanın açarını dəyişsəniz tokenlər açıla bilməz; açarı ayrıca təhlükəsiz ehtiyatlayın. Lokal rejim yalnız yerli private-data/local-data.key yaradır.
- `SHAMS_ADMIN_PASSWORD_HASH`: minimum 16 simvolluq öz şifrənizi stdin ilə `node backend/admin-password.cjs`-ə verin, çıxan scrypt hash-i server secret kimi saxlayın. Şifrəni komanda arqumentinə və repoya yazmayın. Bu hash real Google açarı deyil.
- `GOOGLE_APPLICATION_CREDENTIALS`: real xidmət hesabı JSON faylının web root xaricindəki yolu. `PLAY_PACKAGE_NAME`, `PLAY_PRODUCT_ID`, `PLAY_BASE_PLAN_ID` real Console dəyərləridir.
- `PLAY_RTDN_AUDIENCE`: Pub/Sub push üçün dəqiq HTTPS audience; `PLAY_RTDN_SERVICE_ACCOUNT_EMAIL`: bildiriş imzalayan real push xidmət hesabı. OIDC imzası, issuer, audience, email və expiry serverdə yoxlanır.
- Sazlama tamamlandıqdan sonra `SHAMS_ENABLE_BILLING=true`. Nümunə env faylını lokal doldurub `node --env-file=backend/config.local backend/server.cjs` işlədə bilərsiniz. Boş parametrlərlə production işə düşmür.

Admin ayrıca HttpOnly/SameSite cookie, CSRF, scrypt, giriş limiti ilə qorunur. Production cookie Secure-dur. Admin hesabı ictimai istifadəçinin Premium cookie-sini dəyişmir. Maliyyə sənədləri yalnız adminə açıqdır; yalnız manual təsdiqlənmiş yardımın sənədi ictimai endirməyə açılır. İctimailəşdirmədən əvvəl şəxsi məlumatları gizlədin.

## Google Play Console / Android

1. Mövcud Android package-in real ID-sini müəyyən edin. Bu repoda Android wrapper yoxdur. PWA-nı TWA kimi paketləyin, Digital Asset Links-i real domen və Play App Signing SHA-256 ilə qurun. Bubblewrap-da `features.playBilling.enabled=true` və ya Android Browser Helper-in rəsmi Play Billing körpüsü lazımdır. Yeni Android asılılıqlarını bu statik PWA-ya saxta layihə kimi əlavə etməmişik.
2. Play Console-da Premium abunəliyi yaradın: bir illik auto-renew base plan, USD baza qiyməti **$3.60**. Yerli qiymətləri/vergiləri yoxlayın və planı aktivləşdirin. Bu TWA yolu üçün illik planı backwards-compatible edin; eyni məhsulda aylıq/trial/qarışıq offer işlətməyin. Fərqli period gəlsə alış düyməsi təhlükəsiz şəkildə bağlı qalır.
3. Google Play Developer API-ni aktivləşdirin. Xidmət hesabına həmin tətbiqdə abunəlikləri görmək/idarə etmək, təsdiqləmək üçün lazımi Play icazələrini verin. JSON credential yalnız serverdə saxlanılır; brauzerə verilməz.
4. Pub/Sub mövzusu yaradın, Google Play notification xidmətinə publisher icazəsi verin. Console-da RTDN mövzusunu seçin. Authenticated push subscription-u `https://REAL-DOMAIN/api/play/rtdn` ünvanına yönəldin; dəqiq audience və push xidmət hesabını env-ə yazın. Test bildirişini göndərin; 2xx nəticəsini yoxlayın. Unknown purchase RTDN-i, client tokeni istifadəçi ilə bağlayanadək retry üçün 503 alır.
5. Daxili test kanalına billing-enabled AAB yükləyin, license tester hesabını əlavə edin və Play-dən quraşdırın. Real cihazda localized price, alış, pending, cancel, renew, grace/hold, expire, refund/revoke və restore yoxlanmalıdır. Test alışları fonda daxil edilmir.
6. Play maliyyə/earnings hesabatından faktiki USD merchant settlement məlumatlarını çıxarın. Adminə daxil olub yalnız Google-da təsdiqlənmiş order-lərin faktiki rəqəmlərini və sübutunu təsdiqləyin. Qeyri-USD satış üçün Google hesabatındakı faktiki USD settlement/FX nəticəsini istifadə edin; özbaşına məzənnə yoxdur. Başqa merchant valyutası istifadə olunursa USD-yə təsdiqlənmiş çevirmə sənədi tələb olunur. Commission API-dən təxmin edilməyib.

## Maliyyə qaydaları

Google SubscriptionPurchaseV2 nəticəsi təsdiqlənir, məhsul/base plan yoxlanır, aktiv alış serverdə acknowledge edilir. Alış tokenləri AES-256-GCM ilə şifrələnir, sahibliyi server profilinə bağlanır. Aktiv/grace və müddəti bitməmiş canceled access saxlayır; pending, hold, paused, expired açmır. Ləğv Google subscription management linkində edilir; növbəti ödənişi dayandırır. Bərpa Digital Goods listPurchases və server verify ilə işləyir. Başqa cihazda sahiblik üçün məxfi profil bərpa kodu lazımdır; istifadəçi bu kodu saxlamalıdır. Aktiv sessiyada yeni kod yaradıla bilər, əvvəlkini ləğv edir. Profil recovery kodu şəxsi duaları buluda köçürmür.

Hər yeni uğurlu Google order unikal qeyd olunur. Məbləğ və komissiya client qiymətindən götürülmür. Faktiki maliyyə təsdiqlənənədək charity **0 əlavə** edir. İlkin 15% komissiya yalnız admin izahıdır; avtomatik heç nə tutulmur.

- Brüt üsul: `(gross − fee − tax − other) × 20%`.
- Artıq-xalis üsul: `actual net × 20%`, əlavə tutulma sahələri qəbul edilmir.
- Hər düzəliş əvvəlki hesabın üzərinə yeni satış kimi deyil, əvvəlki charity ilə fərq kimi tətbiq olunur. Optimistic revision köhnə/təkrar POST-u rədd edir.
- Ledger bütün məbləğləri integer microUSD saxlayır (1 USD = 1,000,000). 20% hesabı microUSD-yə doğru sıfıra kəsilir. Refunddan qalan komissiya kimi mənfi xalis rəqəmlər balansı azaldır; balans sıfıra saxtalaşdırılmır.
- Refund/chargeback Voided Purchases API ilə təsdiqlənəndə müsbət ayrılmış pay dayandırılır və faktiki yenidən uzlaşdırma tələb olunur. Qismən refundun məlum olmayan qalıq payı fonda daxil edilmir. Eyni void hadisəsi təkrar hesablanmır. Sonrakı hesabat yeni faktiki yekunu təsdiqləyir.
- RTDN + server açılışında və hər 6 saatda sync var. Tətbiq status sorğusu da Google ilə yenidən yoxlayır. Voided API son 30 günü qaytarır; daha uzun server fasiləsindən sonra maliyyə hesabatı manual uzlaşdırılmalıdır. RTDN-dən əvvəl itirilmiş köhnə renewal order-ləri uydurulmur və fonda əlavə edilmir; əlavə tarixi məlumat lazımdırsa verified import ayrıca hazırlanmalıdır.
- Ledger/distribution/audit `BEGIN IMMEDIATE` tranzaksiyası içində dəyişir. Unikal event key ikiqat saymanı bloklayır. Audit append-only hash zənciridir; ictimai CRUD yoxdur. DB faylını dəyişə bilən sistem administratoruna qarşı müstəqil notarius deyil.
- Fond $1,000 həddini keçəndə admin panelində bildiriş yaranır (açıq panel 60 saniyədə yenilənir). Email/push provayderi olmadan saxta çatdırılma iddiası yoxdur.
- Paylama real köçürmə etmir. Admin təşkilat/məbləğ/tarix/sübut ilə qaralama yaradır, sonra **ödəniş edilib** təsdiqi verir. Balans çatmırsa rədd edilir; eyni payment evidence ikinci dəfə sayıla bilməz. Təsdiqdən sonra balans azalır və ictimai tarixçə/sənəd görünür. Refund paylamadan sonra gələndə yaranan mənfi balans gizlədilmir.

## İstinadlar

- [TWA Play Billing: qiymət, alış və bərpa](https://developer.chrome.com/docs/android/trusted-web-activity/receive-payments-play-billing)
- [Abunəliklərin lifecycle və server yoxlaması](https://developer.android.com/google/play/billing/lifecycle/subscriptions)
- [SubscriptionPurchaseV2](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2)
- [Voided Purchases](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list)
- [Faktiki maliyyə hesabatları](https://support.google.com/googleplay/android-developer/answer/6135870)
