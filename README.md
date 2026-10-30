# Shams

Telefon ekranları üçün Quran, dua, zikr, namaz və Ramazan veb tətbiqi.

- Göndərilmiş Shams loqosu bütün 6 temanın rənglərinə uyğunlaşır.
- 5 dil: Azərbaycan, türk, rus, ingilis, ərəb (RTL). İlk girişdə cihazın dili seçilir.
- 10 mərhələli tanışlıq; Daha çox → Tanışlığı yenidən başlat. Ad və seçimlər yalnız cihazda saxlanılır.
- Hənəfi və Cəfəri üçün ayrı, insan anatomiyasına yaxın namaz təsvirləri və addım-addım izahlar.
- Ramazan: sahur/iftar saatları, dairəvi geri sayım, əvvəlki illər üçün oruc qeydləri, gün sayı və iftar duası. Ümmül-Qura təqvimi yerli ay müşahidəsinə görə fərqlənə bilər.
- Axtarılan 17 dua, tam Ayətəl-Kürsi, yeməkdən əvvəl/sonra dualar. Günün duası yerli tarixlə kitabxanadan seçilir.
- Animasiya ilə təsbeh, dünya şəhərləri üçün namaz vaxtları, oruc təqvimi və statistika.
- Shams Pro $1.99 təqdimatı və yardım mətni; ödəniş provayderi qoşulmayıb.

## Lokal açılış

Node.js 20+: `npm start`. Yoxlama: `npm test`. Kitabxana quraşdırmağa və build etməyə ehtiyac yoxdur.

## GitHub Pages

Settings → Pages → Source: GitHub Actions. Actions → Deploy to GitHub Pages → Run workflow. Statik fayllar `dist/` qovluğundadır. Repo adının basira olması saxlanılıb ki, mövcud keçid dəyişməsin.

## Saxlanma

Şəxsi cavablar, namaz və oruc qeydləri localStorage-dadır; analitikaya göndərilmir. Yeni şəhər/namaz vaxtları, Quran mətnləri və audio üçün internet lazımdır. İlk HTTPS açılışından sonra əsas bölmələr və dualar oflayn işləyir. Veb versiya kilit ekranını dəyişmir. Bildirişlər tətbiq açıq olduqda işləyir.

## Yoxlama

19 bölmə, 10 namaz ardıcıllığı, 5 dildə tanışlıq, 6 tema, yaddaşdan bərpa, oruc qeydləri, saat qurşaqları, yay/qış vaxtı, sayğac mərhələləri və dua axtarışı yoxlanılır. Fiziki telefon titrəyişi ayrıca cihaz dəstəyi tələb edir.

Visual asset provenance and final ImageGen prompts: [ASSETS.md](ASSETS.md).
