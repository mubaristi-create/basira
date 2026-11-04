# SHAMS 1.7.0

- Məscidlər seçilmiş əraziyə görə məsafə sırası ilə göstərilir. Məsafə ərazi/axtarış mərkəzindən düz xətt üzrədir. Adına toxunduqda Waze, Google Maps və Apple Maps seçilir.
- Quran: hər surənin ayrıca yaşıl “Oxundu” işarəsi; hər surədə bir ayə üçün “Burada qaldım” işarəsi və davam düyməsi. İşarələr cihazda saxlanır, yalnız istifadəçinin seçdiyi şəxsi bulud ehtiyat nüsxəsinə daxil olur.
- Ramazan: qeyd edilmiş buraxılmış Ramazan günləri üçün qalıq qəza və “Qəzasını tutdum” seçimi. Könüllü oruclar qəza sayına daxil deyil. Bu şəxsi gündəlikdir, dini hökm deyil.
- Qədr gecələri: Hənəfi/Sünni və Cəfəri/Şiə seçimi, il seçimi, təqvimdə qızılı çərçivə, əvvəlki günün axşamında başlanma tarixi və mənbəli ibadət xülasəsi. Təqvim Ümmül-Quradır; yerli hilal müşahidəsi fərqlənə bilər. Mənbələr tətbiqdə Diyanet, Al-Khoei Foundation, Sistani və Tirmidhi 3513 keçidləridir.
- “Fikir və təkliflər”: hamıya açıq, səhifələnən rəy lenti; qeydiyyatlı istifadəçi fikir yazır. Admin cavab, Planda var/Hazırlanır/Tezliklə/Tamamlandı statusu və gizlətmə seçimini cloudadmin panelindən idarə edir. Şəxsi məlumat paylaşmamaq xəbərdarlığı var; şəxsi dua və qeydlər buraya göndərilmir. Açıq səhifə 30 saniyədə yenilənir.
- Liderlik: ana səhifə karuselinin yeni dördüncü paneli və Daha çox menyusu. Açıq adla könüllü qoşulma/çıxma; ilk üçlük podiumu və real istifadəçi xalları. Saxta iştirakçı yoxdur. Hər düzgün cavab 10 xal, bir suala UTC günü ərzində bir kredit; gündə ən çox 10 reytinq oyunu. Server sualları təyin edir, cavabları yoxlayır, eyni raundu ikinci dəfə hesablamır. Yerli məşq və köhnə tarixçə sıralamaya köçürülmür. Premium modul siyasəti serverdə də qorunur.
- 80 Azərbaycan dilində sual daha aydın yenidən yazıldı. Mənbə, izah və beş dil saxlanıldı; iki qeyri-təbii cavab dəsti beş dildə düzəldildi. Variantların ilkin mövqeləri bütün dillərdə uyğun dəyişdirildi; hər oyunda da qarışdırılır.
- Android: azan zamanı dilə uyğun, ardıcıl təkrarlanmayan təsadüfi namaza çağırış bildirişi. Bildiriş səs bitdikdən sonra da oxunmaq üçün qalır. Mövcud alarm və istifadəçinin göndərdiyi azan audiosu qorunur.
- Supabase “Confirm email” istifadəçinin ayrıca təsdiqi ilə söndürülüb. Yeni hesablar dərhal daxil olur. Admin hüququ yalnız mövcud admin UUID-lərinə bağlıdır; e-poçta əsaslanan avtomatik admin yüksəltməsi söndürülüb. Rəy yazma həddi saatda 5-dir; maliyyə və digər RLS icazələri dəyişməyib.

Yoxlama: 49 Node testi, geniş check.cjs, canlı bazada rollback ilə kredit/təkrar/hesab sahibliyi/özəl cədvəllər/moderasiya sınaqları, Android build və imza/fayl uyğunluğu. Fiziki telefonda fon azanı və istehsalçı batareya məhdudiyyətləri ayrıca cihaz testi tələb edir. Mağaza ödənişləri üçün 1.6 quraşdırma sənədindəki real açarlar hələ lazımdır.

Admin: Hesabım → mövcud mubaristi@gmail.com hesabı → Tətbiq idarəetməsi. İdarəetmə dəyişiklikləri eyni Supabase-dən APK və vebə gəlir. Rəylərin yenilənməsi 30 saniyəyə qədər çəkə bilər; Yenilə düyməsi dərhal sorğu göndərir.
