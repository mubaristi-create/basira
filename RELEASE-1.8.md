# SHAMS 1.8.0

“Fikir və təkliflər” bölməsində siyahı sorğusunun `busy` vəziyyəti göndərmə düyməsini bağlı saxlayırdı. Siyahı və göndəriş ayrıldı. Fon yenilənməsi yalnız lenti dəyişir; yazı sahəsi, mətn və fokus yenidən yaradılmır. Xəta mesajı görünür, mətn qorunur və təkrar göndəriş eyni request UUID-si ilə serverdə yalnız bir qeyd yaradır. Hesabsız istifadəçi mətni yaza, daxil olub həmin mətnlə davam edə bilər.

- Paylaşım qaydalarına razılıq serverdə qeydə alınır. Məzmun və liderlik müəllifləri üçün şikayət və bloklama/açma əlavə edildi. Şikayətlər admin panelində görünür; paylaşımı gizlətmək, hesabı məhdudlaşdırmaq və şikayəti tamamlanmış işarələmək mümkündür.
- Məxfilik, istifadə qaydaları və tətbiqsiz hesab silmə səhifələri əlavə edildi. Hesabım bölməsində öz hesabını və əlaqəli bulud məlumatlarını silmə yolu var. Server Auth istifadəçisini özü təsdiqləyir; başqa hesabın ID-si qəbul edilmir. Admin rolu silinmədən əvvəl köçürülməlidir. Yerli silmə seçimi vidcet və native məkan/alarm keşini də təmizləyir. Play abunəliyi ayrıca idarə edilir.
- Android 13+ üçün native geri jesti callback-i, köhnə Android üçün geri düyməsi saxlanıldı. Android 12+ sistem ehtiyat nüsxəsi/cihaz köçürməsi üçün məxfi məlumatların avtomatik çıxarılması bağlandı. Boot receiver yalnız nəzərdə tutulan sistem hadisələrinə cavab verir.
- Paket: `app.shams.mobile`, `versionCode 18`, `versionName 1.8.0`, min API 26, target API 36. Mövcud imza sertifikatı qorunur.

Yoxlama: 56 Node testi, geniş check.cjs, iki native Java sınağı, server kodunun Deno type-check-i, canlı bazada rollback testləri, ayrıca brauzer mühitində yazı → yenilə → bağlantı xətası → təkrar göndəriş (2 cəhd, 1 qeyd), real disposable Auth hesabının qeydiyyat/ehtiyat nüsxə/silinmə sınağı. İctimai lentə test rəyi göndərilmədi. Android tam lint: 0 error, 12 qeyri-bloklayan xəbərdarlıq. Rəsmi bundletool AAB validation, AAB-dən imzalı APK yaratma, imza və ZIP alignment yoxlamaları keçdi. Paketdə native `.so` yoxdur; Java-only paket 16 KB ELF hizalama problemindən asılı deyil.

Mağazaya texniki yükləmə üçün AAB hazırdır. Google Play Production təsdiqi, real cihaz/Pre-launch report və real mağaza satınalması bu lokal yoxlamaların əvəzi deyil. Real Play xidmət hesabı/base plan/RTDN məlumatları hələ sahib tərəfindən daxil edilməlidir. [Play Console hazırlığı](PLAY-CONSOLE-1.8.md).
