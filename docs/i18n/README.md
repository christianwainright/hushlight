# Translation maps and the pipeline that applies them

Nine locales — en, es, fr, de, it, pt-BR, ja, ko, zh-Hans — 255 keys each, 2,295
strings. These files are the **source** of that: the catalogs are generated from them,
not hand-edited, so a change to a translation is a change to one readable Python dict
rather than a hunt through three `.xcstrings` blobs.

## Which keys exist is not this file's decision

The **compiler** decides that, and `scripts/lint-loc-catalog.sh` enforces it
(decision 0063). `SWIFT_EMIT_LOC_STRINGS` is on, so
`xcodebuild -exportLocalizations` writes into the catalogs every key the code
actually resolved and marks `stale` every key nothing produces; the gate runs that
and fails if either happened. Adding a string is therefore a loop, not a guess:

```bash
./scripts/lint-loc-catalog.sh      # names the keys you are missing
xcodebuild -exportLocalizations -project Hushlight.xcodeproj \
    -localizationPath "$(mktemp -d)" -exportLanguage en   # keeps them
# then add the new keys to the maps below and apply
```

Before that setting was turned on, nothing reconciled the catalogs against the
source at all, and 53 keys were missing or near-missed — the full account is in
decision 0063 and in HL-046's backlog entry.

## Running it

```bash
# one language into all three catalogs
for c in Hushlight/Localizable.xcstrings \
         HushlightWidgets/Localizable.xcstrings \
         Packages/LaborKit/Sources/LaborKit/Resources/Localizable.xcstrings; do
  python3 scripts/apply-language.py "$c" docs/i18n/maps/fr.py fr --combined
done

# then the gate half: `verified` plus the language's own neverSays list
python3 scripts/verify-language.py docs/i18n/maps/fr.py fr "why this list is cut this way"
```

`--combined` says the map covers all three catalogs, so a key it names that this
catalog lacks belongs to a sibling and is not an error. The check that matters — every
key in *this* catalog is covered — stays fatal either way.

## What the pipeline refuses, and why each check exists

**Uncovered keys.** A map that misses a key would ship that string in English inside an
otherwise-translated app. Fatal.

**Format-specifier mismatch.** The specifiers are compared as a multiset, so `%@`
against `%lld` fails and so does a dropped or duplicated argument. This is the check
worth having: the wrong specifier does not crash a build, a lint or a test — it reads
another eight bytes off the stack at runtime and prints garbage into a sentence someone
is reading aloud to a midwife.

**Argument order, when a translation reorders.** `printf` consumes its arguments in
written order, so a translation that moves a clause silently swaps two values while
the multiset check still passes — Japanese, Korean and Chinese all want the count
before the interval in "averaging every X over N timed contractions", and all three
did exactly that. The fix is positional specifiers, and the check is that a
translation using them names every English argument exactly once **and** matches the
type English has at that index: `%2$lld` is only allowed where English's second
argument is `%lld`. A translation using no positions is asserting English's order,
which the multiset check already covers.

**Plural categories against the *target* language.** English has `one` and `other`;
Japanese, Korean and Chinese have only `other`. Validating against English would write
those languages a rule they never select, and a translator reading the catalog back
would think the app distinguished singular where it does not. `PLURAL_CATEGORIES` in
`apply-language.py` is the authority.

**A `neverSays` phrase that appears in the language's own shipped copy.**
`verify-language.py` checks before it writes, because seeing that here is far easier
than reading it out of a T0-14 failure log.

## What the maps carry beyond the strings

Each file's docstring records the **vocabulary decided once for that language** and the
**register rules**, because both are judgements a later editor would otherwise have to
re-derive from the diff:

- *provider* follows the country's care system, not the dictionary — `profesional`
  rather than the insurance-flavoured calque `proveedor`, `deine Hebamme oder Ärztin`
  because German maternity care is midwife-led, `담당 의료진` for the team seeing you.
- *labor and delivery* is a US ward name and becomes the room a local would be told to
  call: `la sala de partos`, `la maternité`, `a maternidade`, `産院`, `분만실`, `产房`.
- **No verdict is an imperative in any language.** The English is nominalised on purpose
  — "Calling your provider now is reasonable", never "Call your provider" — and every
  translation keeps that shape. The app reports; it does not order.
- The mono-caps instrument words are given as **words**, not capitals: the caps come
  from the type role (decision 0062), so `AHORA` and `Ahora` render identically.

Spanish predates the convention and its list lived only in `VerifiedLanguages`,
where `verify-language.py` could not read it; HL-046 mirrored it into `es-app.py`
so all nine locales are checked the same way.

## `neverSays` is cut per idiom, never translated

The English list is five phrases. Several languages need shapes English has no
counterpart for, because the temptation is language-specific: `ya viene el bebé`,
`il bambino sta arrivando`, `赤ちゃんが生まれます`, `要生了`. That sentence — *the baby is
coming* — is the one a frightened reader most wants to hear and the one this app has no
standing to say. English never had to ban it because English does not reach for it the
same way.

## Who signed

Decision 0061: Christian accepts the agent's translation as HD-4's verified read, and
`VerifiedLanguages` records it as **his acceptance**, not an agent's signature. The
residual risk is named there rather than buried — for ja, ko and zh-Hans the acceptance
is trust in the translation rather than an independent read.

Only **six** of the 255 keys are load-bearing medical surfaces
(`VerifiedLanguages.loadBearingKeyFragments`). If a native reviewer is ever engaged,
those six per language are the thing to hand them — 54 short strings across all nine
locales, which is minutes of work rather than a translation contract.
