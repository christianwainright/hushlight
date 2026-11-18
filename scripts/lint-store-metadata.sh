#!/bin/bash
# HL-049 / HL-047: the App Store listing metadata, checked before anything pushes it.
#
# `docs/store/metadata/<storefront>/<field>.txt` is the **source of truth** for the
# listing — one plain file per field, so a copy change is a readable diff rather than a
# blob, and so the push script needs no parser at all. The markdown docs beside it
# (`app-store-listing-*.md`) carry the reasoning; if the two ever disagree, these files
# are what ships.
#
# Six checks, and only one is about counting:
#
#   0. **No price word in the title, subtitle, keywords or promotional text — nor in
#      the screenshot and preview copy.** App Review round 2 (2026-09-09) rejected the
#      subtitle "Free, offline, no account." under Guideline 2.3.7: *"references to
#      free or discounted services are considered a price reference and are not
#      appropriate for app metadata."* Every one of the fourteen subtitles had led with
#      its language's word for free, and two preview text cards said it too. Latin
#      words match by stem so an inflection (gratuits, kostenlose, gratuitas) cannot
#      slip past; the store specs (`docs/design/hushlight/store/spec.json`, `spec/*.json`
#      and the iPad set's `spec-ipad.json`, `spec-ipad/*.json`, and HL-064's Duo set,
#      `spec-duo.json`, `spec-duo/*.json`) are read as well, so a
#      regenerated frame or card cannot bring the copy back. The description is the one field Apple names as the place for it, so
#      it is exempt here.
#
#   1. **Apple's field limits.** 30 / 30 / 100 / 170 / 4000. Exceeding one is not a
#      build error anywhere — App Store Connect simply refuses the field, or worse,
#      truncates it.
#   2. **A keyword may not repeat a word already in the title or subtitle.** Apple
#      indexes the three as one set, so a repeat spends characters to buy nothing. This
#      is the rule the English listing was cut against and the one a later edit is
#      most likely to forget.
#   3. **The policy URLs must agree with `PolicyLinks.swift`.** The app sends a reader
#      to the page in their own language (HL-052); a listing that pointed the same
#      storefront somewhere else would be the app and the store contradicting each
#      other on the one document a reviewer opens.
#   5. **What's New exists for every version past 1.0, in every storefront** (HL-053):
#      `release_notes/<version>.txt`, checked against the MARKETING_VERSION in
#      `project.yml` so the bump to 1.0.1 fails here rather than at submission.
#   4. **Every description ends with the app's own shipped disclaimer, verbatim from
#      the String Catalog.** This is the same join `DisclaimersTests` pins for English,
#      extended to nine languages: the sentence the store page tells a reader is the
#      sentence the app tells them, word for word. Retranslating it here would create a
#      second copy of the one paragraph in this product that must never drift.
set -uo pipefail
cd "$(dirname "$0")/.."

python3 - << 'PYEOF'
import glob, json, os, re, sys

ROOT = "docs/store/metadata"
LIMITS = {"title": 30, "subtitle": 30, "keywords": 100,
          "promotional_text": 170, "description": 4000}
FIELDS = list(LIMITS) + ["privacy_url", "support_url"]
BASE = "https://christianwainright.com/hushlight"

# storefront -> (app language, site locale segment). English storefronts take the bare
# path, which is what PolicyLinks returns for any `en*` language.
STOREFRONTS = {
    "en-US": ("en", ""), "en-GB": ("en", ""), "en-AU": ("en", ""), "en-CA": ("en", ""),
    "es-ES": ("es", "es-ES"), "es-MX": ("es", "es-MX"),
    "fr-FR": ("fr", "fr-FR"), "fr-CA": ("fr", "fr-CA"),
    "de-DE": ("de", "de-DE"), "it": ("it", "it"), "pt-BR": ("pt-BR", "pt-BR"),
    "ja": ("ja", "ja"), "ko": ("ko", "ko"), "zh-Hans": ("zh-Hans", "zh-Hans"),
}

CATALOG = "Packages/LaborKit/Sources/LaborKit/Resources/Localizable.xcstrings"
POLICY_LINKS = "Packages/LaborKit/Sources/LaborKit/PolicyLinks.swift"

errors = []

# Guideline 2.3.7. Latin words match by stem on word boundaries, so "gratuits" and
# "kostenlosen" trip it while "freedom" does not; CJK terms match as substrings, which
# is how those scripts carry words. Currency signs are a price reference on their own.
# "sale" is deliberately absent: it is the Spanish verb in "Nada sale del dispositivo"
# — the privacy line — and a French and Italian adjective; the guideline names "free or
# discounted", and the discount stems cover the second half.
PRICE_STEMS = [r"free", r"gratis", r"gratuit(?:es?|s|[oa]s?|ement)?", r"grátis",
               r"kostenlos(?:e[nrsm]?)?", r"discount(?:s|ed)?", r"descuentos?",
               r"rabatt(?:e[n]?)?", r"scont[oi]", r"descontos?", r"remises?"]
PRICE_SUBSTRINGS = ["無料", "割引", "무료", "할인", "免费", "折扣", "$", "€", "£", "¥"]
PRICE_FIELDS = ["title", "subtitle", "keywords", "promotional_text"]
PRICE_STEM_RE = re.compile(r"(?<![a-zà-ÿ])(?:" + "|".join(PRICE_STEMS) + r")(?![a-zà-ÿ])")
SPECS = (["docs/design/hushlight/store/spec.json"]
         + sorted(glob.glob("docs/design/hushlight/store/spec/*.json"))
         + ["docs/design/hushlight/store/spec-ipad.json"]
         + sorted(glob.glob("docs/design/hushlight/store/spec-ipad/*.json"))
         + ["docs/design/hushlight/store/spec-duo.json"]
         + sorted(glob.glob("docs/design/hushlight/store/spec-duo/*.json")))
CAPTION_FIELDS = ["eyebrow", "headline", "subline"]


def price_word(text):
    low = text.lower()
    m = PRICE_STEM_RE.search(low)
    if m:
        return m.group(0)
    for word in PRICE_SUBSTRINGS:
        if word in low:
            return word
    return None


def read(store, field):
    path = os.path.join(ROOT, store, field + ".txt")
    if not os.path.exists(path):
        errors.append(f"{store}: missing {field}.txt")
        return None
    return open(path, encoding="utf-8").read().rstrip("\n")


strings = json.load(open(CATALOG))["strings"]
disclaimer_key = next(k for k in strings if k.startswith("A stopwatch with arithmetic"))
disclaimer = {lang: unit["stringUnit"]["value"]
              for lang, unit in strings[disclaimer_key]["localizations"].items()
              if "stringUnit" in unit}

policy_source = open(POLICY_LINKS, encoding="utf-8").read()

present = sorted(d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d)))
for extra in set(present) - set(STOREFRONTS):
    errors.append(f"{extra}: a storefront directory this script does not know about")
for missing in set(STOREFRONTS) - set(present):
    errors.append(f"{missing}: no metadata directory")

for store in sorted(set(present) & set(STOREFRONTS)):
    language, segment = STOREFRONTS[store]
    values = {field: read(store, field) for field in FIELDS}
    if any(v is None for v in values.values()):
        continue

    # 0 — no price reference outside the description.
    for field in PRICE_FIELDS:
        hit = price_word(values[field])
        if hit:
            errors.append(f"{store}/{field}: contains a price reference ({hit!r}) — "
                          "Guideline 2.3.7 allows that only in the description")

    # 1 — Apple's limits.
    for field, limit in LIMITS.items():
        if len(values[field]) > limit:
            errors.append(f"{store}/{field}: {len(values[field])} characters, limit {limit}")

    # 2 — keywords are indexed with the title and subtitle, so a repeat buys nothing.
    if " " in values["keywords"]:
        errors.append(f"{store}/keywords: contains a space, which spends a character on nothing")
    head = (values["title"] + " " + values["subtitle"]).lower()
    for word in values["keywords"].split(","):
        if word.lower() in head:
            errors.append(f"{store}/keywords: '{word}' already appears in the title or subtitle")

    # 3 — the listing and the app must send a reader to the same page.
    expected = f"{BASE}/{segment}" if segment else BASE
    for field, page in (("privacy_url", "privacy"), ("support_url", "support")):
        if values[field] != f"{expected}/{page}":
            errors.append(f"{store}/{field}: {values[field]}\n"
                          f"    expected {expected}/{page} — see PolicyLinks.swift")
    if segment and f'"{segment}"' not in policy_source:
        errors.append(f"{store}: segment '{segment}' is not in PolicyLinks.swift, so the "
                      "app would send this storefront's readers somewhere else")

    # 4 — the store page and the app close on the same sentence.
    expected_close = disclaimer.get(language)
    if expected_close is None:
        errors.append(f"{store}: no shipped disclaimer for language '{language}'")
    else:
        if language == "en" and store != "en-US":
            expected_close = expected_close.replace("diagnose labor", "diagnose labour")
        if not values["description"].endswith(expected_close):
            errors.append(f"{store}/description: does not end with the shipped disclaimer "
                          f"for '{language}' — the store page and the app must close on "
                          "the same sentence")

# 5 — What's New (HL-053). `release_notes/<version>.txt` per storefront: every version
# that exists anywhere exists everywhere, each within Apple's 4,000, none with a price
# word, and the version `project.yml` is about to ship has one — 1.0 excepted, since
# App Store Connect asks for none on a first release. This is the check that turns
# "1.0.1 cannot ship without release notes in fourteen storefronts" from a discovery
# at submission time into a red gate at the version bump.
versions = {}
for store in sorted(set(present) & set(STOREFRONTS)):
    folder = os.path.join(ROOT, store, "release_notes")
    if os.path.isdir(folder):
        for name in os.listdir(folder):
            if name.endswith(".txt"):
                versions.setdefault(name[:-4], set()).add(store)
for version, stores in sorted(versions.items()):
    for store in sorted(set(STOREFRONTS) - stores):
        errors.append(f"{store}: no release_notes/{version}.txt")
    for store in sorted(stores):
        text = open(os.path.join(ROOT, store, "release_notes", version + ".txt"),
                    encoding="utf-8").read().rstrip("\n")
        if len(text) > 4000:
            errors.append(f"{store}/release_notes/{version}: {len(text)} characters, limit 4000")
        hit = price_word(text)
        if hit:
            errors.append(f"{store}/release_notes/{version}: contains a price reference "
                          f"({hit!r}) — Guideline 2.3.7")
# `project.yml` carries the version three times — the project-wide backstop and one
# override per target — and a bump that touches only the app target is the one that
# ships. Every value is checked, so no single line can be the one that was missed.
shipping = set(re.findall(r'MARKETING_VERSION:\s*"([^"]+)"',
                          open("project.yml", encoding="utf-8").read()))
for version in sorted(shipping - {"1.0"} - set(versions)):
    errors.append(f"project.yml ships {version} and no storefront has "
                  f"release_notes/{version}.txt — App Store Connect will refuse the update")

# 0, continued — the screenshot captions and preview cards are metadata too. Apple
# rejected the subtitle, but the same word sat on two preview cards; a caption that
# says it would be the next rejection.
for spec in SPECS:
    doc = json.load(open(spec, encoding="utf-8"))
    for kind in ("frames", "cards"):
        for item in doc.get(kind, []):
            for field in CAPTION_FIELDS:
                text = item.get(field)
                hit = price_word(text) if text else None
                if hit:
                    errors.append(f"{spec} {kind}/{item['id']}/{field}: contains a price "
                                  f"reference ({hit!r}) — Guideline 2.3.7")

if errors:
    print("FAIL — App Store listing metadata:")
    for e in errors:
        print(f"  {e}")
    sys.exit(1)

print(f"PASS — {len(present)} storefronts and {len(SPECS)} store specs: no price words outside "
      "the description, within "
      "Apple's limits, keywords do not repeat the title, policy URLs agree with PolicyLinks, "
      "descriptions close on the shipped disclaimer, release notes complete for "
      f"{len(versions)} version(s)")
PYEOF
