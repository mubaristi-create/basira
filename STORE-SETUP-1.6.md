# SHAMS 1.6 — mağaza inteqrasiyasının aktivləşdirilməsi

Android HTML/JS + Java WebView olaraq qalır. Native Google Play Billing 9.1.0 qoşulub; yalnız Android build sistemi transitive SDK asılılıqlarını düzgün paketləmək üçün Gradle-a keçirilib. `android/build-store.ps1` JDK 21 və Android SDK 36 ilə imzalı APK/AAB yaradır. Mövcud imza faylları `private-data` daxilində qalır və yayımlanmır.

Yeni `ios/SHAMS.xcodeproj` WKWebView + StoreKit 2 layihəsidir. Mac-da `sh ios/prepare.sh` işlədin, sonra Xcode-da açın. `StoreConfig.xcconfig` daxilində qeydiyyatdan keçmiş Bundle ID və Developer Team doldurulmalıdır. Windows-da iOS compile, signing, Sandbox və IPA yoxlaması aparılmayıb.

## Google Play Console — çatışmayan məlumatlar

1. `app.shams.mobile` paketinə uyğun mağaza tətbiqi və Play App Signing / upload sertifikatının uyğunluğu. Hazır AAB-ni Internal testing-ə yükləyin.
2. `shams_premium_yearly` adlı subscription yaradın. Bir illik avtomatik yenilənən base plan-ı aktivləşdirin, USD baza qiymətini $3.50 seçin. Regional yekun qiymət SDK-dan oxunur, tətbiqdən tutulmur.
3. Android Publisher API aktiv olan service account yaradın və həmin tətbiqin alış/abunəlik yoxlanması və idarəsi üçün Play Console hüquqları verin.
4. Supabase Edge Function Secrets: `PLAY_PACKAGE_NAME=app.shams.mobile`, **real** `PLAY_BASE_PLAN_ID`, `PLAY_SERVICE_ACCOUNT_JSON`.
5. Google RTDN üçün Pub/Sub topic və authenticated push subscription yaradın. Push URL: `https://ayaiddowrabrdltrqysn.supabase.co/functions/v1/store-billing`. Google Play publisher üçün topic publish hüququ verin. `PLAY_RTDN_AUDIENCE` push URL ilə, `PLAY_RTDN_SERVICE_ACCOUNT_EMAIL` isə push identity ilə eyni olmalıdır.
6. License Testing istifadəçilərini və Internal testing tester-lərini Console-da əlavə edin. Alış testini Play Store-dan quraşdırılan versiyada edin; bu APK-ni sadəcə telefona köçürmək ödəniş sınağını əvəz etmir.

## App Store Connect — çatışmayan məlumatlar

1. Apple Developer Team, qeydiyyatdan keçmiş Bundle ID və tətbiqin numeric Apple ID-si.
2. Subscription group və `shams_premium_yearly` adlı illik auto-renewable subscription, lokallaşdırmalar və review məlumatları. $3.50 planlaşdırılmış baza qiymətidir; Console-da mövcud qiymət nöqtəsi seçilməlidir. Tətbiq həmişə mağazanın real yerli qiymətini göstərir.
3. App Store Server API üçün Issuer ID, Key ID, private `.p8` açarı. Supabase Secrets: `APPLE_BUNDLE_ID`, `APPLE_APP_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`. Açarları web koduna və GitHub-a yazmayın.
4. Production və Sandbox App Store Server Notifications **V2** URL: `https://ayaiddowrabrdltrqysn.supabase.co/functions/v1/store-billing`.
5. Sandbox tester hesabları, Xcode signing və StoreKit capability, cihaz/TestFlight sınağı. Yerli StoreKit Configuration faylının saxta JWS-i production serverində qəbul edilmir; uçdan uca doğrulama üçün Apple Sandbox istifadə edin.

## Ortaq server ayarları

Supabase-də `20261103_store_billing.sql` və `20261103_store_refunds.sql` miqrasiyaları, `store-billing` funksiyası yerləşdirilir. Tətbiqin mövcud Auth sistemi dəyişmir. Funksiya istifadəçinin access token-ini Auth serverində yoxlayır; Google tokeni və Apple JWS-i rəsmi mağaza məlumatı ilə təsdiqləyir. Google account binding SHA-256(Supabase user UUID), Apple binding isə appAccountToken UUID-dir. Başqa hesaba alış keçirmək rədd edilir.

`PURCHASE_ENCRYPTION_KEY`: təhlükəsiz yaradılmış 32 baytın base64 forması, yalnız Edge Secrets-də saxlanılır. Google tokenləri AES-GCM ilə şifrələnir. `STORE_CRON_SECRET`: təsadüfi güclü server sirri. Bu sirləri çatda göndərməyin. Mağaza açarları hazır olmadığından alış funksiyası hazırda `google:false, apple:false` qaytarır və alış bağlı qalır.

Sınaq üçün `ALLOW_STORE_SANDBOX=true`; production üçün false. Sandbox hüquqları serverdə ayrıca işarələnir, xeyriyyə gəliri hesablanmır. Production-a keçərkən əvvəlki test hüquqlarının `sandbox_allowed` sahəsini false edin. Heç bir demo satış və fond məbləği yaradılmır. Native receipt qeydləri maliyyə settlement-i deyil; mövcud xeyriyyə ledger-i yalnız faktiki təsdiqlənmiş maliyyə məlumatları ilə işləməyə davam edir.

Webhook gateway-də legacy JWT yoxlaması OFF-dur, çünki Google/Apple webhook-ları Supabase JWT-si daşımır. Bu, `verify` əməliyyatını açıq etmir: o, Auth getUser ilə real sessiya tələb edir. Google webhook-da OIDC issuer/audience/email/signature, Apple webhook-da rəsmi Apple sertifikat zənciri və JWS yoxlanır. Apple root sertifikatları public Apple mənbələrindən götürülüb. İctimai istifadəçinin maliyyə və entitlement cədvəllərinə yazmaq hüququ yoxdur.

Hər 6 saat cron ilə POST `{"action":"reconcile"}` göndərin, `x-shams-cron` başlığında server sirrini əlavə edin. Job 100 ən köhnə yoxlanmış abunəliyi yeniləyir; böyük istifadəçi sayı üçün tezliyi artırın. Webhook-lar əsas yenilənmə yoludur; istifadəçi tətbiqi açanda alışlar yenidən yoxlanır. Verilənlər bazası müddəti öz saatına görə bitirir. Google full-refund order-i təkrar yoxlama ilə açılmır; yeni təsdiqlənmiş renewal order-i əvvəlki refund-a görə bloklanmır.

## Sınaq siyahısı

Hər mağazada: alış → official sheet → server statusu; ləğv (ödənmiş müddət sonadək qalır); renewal; grace/hold; pending/cancel; full refund/revoke; müddətin bitməsi; tətbiqin yenidən quraşdırılması; eyni SHAMS hesabında başqa cihaz; Restore Purchases; başqa SHAMS hesabına restore-un rəddi. StoreKit transaction yalnız server təsdiqindən sonra finish edilir; Google acknowledgment serverdə aparılır.

Mənbələr: [Google Billing](https://developer.android.com/google/play/billing/integrate), [RTDN](https://developer.android.com/google/play/billing/rtdn-reference), [Apple server library](https://github.com/apple/app-store-server-library-node), [Apple notifications](https://developer.apple.com/documentation/appstoreservernotifications/).
