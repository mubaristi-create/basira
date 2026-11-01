# SHAMS 1.3 — azan, paylaşma, xüsusi namazlar, Supabase və APK

## Hazır funksiyalar

- Namaz vaxtları və izləyicidə manual azan düyməsi, dayandırma və yerli audio pleyer. 183 saniyəlik real insan yazısıdır; avtomatik/fon azanı deyil. MP3 və OGG tətbiqə daxil edilib.
- Başlıqda və Daha çox bölməsində paylaşma. Web Share, Android sistem menyusu, WhatsApp/Telegram və keçidi kopyalama. Paylaşma mətni şəxsi qeyd və hesab məlumatı daşımır.
- Namazı öyrən, namaz vaxtları və Ramazan panelindən bayram/Ramazan gecə ibadətinə keçid. Hənəfi və Sistaninin cari Cəfəri təlimatları ayrı göstərilir. Mənbələr: SPECIAL-PRAYERS-SOURCES.md.
- Daha çox → Hesabım: e-poçt/şifrə, təsdiq keçidi, şifrə bərpası, ad, fəaliyyət tarixçəsi və yalnız istifadəçinin razılığı ilə şəxsi ehtiyat nüsxə.
- Daha çox → Tətbiq idarəetməsi: qeydiyyatlar, son girişlər, hesabın bulud girişini məhdudlaşdırmaq/bərpa etmək, əlavələrin fəaliyyət qeydləri, dua/elan redaktəsi və yayımdan çıxarma, admin audit izi. Tarixçələr axtarılır və səhifələnir.

## Canlı Supabase

Free təşkilatında **shams**, project ref `ayaiddowrabrdltrqysn`, EU West (Ireland) yaradılıb. API: `https://ayaiddowrabrdltrqysn.supabase.co`. Yalnız publishable açar `dist/cloud-config.js`-dədir. Secret/service-role açar tətbiqə və APK-yə daxil edilməyib.

Yeddi cədvəldə RLS aktivdir. Admin hüquqları istifadəçinin dəyişə bildiyi metadata-da deyil, Data API-dən gizli `shams_private` sxemindədir. Adi istifadəçi başqa hesabı, ehtiyat nüsxəni və admin funksiyalarını görə/dəyişə bilmir. Tətbiq admini də başqasının şəxsi ehtiyat nüsxəsini oxumur. Sistem səviyyəsində Supabase layihə sahibi ayrıca DB səlahiyyətinə malikdir.

Hesab məlumatı, qeydiyyat/giriş tarixləri və yalnız fəaliyyətin növü/sayı saxlanır. Şəxsi dua mətnləri fəaliyyət loguna yazılmır. Ehtiyat nüsxə manual razılıqla, hesab sahibinin RLS ilə qorunan sahəsinə HTTPS üzərindən göndərilir. Bu, end-to-end şifrələmə iddiası deyil. Sessiya tokenləri ehtiyat nüsxəyə daxil deyil.

Auth Site URL və redirect URL GitHub Pages tətbiqinə sazlanıb. Təsdiq məktubu ilə qayıdan token yoxlanır və URL-dən silinir. Admin üçün istifadəçinin təsdiqlədiyi e-poçt yalnız private DB-də icazələndirilib, mənbə koduna yazılmayıb. Həmin ünvanla **Hesabım → Qeydiyyat**, sonra məktubun təsdiqi və giriş lazımdır. Yerli maliyyə panelinin əvvəlki şifrəsi yeni bulud hesabı şifrəsi deyil.

**İctimai qeydiyyatın qalan sazlaması:** Supabase standart SMTP-si yalnız təşkilat üzvlərinə, saatda 2 məktub həddində sınaq göndərişi edir. Digər istifadəçilər üçün öz SMTP provayderinizi Supabase Authentication → Emails bölməsində qoşun. SMTP hazır olana qədər `registrationReady:false` sınaq bildirişi göstərir. Hazır olduqda bunu true edin və veb/APK-ni yeniləyin. E-poçt təsdiqi təhlükəsizlik üçün söndürülməyib. Mənbə: https://supabase.com/docs/guides/auth/auth-smtp

`supabase/migrations/` cədvəl və funksiyaların mənbəsidir. `supabase-schema.sql` bu miqrasiyaların yeni, boş layihə üçün birləşdirilmiş nüsxəsidir; mövcud layihədə təkrar işə salmayın. `check-rls.sql` və `check-admin.sql` test istifadəçilərini yalnız tranzaksiya daxilində yaradır və rollback edir. Canlı test qeydi/satış saxlanmır.

## Android

`SHAMS-1.3.0.apk`: Android 8.0+, package `app.shams.mobile`, versionCode 13. Offline statik məzmun/audio paketdədir, Quran sorğuları, yeni namaz vaxtları və Supabase üçün internet lazımdır. Native paylaşma, istifadəçi toxunuşu ilə media, seçilmiş fayl yükləmə və istifadəçi razılığı ilə yer icazəsi dəstəklənir. Tətbiq arxa plana keçəndə audio dayanır.

APK v2 və v3 imzası ilə yoxlamadan keçib. Fiziki telefonda/emulatorda tam end-to-end quraşdırma testi bu təhvilin hissəsi kimi aparılmayıb. Bu, Play Store AAB və ya Play Billing aktiv TWA deyil. Əvvəlki Premium server kodu saxlanılıb, real Play açarları olmadan satış açılmır. Hesab/CMS Supabase-də işləyir; mövcud maliyyə SQLite bazası və Google billing serveri avtomatik buluda köçürülməyib.

İmza açarı `private-data/android-signing.p12` və onun parolu lokal qalır; GitHub/ZIP-ə göndərilmir. Gələcək APK yeniləmələrini eyni açarla imzalayın və bu faylları təhlükəsiz ehtiyatlayın.

Yenidən yığmaq üçün repoda Android mənbə ZIP-ini açın (`android/` qovluğu kökdə olsun). Windows PowerShell və Android Studio JBR/SDK lazımdır:

```powershell
./android/build.ps1 -AndroidSdk 'C:/Users/YOUR_USER/AppData/Local/Android/Sdk'
```

Script mövcud SDK 35.0.0 build tools və android-36 platformunu istifadə edir; yeni Gradle/npm asılılığı quraşdırmır. `-Jdk` ilə JBR yolunu verə bilərsiniz. Default SDK/JDK yollarını öz kompüterinizə uyğunlaşdırın. APK-yə download arxivi və private-data daxil edilmir.

## Yoxlama

- Mövcud tətbiqin bütün check.cjs yoxlamaları.
- 15 Premium təhlükəsizlik/maliyyə testi.
- 8 yeni funksiya testi: 5 dil və məzhəb ayrılığı, real audio hash-i, manual playback, paylaşma, tokenlərin backup-dan çıxarılması, restore allowlist, məxfi mətni olmayan fəaliyyətlər, CMS XSS qorunması.
- Canlı Supabase anonymous sorğularında profil/backup/admin yazıları rədd edildi. Authenticated RLS və admin/CMS testləri rollback ilə keçirildi.
- Brauzerdə audio real olaraq 183.49 saniyə müddəti ilə səsləndi və dayandı. Mobil səhifələr ayrıca yoxlanır.

## Mənbə və lisenziya

Azan: Andrewler, [Azan.ogg](https://commons.wikimedia.org/wiki/File:Azan.ogg), CC BY-SA 4.0. OGG orijinaldır, MP3 Wikimedia transkodudur; SHAMS mətn/səs redaktəsi etməyib. Atribut/lisenziya pleyerdə və `dist/audio/LICENSE.md`-də var. Namaz məzmunu üçün SPECIAL-PRAYERS-SOURCES.md-yə baxın.
