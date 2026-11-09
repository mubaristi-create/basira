# SHAMS — Yoxlama nəticələri, 9 noyabr 2026

## Səbəb və dəyişikliklər
Əvvəlki bank 80 sualdan ibarət idi. 10 suallıq raund seçimi davamlı, hesab üzrə göstərilmə tarixçəsinə əsaslanmırdı; buna görə yeni oyunlarda eyni suallar tez qayıdırdı. Yeni seçim əvvəl göstərilməmiş sualları önə çəkir, sessiyada ID/məzmun təkrarını bloklayır, cavabları sabit identifikatorlarla qarışdırır.

## Yoxlamalar
- Node avtomatik testləri: **86/86 keçdi**, 0 uğursuz, 0 buraxılmış.
- Ümumi regresiya: 21 tam quiz raundu və mövcud funksiyaların yoxlamaları keçdi.
- Android assembleRelease + lintRelease: BUILD SUCCESSFUL, 0 lint xətası, 12 xəbərdarlıq.
- Java InsetsBounds: 6 sərhəd/klaviatura/naviqasiya testi keçdi.
- Supabase rollback testləri: hesab izolə edilməsi, RLS, idempotent tarixçə, görünmə/cavab ayrılığı, server qiymətləndirməsi, yeni sual prioriteti və redaksiya qapısı keçdi. Test hesabları və xallar commit edilmədi.
- Canlı kataloq: HTTP 200, 80 sual. Anonim özəl tarixçəyə giriş: HTTP 401.
- Brauzer: 10 fərqli suallıq tam oyun; nəticə 2 doğru/8 səhv, yenidən oyunda yeni sual. Ərəb dili 320px RTL və ingilis dili 360px yoxlanıldı.
- Saxlama: offline növbə, hesab dəyişməsi, gec server cavabı, yaddaş kvotası, yarımçıq sessiya və kompakt arxiv testləri keçdi.

## Sual bazası
Quran 10; peyğəmbərlər 10; İslam tarixi 10; namaz 10; Ramazan 10; əsaslar 10; ümumi 20; hədis 0. Mövcud 80 sual qorundu. 500 və 5000 sətrlik struktur sintetik test məlumatı ilə yoxlanıldı; bu məlumatlar istifadəçilərə təqdim edilmir. Yeni dini məzmun mənbə və beş dil üzrə redaksiya təsdiqi olmadan aktivləşmir. Avtomatik oxşarlıq yoxlaması bütün parafrazları sübut etmir; redaksiya yoxlaması tələb olunur.

## Dəyişdirilmiş əsas fayllar
- Quiz: dist/quiz-engine.js, dist/quiz-upgrade.js, dist/quiz-upgrade.css, dist/learning.js.
- Məzmun: content-quiz.json, content-schema.json, legacy-quiz-review.json, dist/quiz-data.js, prepare-content.cjs, prepare-quiz.cjs.
- Backend: supabase/migrations/20261108_quiz_history.sql, 20261108_quiz_payloads.sql, supabase/quiz-upgrade-deploy.sql və SQL yoxlama skriptləri.
- Android/layout: MainActivity.java, InsetsBounds.java, InsetsBoundsTest.java, dist/safe-layout.js, dist/safe-layout.css; index/app/service-worker qoşulmaları.
- Yoxlamalar: check.cjs, features.test.cjs, quiz-upgrade.test.cjs, package.json.
- Hesabat: AUDIT-PLAN-2026-11-08.md, QUIZ-UPGRADE.md, QUIZ-AUDIT.json, QUIZ-LIVE-CHECK.json.

## Buraxılış və məhdudiyyətlər
Quiz backend yeniləməsi Supabase-də tətbiq edildi. Frontend və Android dəyişiklikləri lokal baxış üçündür; GitHub/web buraxılışı və yeni Play AAB yayımlanmayıb. Mövcud SHAMS-1.8.2-play.aab dəyişməyib (SHA256: 5ce363cd656e84585f606664477637f97457f68632b666ca349c7f3f5d877af6).
Fiziki Android 10–16 cihaz matrisi, real mağaza alışları və iki fiziki cihaz arasında sinxronizasiya sınağı aparılmayıb. AdMob, Billing və autentifikasiyanın sonrakı audit mərhələləri təsdiqdən sonra davam edəcək.
