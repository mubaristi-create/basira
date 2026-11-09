# SHAMS 1.9.0 — 9 noyabr 2026

Paket: `com.shams.play` · versionCode: **21** · Android 8.0+ / target API 36.

- Quiz: görülməmiş sualların prioriteti, hesaba bağlı göstərilmə/cavab tarixçəsi, offline növbə, sabit cavab ID-ləri, 3 səviyyə, 5 dil/RTL, redaksiya təsdiqi və admin JSON importu/şikayət baxışı. Mövcud 80 sual saxlanır; 500–5000 tutumu sintetik testlərlə yoxlanılıb.
- Android safe area: sistem barları, kamera kəsiyi və klaviatura insets-i real WebView sahəsinə tətbiq edilir; alt menyu ölçülür, böyük şriftlər sətir açır.
- Google Cloud SHAMS layihəsi və OAuth client yaradılıb; Supabase Google girişi aktiv, Google audience In production, native callback əlavə edilib. Son istifadəçi OAuth sınağı ayrıca qalır.
- Giriş: Android Keystore ilə AES-GCM token anbarı, köhnə sessiyanın təhlükəsiz miqrasiyası, paralel refresh kilidi, offline sessiyanın qorunması, Google PKCE/native callback və qonaq seçimi.
- Premium: mağaza paket adı düzəldilib, qiymət yalnız mağaza məlumatından göstərilir. Server doğrulaması və restore saxlanır. Real Play API/base-plan/RTDN ayarları olmadan alış aktiv göstərilmir.
- AdMob: Mobile Ads 25.5.0 + UMP 4.0.0; adaptive native banner ayrıca yer tutur. Oxu/dua/namaz/oyun ekranlarında banner yoxdur. Native server yoxlaması Premium bannerini bağlayır. Əsas paketdə reklam rejimi `off`; ayrıca test APK yalnız Google test ID-ləri ilə yığılıb. Real ID üçün AdMob telefon təsdiqi lazımdır.
- Məxfilik səhifələri yenilənib; istifadəçi hesabları, ibadət qeydləri və köhnə nəticələr silinməyib.

## Yoxlama
93 Node testi keçdi; ümumi regresiya 21 tam quiz raundu və mövcud funksiyaları yoxladı. Native vaxt/DST, bildiriş mətnləri və inset Java testləri keçdi. Android lint: 0 xəta, 11 xəbərdarlıq. AAB bundletool validate, universal APK çevrilməsi, 16KB ZIP alignment və imzalar keçdi; əvvəlki signing sertifikatı saxlanır. 59 mətn asset-i APK ilə eyni hash-a malikdir. Paketdə ELF kitabxanası yoxdur.

Bu Internal testing üçün buraxılış namizədidir. Fiziki Android 10–16 cihaz matrisi, real mağaza satınalma/restore/refund, fon azanı və vidcet cihaz sınaqları tamamlanmış sayılmır. Canlı alış və reklam təsdiqi olmayan halda production-a tam hazır olduğu iddia edilmir.

[Veb](https://mubaristi-create.github.io/basira/?v=1.9#home) · [Admin](https://mubaristi-create.github.io/basira/?v=1.9#cloudadmin) · [APK](https://mubaristi-create.github.io/basira/downloads/SHAMS-1.9.0-play.apk) · [AAB](https://mubaristi-create.github.io/basira/downloads/SHAMS-1.9.0-play.aab)

Lumi Play hesabında Premium məhsulu yaradıldı; illik planın saxlanmasını Console xətası bloklayır. Real satınalma buna və server API/RTDN konfiqurasiyasına bağlı qalır. Production üçün 12 tester/14 gün tələbi hələ ödənməyib (hazırda 10 tester).
