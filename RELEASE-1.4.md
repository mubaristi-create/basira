# SHAMS 1.4.0

- Dua Kitabım, İslam Bilik Oyunu və Ramazan panelinə giriş Premium statusuna bağlıdır. Əvvəlki istifadəçi qeydləri silinmir. Gündəlik dualar və namaz təlimatı pulsuz qalır.
- Mövcud real server yoxlaması saxlanılır. Play Billing və maliyyə backend-i canlı sazlanmadığı üçün ödəniş qəbul edilmir və saxta Premium verilmir. Bu statik veb paketində ödənişli məzmun ayrıca serverdən qorunan xidmət deyil; hazırkı məhdudlaşdırma tətbiqin istifadəçi interfeysindədir.
- Ana səhifə karuseli məzmun hündürlüyünə uyğunlaşır. Namaz cədvəlində beş sətrin hamısı kart daxilindədir. Qısa ekranlarda səhifə sürüşdürülə bilər; məzmun kəsilmir.
- Yeni azan: sahibin verdiyi videoplayback.weba, dəyişdirilmədən audio/adhan-user.webm. Təxminən 4 dəqiqədir. Manual pleyer ayrıca qalır. Ümumi açar və fərdi namaz açarları birlikdə tətbiq açıq olduqda vaxtında səslənməni idarə edir. Bağlı APK üçün fon alarmı qurulmayıb. Brauzer səsə avtomatik icazə vermədikdə manual pleyer istifadə olunur.
- “Telefona əlavə et” → “Ekran üçün dualar”: dua seçimi, 1080×1920 PNG, Android sistem pəncərəsi ilə fon seçimi, Android ana ekranına vidcet əlavə edilməsi. Vidcetə toxunanda tətbiq açılır. Seçim mövcud SHAMS vidcetlərində də yenilənir. Kilid ekranında avtomatik üst pəncərə və məcburi mətn göstərilməsi yoxdur; istifadəçi telefonun fon seçimini təsdiqləyir.
- Loqo: sahibin göndərdiyi PNG-nin rəngləri və təsviri dəyişməyib. Əsli icons/shams-original.png-də saxlanır. Kvadrat launcher ikonları proporsiya saxlanaraq hazırlanıb; orijinalın ölçüsü 285×274-dür.
- Android kompas: native rotation-vector; alternativ geomagnetic rotation-vector, sonra accelerometer + magnetometer. Ekran dönüşü və seçilmiş məkanın maqnit meyli nəzərə alınır. Sensorlar bölmədən çıxanda və tətbiq arxa plana keçəndə dayandırılır. iOS sensor icazəsi istifadəçi toxunuşundan soruşulur. Brauzerdə absolute/Apple heading işlədilir; nisbi alpha düzgün şimal kimi təqdim edilmir. Sensor yoxdursa seçilmiş şəhərin qiblə bucağı, şimala görə diaqram və xəritə keçidi qalır. Dəqiq yer yalnız istifadəçinin məkan düyməsi ilə alınır.

## Yoxlama

`node check.cjs`, `node --test features.test.cjs backend/premium.test.cjs`: 27 test və mövcud geniş davranış yoxlamaları. Android SDK ilə build və APK imza v2/v3 yoxlaması keçib. Mobil brauzerdə 350×640 ölçüsündə 4 karusel kartı tam görünür; azan real səslənib (240.021 saniyə); beş namaz sətri kartın sərhədlərindədir. Fiziki telefonda magnetometr, launcher vidceti və sistem fon seçimi ayrıca cihaz sınağı tələb edir.

## Mənbələr

- Android widget pin API: https://developer.android.com/develop/ui/views/appwidgets/discoverability
- Android wallpaper chooser: https://developer.android.com/reference/android/app/WallpaperManager#getCropAndSetWallpaperIntent(android.net.Uri)
- Audio və loqo istifadəçi tərəfindən verilib. Audio üçün ifaçı/lisenziya uydurulmayıb.

Supabase SMTP və Google Play aktivləşdirmə üzrə əvvəlki CLOUD-ANDROID.md / PREMIUM-SETUP.md qeydləri qüvvədədir. Backend sirləri, admin şifrələri və APK imza açarları repoya daxil edilmir.

APK paketləmə yoxlaması: Windows AAPT2-nin nested asset adlarında yaratdığı əks slash-lar imzalamadan əvvəl düz slash-a normallaşdırılır. İmzalanmış APK içində updates.js, yeni azan və yeni loqo əsillərlə SHA-256 üzrə eynidir; bütün ZIP yolları və məxfi faylların olmaması yoxlanıb. Build bu yoxlamanı gələcək paketlərdə də məcburi aparır.
