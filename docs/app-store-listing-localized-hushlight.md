# App Store listing — the localized fields

Backlog HL-010. Companion to `app-store-listing-hushlight.md`, which holds the
English listing and the reasoning every field below inherits. **Proposals: the
listing needs Christian's approval and App Store Connect is a hard gate.**

## Round 2: no price words, anywhere in the three fields

App Review round 2 (2026-09-09) rejected the subtitle under Guideline 2.3.7 — *"references
to free or discounted services are considered a price reference and are not appropriate
for app metadata."* Every subtitle below had led with its language's word for free. They
now lead with its word for **private**, which is the differentiator the other two were
always in service of, and `scripts/lint-store-metadata.sh` refuses a price word in the
title, subtitle or keywords of any storefront. The description may still say free; Apple
says so in the same message.

## What is settled here, and what is not

The three fields below **interlock and cannot be cut separately**. Apple indexes
title, subtitle and keywords as one set, so a term in the title is already earning
its search and repeating it in the keyword field buys nothing — which is why the
English field spends its 100 characters on `labor,labour,birth,…` and never says
"contraction" or "timer". Each locale is cut the same way: the category term goes
in the **title** (the weighted field), the subtitle carries the three
differentiators no competitor can copy, and the keyword field spends what is left
on the vocabulary a reader actually types.

**The keywords are unvalidated, and that is stated rather than buried.** They come
from category vocabulary in each language, not from search-volume data: there is no
ASO tool here and buying one is the money gate. What they are *not* is machine
translation of the English list — a translated `overdue` earns nothing in Japanese,
where the search is `予定日` and `臨月`. Treat them as a well-reasoned first cut to
be measured against real impressions after 1.0 ships, which is the only honest way
to validate a keyword field anyway.

## Storefronts are not languages

The app ships nine languages; the listing needs more entries than that, because
Apple splits some languages by storefront while the app does not:

| App language | Listing entries |
|---|---|
| en | en-US, en-GB, en-AU, en-CA — one copy, British spelling for GB/AU |
| es | **es-ES and es-MX**, cut separately (see below) |
| fr | **fr-FR and fr-CA** |
| de, it, pt-BR, ja, ko, zh-Hans | one each |

Fourteen listings, not nine. The `es-MX` split is the one that earns its keep:
Latin America is a large storefront for this category and it does not search in
Peninsular Spanish.

---

## es-ES

**Title** (25/30)
> Hushlight - Contracciones

**Subtitle** (28/30)
> Privada, offline, sin cuenta

**Keywords** (97/100, comma-separated, no spaces)
> parto,embarazo,matrona,dilatación,doula,511,nacimiento,bebé,prenatal,cronómetro,contador,gestante

*`matrona` is the Spanish word for a midwife; Latin America says `partera`, which is why es-MX is cut separately below rather than sharing this field. `dilatación` is what a first-time mother is actually told to watch, and it is not a word the app itself uses.*

---

## es-MX

**Title** (25/30)
> Hushlight - Contracciones

**Subtitle** (28/30)
> Privada, offline, sin cuenta

**Keywords** (97/100, comma-separated, no spaces)
> parto,embarazo,partera,dilatación,doula,511,nacimiento,bebé,prenatal,cronómetro,contador,obstetra

*Identical to es-ES except `matrona`→`partera` and `gestante`→`obstetra`. Two storefronts, one app language: the catalog ships a single `es`, so this is a listing split, not a translation split. Mexico and the wider Latin American storefront are worth the separate cut — this category searches in local vocabulary, not in Peninsular Spanish.*

---

## fr-FR

**Title** (24/30)
> Hushlight - Contractions

**Subtitle** (30/30)
> Sans compte, hors ligne, privé

**Keywords** (91/100, comma-separated, no spaces)
> accouchement,grossesse,sage-femme,travail,minuteur,bébé,terme,doula,maternité,511,naissance

*`travail` is the clinical word for labour and carries the search on its own; `accouchement` is the birth itself. `sage-femme` is hyphenated and Apple treats the hyphen as part of the token, so it costs the character but matches how it is typed.*

---

## fr-CA

**Title** (24/30)
> Hushlight - Contractions

**Subtitle** (30/30)
> Sans compte, hors ligne, privé

**Keywords** (92/100, comma-separated, no spaces)
> accouchement,grossesse,sage-femme,travail,minuterie,bébé,terme,doula,maternité,511,naissance

*Only `minuteur`→`minuterie`, which is the term Québec uses. Everything else holds.*

---

## de-DE

**Title** (23/30)
> Hushlight - Wehen Timer

**Subtitle** (27/30)
> Privat, offline, ohne Konto

**Keywords** (96/100, comma-separated, no spaces)
> Geburt,Schwangerschaft,Hebamme,Entbindung,Kreißsaal,Stoppuhr,Zähler,Baby,Doula,511,Geburtstermin

*`Wehen` is in the title, so it is absent here. `Kreißsaal` is the delivery room and the word a German reader would search for the place; `Geburtstermin` is the due date. Nouns stay capitalised — Apple's indexer is case-insensitive, but a German reading their own keyword list should not see it in lower case.*

---

## it

**Title** (23/30)
> Hushlight - Contrazioni

**Subtitle** (29/30)
> Privata, offline, senza login

**Keywords** (96/100, comma-separated, no spaces)
> parto,gravidanza,ostetrica,travaglio,cronometro,nascita,bebè,doula,511,contatore,partorire,mamma

*`travaglio` is labour, `parto` the birth; both earn their place. `ostetrica` is the midwife. `partorire` is the verb, which is how a search is often phrased.*

---

## pt-BR

**Title** (22/30)
> Hushlight - Contrações

**Subtitle** (27/30)
> Privado, offline, sem conta

**Keywords** (99/100, comma-separated, no spaces)
> parto,gravidez,obstetra,parteira,doula,cronômetro,nascimento,bebê,511,contador,maternidade,gestante

*`obstetra` and `parteira` both appear because Brazilian care is split between them and a reader searches for whichever they have. `gestante` is the word used for a pregnant woman in Brazilian health services, more than `grávida`.*

---

## ja

**Title** (18/30)
> Hushlight - 陣痛タイマー

**Subtitle** (16/30)
> オフライン・登録不要・端末内完結

**Keywords** (90/100, comma-separated, no spaces)
> 出産,妊娠,助産師,分娩,産院,赤ちゃん,臨月,予定日,破水,おしるし,カウンター,計測,511,妊婦,出産準備,間隔,ストップウォッチ,初産,マタニティ,助産院,経産婦,妊娠後期

*The CJK fields have room the Latin ones do not: Apple counts characters, and a Japanese keyword is two or three characters carrying a whole word. `おしるし` (the bloody show) and `破水` (waters breaking) are what someone actually searches at 3am, before they would think of the app category at all. `陣痛` and `タイマー` are in the title and absent here.*

---

## ko

**Title** (18/30)
> Hushlight - 진통 타이머

**Subtitle** (22/30)
> 오프라인 · 가입 없음 · 기기 안에서만

**Keywords** (78/100, comma-separated, no spaces)
> 출산,임신,조산사,분만,아기,예정일,양수,이슬,초산,산모,카운터,측정,511,산부인과,출산준비,스톱워치,만삭,진통간격,분만실,임산부,출산가방

*Same headroom as Japanese. `이슬` and `양수` are the Korean equivalents of the show and the waters. `진통간격` keeps `진통` from the title inside a compound — a deliberate exception, because Korean tokenises the compound as its own term and it is the single most likely phrase typed.*

---

## zh-Hans

**Title** (17/30)
> Hushlight - 宫缩计时器

**Subtitle** (18/30)
> 离线 · 无需注册 · 数据只在本机

**Keywords** (68/100, comma-separated, no spaces)
> 分娩,待产,怀孕,助产士,产房,宝宝,预产期,破水,见红,阵痛,秒表,计数,511,孕晚期,临产,产检,生孩子,数宫缩,产妇,临盆,顺产

*`阵痛` is included even though `宫缩` is in the title: the two are separate words for the same thing and readers use both. `见红` and `破水` are again the pre-hospital searches. `数宫缩` repeats `宫缩` inside a compound for the same reason Korean does.*

---

## Support and privacy URLs

Already live, one pair per storefront, and they resolve for every locale the
listing needs — checked 2026-09-06:

> `https://christianwainright.com/hushlight/<locale>/privacy`
> `https://christianwainright.com/hushlight/<locale>/support`

English answers at the bare `/hushlight/privacy` and `/hushlight/support`. An
unregistered locale 404s rather than falling through, so the routing is real.

**One defect to fix before submission**, found checking them: the localized pages
serve translated copy under `<html lang="en">`. VoiceOver picks its voice from that
attribute, so the Japanese and Chinese pages are read aloud in an English voice —
which is precisely the failure this app spends its own accessibility budget
avoiding. A one-line fix on the site, not in this repo.
