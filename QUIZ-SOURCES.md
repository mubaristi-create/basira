# Shams quiz content audit

Source-check date: 31 October 2026. The bank contains 80 educational questions: 10 each for Quran, prophets, history, prayer, Ramadan, culture, names, and general knowledge. Every record contains all five locale keys (`az`, `tr`, `ru`, `en`, `ar`), four distinct options in each locale, an explanation, a precise Quran reference, a public source URL, and explicit `reviewed` / `active` flags.

`reviewed: true` records that the factual answer was checked against the specified Quran passage through Quran Foundation's Quran.com interface. It **does not** represent a fatwa, endorsement by a scholar, or independent scholarly certification. Additional editorial and native-language review is advisable before expanding the bank. The short localized explanations are original paraphrases rather than reproduced published translations.

The bank deliberately avoids school-specific prayer mechanics, calculation methods, health decisions, and disputed legal conclusions. For example, the travel-prayer item asks only which context Quran 4:101 mentions, not the distance or number of days that would entitle an individual to shorten prayer. The fidyah item asks only what kind of aid appears in 2:184 and explicitly separates individual rulings from the quiz.

## Checked passages

- Quran chapter identification: [1:2](https://quran.com/1/2), [97:1–3](https://quran.com/97/1-3), [112:1](https://quran.com/112/1), [2:255](https://quran.com/2/255), [95:1](https://quran.com/95/1), [113:1](https://quran.com/113/1), [103:1](https://quran.com/103/1), [96:1](https://quran.com/96/1), [29:41](https://quran.com/29/41), [91:1](https://quran.com/91/1).
- Prophets: [20:77](https://quran.com/20/77), [11:36–37](https://quran.com/11/37), [37:142 and its Yunus context](https://quran.com/37/142), [12:4](https://quran.com/12/4), [2:127](https://quran.com/2/127), [4:163](https://quran.com/4/163), [19:34](https://quran.com/19/34), [2:31](https://quran.com/2/31), [27:18](https://quran.com/27/18), [19:7](https://quran.com/19/7).
- Quranic history: [3:123](https://quran.com/3/123), [9:25](https://quran.com/9/25), [18:9](https://quran.com/18/9), [7:73–74](https://quran.com/7/73), [11:50](https://quran.com/11/50), [7:85](https://quran.com/7/85), [7:103](https://quran.com/7/103), [28:76](https://quran.com/28/76), [31:13](https://quran.com/31/13), [30:2–3](https://quran.com/30/2-3).
- Prayer: [2:144](https://quran.com/2/144), [5:6](https://quran.com/5/6), [62:9](https://quran.com/62/9), [20:14](https://quran.com/20/14), [7:31](https://quran.com/7/31), [2:45](https://quran.com/2/45), [29:45](https://quran.com/29/45), [2:43](https://quran.com/2/43), [24:58](https://quran.com/24/58), [4:101](https://quran.com/4/101).
- Ramadan: [2:183](https://quran.com/2/183), [2:184](https://quran.com/2/184), [2:185](https://quran.com/2/185), [2:187](https://quran.com/2/187), [97:3](https://quran.com/97/3).
- Social ethics: [4:86](https://quran.com/4/86), [4:58](https://quran.com/4/58), [5:1](https://quran.com/5/1), [17:35](https://quran.com/17/35), [17:23](https://quran.com/17/23), [49:11](https://quran.com/49/11), [49:12](https://quran.com/49/12), [24:27](https://quran.com/24/27), [2:168](https://quran.com/2/168), [7:31](https://quran.com/7/31).
- Divine names: [1:3](https://quran.com/1/3), [59:22–24](https://quran.com/59/22-24), [2:32](https://quran.com/2/32), [2:127](https://quran.com/2/127). Questions use distinct lexical meanings, without teaching a disputed enumeration or treating similar meanings as separate simultaneous answer options.
- General: [2:271](https://quran.com/2/271), [3:92](https://quran.com/3/92), [2:256](https://quran.com/2/256), [4:135](https://quran.com/4/135), [49:13](https://quran.com/49/13), [9:60](https://quran.com/9/60), [82:10–12](https://quran.com/82/10-12), [2:97](https://quran.com/2/97), [2:185](https://quran.com/2/185), [3:185](https://quran.com/3/185).

## Integration contract

The exported global is `const SHAMS_QUIZ`. Canonical correct options are first (`correct: 0`), so the UI must shuffle choices while preserving each choice's original index. The difficulty field is editorial learning metadata. To create ten unique questions for one category at an unlocked level, prioritize that difficulty and fill from the remaining reviewed category records; an exact difficulty-only filter would contain fewer than ten.

Only records where both `active === true` and `reviewed === true` should be served. To withdraw a question, set either flag to false. This structure allows a future authenticated content-management system without shipping unverified draft questions.

## Validation performed

`node --check dist/quiz-data.js` passes. A VM schema check found exactly 80 records, 80 unique IDs, 8 categories with 10 records each, five complete locales per question/option/explanation, four distinct localized answer strings, and no schema errors. Runtime scoring and UI tests belong to the integrating application.
