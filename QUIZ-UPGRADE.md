# Bilgi Oyunu — tarixçə və sual bankı

## Audit

Bankda **80** mövcud mənbə yoxlamalı sual var, 500 deyil. Köhnə kateqoriyalar hər biri 10 sualdan ibarət idi. Yeni səkkiz mövzu: Quran 10, peyğəmbərlər 10, tarix 10, namaz 10, Ramazan 10, İslamın əsasları 10, ümumi biliklər 20, **hədislər 0**. Hədis bölməsi təsdiqlənmiş məzmun gələnədək boş göstərilir.

Mətn/variant uyğunluğu, ID və cavab açarı yoxlamalarında 80 qeyddə struktur xətası, dəqiq mətn dublikatı və eyni mənbə+cavab namizədi tapılmadı (`QUIZ-AUDIT.json`). Bu, bütün mümkün parafrazların semantik cəhətdən fərqli olmasının və ya beş dilin peşəkar redaktor tərəfindən sertifikatlaşdırılmasının sübutu deyil. Yeni məzmun üçün mənbə və ana dil redaktoru yoxlaması tələb olunur. Dini hökm və ixtilaflı məsələlər üçün ayrıca təsdiq/resolution sahəsi var.

## Davranış

- Sessiyada ID, mətn və `concept_id` təkrarlanmır. Əvvəl göstərilməmiş suallar çətinlikdən üstün prioritet alır. Sonra ən köhnə göstərilənlər seçilir; səkkiz kateqoriya balanslaşdırılır. Uyğun hovuz 10 sualdan azdırsa qısa oyun, sıfırdırsa açıq boş vəziyyət verilir.
- Çətinlik Asan/Orta/Çətindir. İstəyə görə son beş nəticəyə uyğun səviyyə tövsiyə olunur. Köhnə dördüncü səviyyə/nəticələr silinmir.
- Variantlar Fisher–Yates ilə qarışdırılır; nəticə ekrandakı A/B/C/D mövqeyi ilə deyil, dəyişməz option ID ilə yoxlanılır. Server xalları ayrıca yoxlayır, client xal miqdarı göndərmir. Başlamış round üçün cavab açarı snapshot-ı saxlanır.
- Yalnız faktiki göstərilən sual `shownAt`, cavab verilən sual `answeredAt` alır. Sessiyada sualın əvvəlcədən seçilməsi onun göstərilməsi sayılmır. Köhnə server round-larında fərdi göstərilmə qeydi olmadığı üçün əvvəl təyin edilmiş suallar konservativ olaraq tarixçəyə daxil edilir.
- `shams-quiz` nəticələri qorunur. Yeni `shams-quiz-v2:<account UUID>` və `...:guest` profillərində tarixçə, bitməmiş sessiya, göndərilməmiş idempotent hadisələr və şəxsi səs seçimi ayrıdır. Hesab dəyişəndə bitməmiş sessiya bərpa olunur. Köhnə yerli tarixçəni hesaba birləşdirmək ayrıca düymə ilə olur.
- Şəbəkə xətasında outbox silinmir; online/login/növbəti girişdə təkrar sinxronlaşdırılır. Gec gələn server cavabı yeni yazılmış hadisələri silmir. Baza sahib UUID-sini `auth.uid()` ilə müqayisə edir. Tarixçə xalları dəyişmir.
- Tətbiq bağlanarkən localStorage-a yazılmış hərəkətlər saxlanır; yaddaş dolarsa xəta göstərilir, əvvəlki qeydlər təmizlənmir. Server kataloqu IndexedDB-də saxlanır. Bloklanmış keş oyun başlanmasını dayandırmır; şəbəkə yoxdursa mövcud təsdiqlənmiş paket/keş istifadə olunur. Sinxron əlaqəsi olmayan iki cihaz həmin an bir-birinin yeni hadisələrini bilmədiyi üçün cihazlararası təkrarsızlıq yalnız sinxronlaşmış tarixçə qədər təmin olunur.
- Beş dil tamlığı yoxlanılır; çatışmayan dil Azərbaycan dili ilə səssiz əvəz edilmir. Ərəb oyun ekranı açıq `dir=rtl` alır. Cavabdan sonra izah, mənbə, düzgün cavab, nəticə və səhv bildirmə var. Səs istəyə görə söndürülür.

## 500–5000 sualın genişləndirilməsi

500 və 5000 qeyddən ibarət **yalnız avtomatik test üçün yaradılmış** banklar yoxlanılır; bunlar istifadəçilərə göndərilmir. Mənbəsi yoxlanmamış 420 sual uydurulmayıb.

Admin panelinə “Sual bankı və bildirişlər” bölməsi əlavə edilib. Yeni suallar JSON massividir; kodu dəyişmədən import edilir. Vacib sahələr:

`id`, `category`, `topic`, `tier` (1–3), `difficulty` (legacy 1–4), `concept_id`, `question`, `options` (4), `option_ids` (4 fərqli sabit ID), `correct`, `correct_option_id`, `explanation`, `source_reference`, `source_url`, `active`, `reviewed`, `review_status`, `review`, `translation_review`.

Aktiv yeni sual üçün `review_status=approved`, `review.source_checked=true`, reviewer və tarix, həmçinin `translation_review.az/tr/ru/en/ar=true` lazımdır. İxtilaflı sualda `controversial=true` və yazılı `review.resolution` tələb olunur. Bunlar insanın faktiki yoxlaması barədə attestasiya sahələridir; proqram dini həqiqəti mətnə baxıb avtomatik təsdiq etmir. Admin serverdə də yoxlanır və import auditə yazılır. Mövcud ID üçün option ID-ləri dəyişdirilə bilməz; belə halda yeni question ID yaradılmalıdır.

`prepare-content.cjs` / `prepare-quiz.cjs` fayl əsaslı müəllif axınını da yoxlayır. Əvvəlki 80 sualın fakt/variant/mənbə məzmunu `legacy-quiz-review.json` fingerprint-i ilə qorunur; dəyişdirilmiş və ya yeni qeydin legacy flag ilə səssiz aktivləşdirilməsinə yol verilmir. `content-schema.json` müqavilə, runtime/server validatorları isə əsas yoxlamadır.

## Server və sınaq

- `20261108_quiz_history.sql` və `20261108_quiz_payloads.sql`: əlavə cədvəllər, RLS, sahibə bağlı sync, server round seçimi, immutable cavab ID-ləri, import və admin bildirişləri. Cədvəllərə anonim/authenticated birbaşa SELECT/INSERT hüququ verilmir.
- `quiz-upgrade-deploy.sql`: eyni sxem + mövcud 80 payload-un bir tranzaksiyada yerləşdirilməsi.
- `check-quiz-upgrade.sql`: rollback ilə istifadəçi izolyasiyası, seen/answered fərqi, idempotency, gecikmiş event, təkrarsız round, boş hovuz, cavab snapshot-ı, admin-only import/report və review gate sınaqları. Daimi test hesabı və ya demo liderlik xalı yaradılmır.
- `quiz-upgrade.test.cjs`: browser VM və pure engine testləri. Mövcud `features.test.cjs`, `check.cjs` və Premium testləri də saxlanılıb.

Yeni mənbə kodu və safe-area düzəlişi bu mərhələdə lokal baxış üçündür; canlı veb/APK yeniləməsi ümumi audit planının buraxılış mərhələsində aparılacaq.

Yeni hesabın statistika, səhv sual və nəticə görünüşü başqa hesabın yeni round-larını saymır. Köhnə sahib etiketi olmayan cihaz nəticələri qonaq irəliləyişi kimi saxlanır və açıq birləşdirmə seçimi ilə hesaba aid edilə bilər. Gecikmiş ranked-score cavabı yalnız uyğun round-u ən son state-ə birləşdirir, yeni hesabın sessiyasını/nəticəsini köhnə snapshot-la əvəz etmir. Qonaq sual bildirişi əvvəlcə cihazda qalır; daxil olduqdan sonra ayrıca göndərmə düyməsi ilə adminə ötürülür.

Final verification (2026-11-09): 86 automated tests passed, zero failed; broad regression passed 21 full quiz rounds. Newly completed rounds keep compact references and answer keys; the active/last session retains review snapshots. Existing archives are preserved. The existing managed-module offline lease is unchanged: starting a gated game may require a connection after expiry, while history and pending sync remain stored.
