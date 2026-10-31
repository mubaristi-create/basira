# Allahın 99 Adı — content provenance

Dataset: `dist/names-data.js`.

## Enumeration used

The module follows the traditional name list recorded at [Jamiʿ at-Tirmidhi 3507](https://sunnah.com/tirmidhi:3507). It has **99 entries including Allah as entry 1**, and does **not** add al-Ahad as an extra entry. All Arabic entries were compared against that source, with normal modern vowel/hamza orthography. This makes the set explicit rather than silently mixing competing lists.

The source labels the name-enumerating narration **Da’if (weak)**. It is therefore described as a traditional enumeration, not as an authenticated verbatim Prophetic list. [Sahih al-Bukhari 2736](https://sunnah.com/bukhari:2736) is given as a separate reference for the general ninety-nine-names narration; it does not enumerate the names.

The official [Diyanet Altıeylül discussion](https://balikesir.diyanet.gov.tr/altieylul/sayfalar/contentdetail.aspx?ContentId=1014&MenuCategory=Kurumsal) was consulted for religious-authority context. Its displayed sequence contains both Allah and al-Ahad despite its ninety-nine heading, so that page was **not** used blindly as a 99-row data source.

## Meanings and explanations

Meanings are concise original editorial glosses in Azerbaijani, Turkish, Russian, English and Arabic, not verbatim translations from a published translation. Explanations restate the indicated meaning as a brief educational definition; they do not invent rewards, ritual counts, medical benefits, or a verse reference for every individual name.

`reviewed: true` records a text/list/source comparison, **not** a hadith-authentication judgment or a claim of review by a qualified theologian. The UI source note makes that distinction in all five supported languages. A qualified religious editor can extend or revise the explanatory glosses separately from application code.

## Audio

No name recording with both verified pronunciation and verified reuse rights was identified. All entries intentionally have `audio: null`; the UI should present a clear unavailable state rather than synthesizing a pronunciation or claiming a playable recording.

## Checks performed

- JavaScript syntax check passed.
- Exactly 99 entries, consecutive IDs 1–99.
- 99 distinct Arabic strings and 99 distinct Latin labels.
- Five nonempty localized meanings and explanations for every entry.
- Every entry has an explicit source reference/URL and `audio: null`.
