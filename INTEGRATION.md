# Shams 1.1 — təhvil qeydləri

## Dəyişikliklər

Ana səhifə kompakt karusellə yeniləndi, bütün 6 tema parlaq cosmic rənglərə keçirildi. Alt bölmələr arasında sağa/sola sürüşdürmə, təsbehə muncuq səsi əlavə edildi; titrəyiş saxlanıldı. Ayrı oruc təqvimi Ramazan panelində birləşdirildi: ay/il, yaşıl tutulan gün, sarı buraxılan gün, məcburi səbəb və şəxsi qeyd.

Üç yeni modul beş dildə (az/tr/ru/en/ar) işləyir:

- Dua Kitabım: 17 hazır dua, şəxsi dua yarat/redaktə/təsdiqlə sil, axtarış, kateqoriyalar, sevimli/gündəlik seçim, gündəlik/həftəlik xatırlatma.
- İslam Bilik Oyunu: 80 mənbəli sual, 8 kateqoriya, 4 səviyyə, 10 suallıq raund, qarışıq variantlar, düzgün cavaba 10 xal, gündəlik sual, tarixçə, nailiyyətlər və səhvlərin təkrarı.
- Allahın 99 Adı: məna/izah/mənbə, axtarış, sevimli/öyrənildi, gündə 3/5/10 planı, yaddaş kartları və iki test rejimi.

## Fayllar və quruluş

| Fayl | Vəzifə |
| --- | --- |
| dist/cosmic.js, cosmic.css | Temalar, karusel, Ramazan jurnalı, sürüşdürmə, muncuq səsi |
| dist/companion.js | Şəxsi dua kitabı, formalar, xatırlatmalar |
| dist/learning.js, modules.css | Oyun və 99 adın məntiqi/interfeysi |
| content-quiz.json, content-names.json | Redaktə edilən beşdilli məzmun |
| prepare-content.cjs, content-schema.json | Məzmun yoxlaması, statik JS generasiyası və gələcək redaktor üçün sxem |
| dist/quiz-data.js, names-data.js | JSON-dan yaradılmış oflayn məlumatlar |
| dist/app.js, enhancements.js | Marşrutlar və geri düymələri |
| dist/index.html, sw.js | Yeni aktivlər və v9 oflayn keş |
| check.cjs | Avtomatlaşdırılmış yoxlamalar |
| NAMES-SOURCES.md, QUIZ-SOURCES.md | Mənbə və dini məzmun qeydləri |

Yeni npm asılılığı yoxdur. Node.js 20+: `npm start`, `npm test`, `npm run build`. Build JSON məzmununu yoxlayır, JS məlumatlarını yaradır və testləri işlədir. Məzmunu JSON-da dəyişin; sonra build edin. Yalnız aktiv və yoxlanmış suallar göstərilir. Hazır admin paneli əlavə edilməyib.

## Yaddaş və miqrasiya

- `shams-dua-book`: dualar, kateqoriyalar və kitabxana seçimləri. Versiya/dəyişiklik nömrəsi; başqa tabda dəyişmiş duanın üzərinə yazma qorunması.
- `shams-dua-reminders`: artıq göstərilmiş yerli xatırlatmalar. Bildirişdə şəxsi mətn göstərilmir.
- `shams-quiz`: raundlar, açılmış səviyyələr, aktiv oyun, gündəlik cavab və variant sırası.
- `shams-names`: öyrənilən/sevimli adlar, plan, kart və test irəliləyişi.
- `shams-fast-journal`: tarixə görə status, səbəb və qeyd. Köhnə `nur-fasts` daxilində yalnız true qeydlər köçürülür; false qeydə alınmamış sayılır. Köhnə məlumat silinmir.
- Səs seçimi mövcud `basira-tasbih` yaddaşındadır. Mövcud namaz və digər qeydlər qorunur.

Bütün şəxsi məlumatlar bu brauzerin localStorage yaddaşındadır. Server hesabı, bulud sinxronizasiyası, SQL miqrasiyası və RLS yoxdur. Eyni cihaz/profili işlədən şəxs qeydləri görə bilər; brauzer məlumatlarını silmək qeydləri silir. Şəxsi mətnlər log və analitikaya göndərilmir. Gələcək server üçün autentifikasiya, istifadəçi sahibliyi və giriş qaydaları ayrıca qurulmalıdır.

## Məzmun və davranış

Səviyyə raund tamamlandıqda açılır. Hər kateqoriyada 10 sual olduğu üçün sonrakı səviyyələrdə həmin bank fərqli sıra ilə istifadə oluna bilər. Bütün kateqoriyalar rejimində seçilmiş çətinlik üstün tutulur. Təkrar cavab və ikiqat xal bloklanır.

99 ad ənənəvi Tirmizi 3507 siyahısına əsaslanır; konkret sadalama rəvayətinin zəif qiymətləndirilməsi tətbiqdə qeyd olunur. Buxari 2736 ümumi 99 ad hədisini dəstəkləyir, konkret siyahını deyil. İzahlar qısa parafrazlardır. Lisenziyalı və tələffüzü yoxlanmış audio olmadığı üçün adlarda səs yoxdur; süni tələffüz əlavə edilməyib. Sonradan audio üçün HTTPS, mənbə, lisenziya və audio_reviewed tələb olunur.

Oruc qeydi şəxsi jurnaldır, dini hökm deyil. Gələcək tarixə qeyd edilmir. Ramazan hesablaması Ümmül-Qura əsaslıdır və yerli ay müşahidəsi fərqlənə bilər.

## Yoxlamalar

Məzmun generatoru və testlər keçir: 22 marşrut, hər iki məktəbin 10 namaz ardıcıllığı, 5 dil, 6 tema, tanışlıq/bərpa, dua CRUD və təhlükəsiz mətn, səbəbli oruc qeydləri, 32 tam oyun raundu, gündəlik cavab kilidi, hər iki ad testi, plan/yaddaş, korlanmış vəziyyətdən bərpa, real pointer dinləyiciləri ilə sürüşdürmə, Web Audio çağırışı, geri-almada səssizlik, şəhər vaxtları/keş/saat qurşaqları.

Brauzerdə 390×844 və 320×568 görünüş, ərəb dili/RTL, dua yarat/redaktə/sil, tam oyun, yeniləmədən sonra gündəlik cavabın qorunması, sevimli/öyrənildi ad, kartlar, ay seçimi və səbəb forması yoxlanılıb. JavaScript xətası müşahidə edilməyib. Fiziki telefon səsi/titrəyişi və cihaz bildirişləri ayrıca cihaz yoxlaması tələb edir.

## Hədlər və Android

Xatırlatmalar yalnız tətbiq açıq olduqda cari dəqiqə uyğun gələndə işləyir; bağlı tətbiq üçün push xidməti yoxdur. Səs istifadəçi toxunuşundan sonra açıla bilər; titrəyiş cihaz/brauzerdən asılıdır. Ödəniş, bulud sinxronizasiyası, kilid ekranına ayə yerləşdirmə və native APK yoxdur.

Android Chrome-da HTTPS keçidini açın → menyu → “Add to Home screen” / “Install app”. İlk açılışı internetlə tamamlayın. Sonra əsas qabıq və bu üç modul oflayn işləyir; yeni şəhər vaxtları və Quran sorğuları internet tələb edir. Səs/titrəyiş/bildiriş icazələrini cihazda yoxlayın; xatırlatma üçün tətbiqi açıq saxlayın. Bu paket PWA-dır; APK üçün ayrıca Android layihəsi və imzalama lazımdır.
