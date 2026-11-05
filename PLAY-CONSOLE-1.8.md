# SHAMS — Play Console 1.8 hazırlığı

**Yüklənəcək fayl: `SHAMS-1.8.0.aab`**. APK lokal quraşdırma üçündür. Tətbiq adı SHAMS, əlaqə `mubaristi@gmail.com`. Paket ID-si `app.shams.mobile`, versionCode **18**, target API **36**, min API **26**.

## Hazır materiallar

- `SHAMS-PlayConsole-1.8.zip`: AAB, 512×512 orijinal loqo, 1024×500 feature graphic, telefon ekran şəkilləri, mağaza mətnləri, release notes və texniki yoxlama nəticəsi. ZIP-in özünü Console-a yükləməyin; içindəki AAB-ni Internal testing bölməsinə yükləyin.
- Məxfilik URL-si: https://mubaristi-create.github.io/basira/privacy.html
- Hesab silmə URL-si: https://mubaristi-create.github.io/basira/deletion.html
- Qaydalar: https://mubaristi-create.github.io/basira/terms.html
- Adi, adminsiz reviewer hesabı hazırlanıb. E-poçt və şifrə yalnız kompüterdəki **`outputs/nur/private-data/play-reviewer.json`** faylındadır. Bu fayl GitHub-a və ictimai arxivlərə daxil deyil. App access formasına həmin giriş məlumatlarını özünüz daxil edin; reviewer-ə admin hesabı verməyin. Girişdən sonra Fikir və təkliflər açılır; paylaşım üçün qaydalar checkbox-u tələb olunur.

## Console-da sahibin tamamlayacağı addımlar

1. Düzgün tətbiqi seçin və ya SHAMS yaradın. AAB-ni **Internal testing** track-ə əlavə edin. Console-da əvvəl işlədilmiş versionCode 18 varsa, yeni kod tələb olunur; mövcud Console hesabına bu sessiyada daxil olunmayıb.
2. App signing sertifikatını müqayisə edin. Sideload APK-larımızın istifadəçilərinin məlumatlarını itirmədən Play versiyasına keçməsi üçün **app signing sertifikatı mövcud sertifikatla eyni olmalıdır**. İlk Play App Signing qoşulmasında mövcud açarın rəsmi import/PEPK axınından istifadə edin. Yeni, fərqli app signing açarı seçilərsə köhnə APK-nın üzərinə quraşdırma alınmaya bilər. Məxfi `.p12` və şifrəsini GitHub-a yükləməyin. Upload key və app signing key fərqli anlayışlardır.
3. Store listing mətnlərini və şəkilləri əlavə edin. Kateqoriya təklifi Lifestyle-dır; auditoriya yaşlarını və ölkələri öz hədəfinizə uyğun seçin. Uşaqlara yönəlmə və kontent reytinqi cavabları sahib tərəfindən təsdiqlənməlidir; reytinq uydurulmayıb.
4. App content → Privacy policy, Data safety, App access, Content rating, Target audience və digər Console bəyannamələrini doldurun. Cari paketdə AdMob/reklam SDK-sı və AD_ID icazəsi yoxdur. “Contains ads” yalnız bu paket üçün **No** ola bilər; sonradan reklam əlavə edilərsə yenilənməlidir.
5. `shams_premium_yearly` üçün illik auto-renewing base plan yaradın, USD referansını $3.50 seçin və lokal qiymətləri yoxlayın. Məhsul ID-si server və native kodla uyğun olmalıdır. Real xidmət hesabı icazələri, base-plan ID-si və RTDN qurulması [STORE-SETUP-1.6.md](STORE-SETUP-1.6.md) faylındadır. **Canlı config hazırda ödənişi aktivləşdirmir.** Açarlar uydurulmayıb, real satınalma uğurlu sayılmayıb.
6. License testers və Internal testing linki ilə **Play-dən quraşdırılmış** versiyada satınalma, restore, renewal, cancellation, refund/expiry sınaqlarını tamamlayın. Pre-launch report-u yoxlayın. Qeydiyyat, rəy göndərmə, bloklama, hesab silmə, widget və ekran bağlı halda 10 saniyəlik azan sınağını real telefonda edin. Bu mühitdə emulator accelerator statusu 6 qaytardı; Windows virtualizasiya ayarları dəyişdirilmədi, fiziki cihaz sınağı aparılmayıb.
7. Console-un hesab tipiniz üçün tələb etdiyi qapalı test və production-access mərhələlərini tamamlayın. Göndərilən azan audiosu və loqonun mağazada yayımı üçün hüquqlarınızı təsdiqləyin; lisenziya sübutu uydurulmayıb.

## Data safety üçün faktlara əsaslanan qaralama

Bu cədvəl avtomatik göndərilmiş bəyannamə deyil; son SDK və Console forması ilə təsdiqlənməlidir.

| Məlumat | Faktiki davranış və məqsəd |
|---|---|
| Ad, e-poçt, hesab ID-si | Supabase Auth və profil; qeydiyyat seçildikdə toplanır, hesab idarəetməsi üçündür. Şifrə adminə görünmür. |
| İstifadəçi məzmunu | Rəy, seçilən açıq ad, şikayət və könüllü şəxsi ehtiyat nüsxəsi. Rəy/ad açıqdır; şikayət adminə, şəxsi nüsxə yalnız sahibinə açıqdır. |
| Tətbiq fəaliyyəti | Giriş və quiz/admin hadisələri, serverdə yoxlanan oyun xalları. Funksionallıq, təhlükəsizlik və liderlik üçündür. |
| Məkan | İcazə ilə könüllü GPS və ya əl ilə şəhər seçimi. Namaz vaxtları/məscid axtarışı üçün xarici xidmətlərə koordinatlar ötürülə bilər. Fon məkan izləməsi yoxdur. |
| Şəxsi dini qeydlər | Varsayılan olaraq yalnız cihazda qalır. İstifadəçi ayrıca razılıqla ehtiyat nüsxə göndərərsə buluda daxil olur; həssas şəxsi məlumat kateqoriyalarını bu davranışa uyğun açıqlayın. |
| Satınalma tarixçəsi | Billing aktivləşdiriləndə məhsul, purchase token və entitlement serverdə yoxlanır. Kart məlumatını SHAMS almır. |
| Texniki SDK məlumatı | Billing 9.1.0 və tranzitiv Google SDK-larının son disclosure/SDK Index məlumatı ilə device identifiers və diagnostics cavablarını təsdiqləyin. Bu audit onları “heç nə toplamır” kimi təsnif etmir. |
| Təhlükəsizlik/silmə | HTTPS, öz hesabına məhdud backend icazələri, tətbiq və vebdən hesab silmə. İstifadəçinin başqa tətbiqə paylaşdığı və başqa cihazda saxladığı nüsxələr ayrıca qala bilər. |

## Texniki sınağın sərhədi

56 Node testi; Deno type-check; canlı SQL rollback və real Auth deletion smoke; brauzer forması failure/retry sınağı; build/signature/bundletool/APK conversion/alignment; 53 paket aktivinin uyğunluğu. Tam Android lint **0 error, 12 warning**: versiya yeniləmə tövsiyələri, köhnə Android-in ignor etdiyi yeni atributlar, tələb olunan WebView JavaScript-i, orijinal launcher assetinin forma/yeri və statik SHAMS etiketi kimi qeyri-bloklayan qeydlər qalır. Tam lint hesabatı lokal `android/build/.../lint-results-release.txt` faylındadır. Android 16 geri jesti problemi düzəldilib; köhnə Android override-ı üçün yalnız həmin yeni native callback-i nəzərə almayan lint qaydasına hədəfli izah əlavə olunub.

Google Play təsdiqi və real Billing testləri bu hesabatda keçmiş kimi göstərilmir.

Rəsmi mənbələr: [API tələbi](https://support.google.com/googleplay/android-developer/answer/11926878), [UGC](https://support.google.com/googleplay/android-developer/answer/9876937), [hesab silmə](https://support.google.com/googleplay/android-developer/answer/13327111), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [bundletool](https://developer.android.com/tools/bundletool), [16 KB](https://developer.android.com/guide/practices/page-sizes).
