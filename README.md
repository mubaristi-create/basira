# SHAMS 1.5.0

[APK](https://mubaristi-create.github.io/basira/downloads/SHAMS-1.5.0.apk) · [Veb](https://mubaristi-create.github.io/basira/) · [Admin](https://mubaristi-create.github.io/basira/#cloudadmin)

Ortaq Premium ayarları, müddətli sınaq, standart SVG ikonlar, yeni loqo və dua paylaşımı: [RELEASE-1.5.md](RELEASE-1.5.md). Aşağıdakı əvvəlki versiya qeydləri həmin sənədlə tamamlanır.

# SHAMS 1.4.0

Yeni APK: [SHAMS-1.4.0.apk](https://mubaristi-create.github.io/basira/downloads/SHAMS-1.4.0.apk). Dəyişikliklər, sınaqlar və hədlər: [RELEASE-1.4.md](RELEASE-1.4.md).

# Shams

## SHAMS 1.3

Real azan, paylaşma, bayram/Ramazan namazları, canlı Supabase hesabı və tətbiq admin paneli əlavə edilib. Android APK və mənbə arxivi mövcuddur. Cari quraşdırma, SMTP məhdudiyyəti, testlər və Android məlumatı: [CLOUD-ANDROID.md](CLOUD-ANDROID.md). Aşağıdakı əvvəlki versiya qeydlərinin bulud/APK hissələri bu sənədlə əvəz olunur.


Telefon ekranları üçün Quran, dua, zikr, namaz və Ramazan veb tətbiqi.

- Göndərilmiş Shams loqosu bütün 6 temanın rənglərinə uyğunlaşır.
- 5 dil: Azərbaycan, türk, rus, ingilis, ərəb (RTL). İlk girişdə cihazın dili seçilir.
- 10 mərhələli tanışlıq; Daha çox → Tanışlığı yenidən başlat. Ad və seçimlər yalnız cihazda saxlanılır.
- Hənəfi və Cəfəri üçün ayrı, insan anatomiyasına yaxın namaz təsvirləri və addım-addım izahlar.
- Ramazan: sahur/iftar saatları, dairəvi geri sayım, əvvəlki illər üçün oruc qeydləri, gün sayı və iftar duası. Ümmül-Qura təqvimi yerli ay müşahidəsinə görə fərqlənə bilər.
- Axtarılan 17 dua, tam Ayətəl-Kürsi, yeməkdən əvvəl/sonra dualar. Günün duası yerli tarixlə kitabxanadan seçilir.
- Muncuq səsi və titrəyişlə təsbeh, dünya şəhərləri üçün namaz vaxtları və statistika. Ayrı oruc təqvimi Ramazan jurnalında birləşdirilib.
- SHAMS Premium: illik USD $3.60 baza planı, Play-dən lokal qiymət, server doğrulaması və təsdiqlənmiş xalis gəlirin 20%-lik xeyriyyə fondu. Real aktivləşdirmə üçün [PREMIUM-SETUP.md](PREMIUM-SETUP.md).

## Lokal açılış

Node.js 24+: `npm start`. Yoxlama: `npm test`. Əlavə paket tələb olunmur. Məzmun JSON-larını dəyişdikdə `npm run build` işlədin.

## GitHub Pages

Settings → Pages → Source: GitHub Actions. Actions → Deploy to GitHub Pages → Run workflow. Statik fayllar `dist/` qovluğundadır. Repo adının basira olması saxlanılıb ki, mövcud keçid dəyişməsin.

## Saxlanma

Şəxsi cavablar, namaz və oruc qeydləri localStorage-dadır; analitikaya göndərilmir. Yeni şəhər/namaz vaxtları, Quran mətnləri və audio üçün internet lazımdır. İlk HTTPS açılışından sonra əsas bölmələr və dualar oflayn işləyir. Veb versiya kilit ekranını dəyişmir. Bildirişlər tətbiq açıq olduqda işləyir.

## Yoxlama

22 bölmə, 10 namaz ardıcıllığı, 5 dildə tanışlıq, 6 tema, yaddaşdan bərpa, oruc qeydləri, saat qurşaqları, yay/qış vaxtı, sayğac mərhələləri və dua axtarışı yoxlanılır. Fiziki telefon titrəyişi ayrıca cihaz dəstəyi tələb edir.

Visual asset provenance and final ImageGen prompts: [ASSETS.md](ASSETS.md).


## Yeni modullar

Dua Kitabım, 80 suallıq İslam Bilik Oyunu və Allahın 99 Adı beş dildə əlavə olunub. Altı cosmic tema, karusel və sürüşdürmə ilə keçidlər yenilənib. Adlar üçün yoxlanmış lisenziyalı audio olmadığından səs əlavə edilməyib. Ətraflı fayllar, məzmun mənbələri, yaddaş miqrasiyası, testlər, hədlər və Android PWA quraşdırılması: [INTEGRATION.md](INTEGRATION.md).



## Premium serveri

`node backend/server.cjs` tətbiq + API-ni eyni origin-də açır; admin `/admin.html`-dədir. Backend və admin əvvəllər mövcud deyildi. Google Play üçün Android TWA/AAB, real məhsul, xidmət hesabı və HTTPS server sazlanmalıdır; GitHub Pages statik olduğundan backend-i işlətmir. `node --test backend/premium.test.cjs` yeni təhlükəsizlik və maliyyə testləridir. Şəxsi dualar kimi əvvəlki qeydlər localStorage-da qalır; Premium/fond yalnız serverdə saxlanır.
