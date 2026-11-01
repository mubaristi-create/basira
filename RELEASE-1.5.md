# SHAMS 1.5.0

## Görünüş və paylaşım

- Android-də emoji/link şəklində görünən naviqasiya və əməliyyat simvolları asılılıqsız inline SVG-lərlə əvəz edilib. Eyni 24×24 viewBox və 1.8px xətt istifadə olunur. Düymələrin əlçatan adları saxlanılıb. Karusel nöqtələrinin toxunma sahəsi böyüdülüb.
- Dördguşəli parıltı simvolları UI mətnlərindən və CSS pseudo-elementlərindən çıxarılıb. Bilik oyununun nailiyyət işarəsi sadə təsdiq ikonudur.
- “Hənəfi (Sunni)” / “Cəfəri (Şiə)” yazıları beş dildədir; daxili hanafi/jafari identifikatorları və namaz ardıcıllıqları dəyişməyib.
- Son verilən logo-app.png 3000×3000 əsli ilə saxlanılıb (SHA-256 22ff936520e7ffcbf1187ec04535a44435e3f0f7855abd84169ed6a325fb76bf). İlk tanışlıqda yalnız ikon, digər uyğun yerlərdə ikon və ad görünür. Launcher ikonları rəng və proporsiya dəyişmədən kiçildilib.
- Bütün kitabxana dualarında, günün duasında, Ramazan iftar duasında və Dua Kitabım kartlarında paylaş düyməsi var. Seçilmiş dua mətn və 1080×1920 şəkil kimi paylaşılır. Android sistem paylaş pəncərəsi WhatsApp və digər quraşdırılmış tətbiqlərə ötürür; statusu və alıcını istifadəçi seçir. Vebdə Web Share dəstəyi olduqda fayl paylaşılır; əks halda şəkli saxlama və WhatsApp mətn keçidi qalır. Uzun şəxsi dualar tam mətn kimi paylaşılır. Şəxsi qeyd sahəsi, hesab adı, token və ehtiyat nüsxəsi paylaşılmır.

## Admin → Premium bölmələr

Online panel: https://mubaristi-create.github.io/basira/#cloudadmin

Mövcud təsdiqlənmiş admin hesabı ilə daxil olun. Yeni “Premium bölmələr” hissəsində Dua Kitabım, İslam Bilik Oyunu və Ramazan üçün rejim seçilir:

- Pulsuz: hər kəs aça bilir.
- Premium: mövcud server tərəfindən təsdiqlənən Premium statusu tələb olunur.
- Bağlı: Premium istifadəçi də daxil olmaqla bölmə bağlanır.
- Sınaq: 1–365 gün arasında ümumi sınaq; hesabsız testçilər də daxil ola bilir. Vaxt serverdə hesablanır; bitdikdə rejim Premium kimi davranır.

**Saxla** düyməsini basın. APK 1.5.0 və veb eyni Supabase RPC-dən ayarları oxuyur; tətbiq açıq və internet olduğu müddətdə 30 saniyədə, yenidən ön plana gələndə dərhal yoxlayır. Ayar üçün yeni APK hazırlamaq lazım deyil. Əvvəlki APK 1.4 bu yeni sistemi oxumur: 1.5 yeniləməsi quraşdırılmalıdır.

Test məqsədilə ilk miqrasiyada üç modul üçün 1 günlük ümumi sınaq açılıb. Miqrasiyanın təkrar icrası mövcud rejimləri və sınaq müddətini sıfırlamır. Admin onu istənilən vaxt dəyişə bilər. Sınaq ödənişli abunəlik vermir, maliyyə satışına çevrilmir və xeyriyyə fonduna məbləğ əlavə etmir.

## Server və təhlükəsizlik

Miqrasiya: supabase/migrations/20261102_module_access.sql. RLS aktiv private policy cədvəli, məxfi sahələr göstərməyən public oxu RPC-si, yalnız mövcud admin roluna açıq yazı RPC-si. Revision yoxlaması paralel pəncərələrin bir-birinin ayarını səhvən əvəz etməsinə mane olur. Dəyişiklik əvvəl/sonra ilə auditə yazılır. İstifadəçi və anonim rol ayar dəyişə bilmir.

Giriş qərarları 90 saniyəlik server cavabına bağlanır; yerli saatı dəyişmək sınağı uzatmır. Server bağlantısı itərsə bu üç idarə olunan modul ən geci lease bitəndə giriş yoxlaması istəyir. Digər oflayn funksiyalar qalır. Ayarlar UI funksiyalarının girişini idarə edir; APK-dakı lokal funksiyaların mənbə kodunu gizlədən DRM deyil. Google Play ödəniş inteqrasiyasının əvvəlki sazlama tələbləri dəyişməyib.

## Yoxlama

- `node check.cjs`: mövcud geniş davranış və yaddaş yoxlamaları.
- `node --test features.test.cjs backend/premium.test.cjs`: 36 test.
- Canlı Supabase-də `check-modules.sql`: anonim/adi istifadəçi yazısı qadağası, admin auditli dəyişiklik, stale revision, yanlış gün, sınaq expiry; hamısı transaction rollback ilə keçib. İstifadəçi məlumatı və test hesabı qalmayıb.
- Mobil brauzerdə ikonlar, 350px daşma, Sunni/Şiə adları, qeydiyyatsız sınaq girişi və 1080×1920 PNG faktiki yoxlanıb.
- Android SDK build və APK v2/v3 imzası; asset ZIP yolları və fayl SHA-256 yoxlaması. Eyni package id və imza açarı ilə 1.4 üzərinə yenilənir.
- Fiziki cihazda WhatsApp-a göndərmə / status paylaşımı aparılmayıb; alıcı seçmə və göndərmə istifadəçiyə məxsusdur. Kompas/vidcet üzrə əvvəlki cihaz sınağı məhdudiyyəti qalır.

Backend sirləri, şəxsi DB, admin şifrəsi və Android imza açarı repoya daxil edilmir.
