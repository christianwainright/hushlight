#!/usr/bin/env python3
"""Apply a language map to a String Catalog, refusing anything that would break at runtime.

usage: apply-language.py <catalog.xcstrings> <map.py> <langcode>

The checks are the point. A translation with the wrong format specifiers does not
fail a build, a lint or a test — it fails on a phone, mid-labour, by printing
garbage into a sentence someone is reading to a midwife. So:

  * the multiset of specifiers must match the source exactly (%@ vs %lld matters:
    the wrong one reads another eight bytes off the stack)
  * plural entries must supply every category the source supplies
  * every catalog key must be covered, and the map may not name keys that do not
    exist — a typo'd key would silently translate nothing
"""
import importlib.util
import json
import re
import sys
from collections import Counter

SPECIFIER = re.compile(r"%(?:(\d+)\$)?(@|lld|llu|lu|[dsf])")


def positional_error(source: str, value: str, lang: str):
    """Why a translation may reorder arguments only with `%N$` positions, and what
    goes wrong when it doesn't.

    A `printf` format consumes its arguments in written order. A translation that
    moves a clause — Japanese, Korean and Chinese all want the count before the
    interval in "averaging every X over N timed contractions" — silently swaps two
    values while every existing check still passes, because the multiset of
    specifiers is unchanged. When both are `%@` the reader sees the wrong figure;
    when one is `%lld` the formatter reads a pointer as an integer.

    So: a translation that uses positional specifiers must name every English
    argument exactly once, and the type it names at each position must be the type
    English has there. A translation that uses none is asserting English's order,
    which the multiset check already covers."""
    src = SPECIFIER.findall(source)
    val = SPECIFIER.findall(value)
    if not any(index for index, _ in val):
        return None
    if any(not index for index, _ in val):
        return (f"MIXED POSITIONS\n    {lang}: {value[:90]}\n"
                "    every specifier must be positional once any of them is")
    # Argument *number* to type, which is not the same as written order: the source
    # may itself be positional (Xcode's exporter rewrites a multi-argument English
    # value that way), and a positional source is free to write %2$@ first.
    src_kind = {}
    for slot, (index, kind) in enumerate(src, start=1):
        src_kind[int(index) if index else slot] = kind
    seen = sorted(int(index) for index, _ in val)
    if seen != sorted(src_kind):
        return (f"BAD POSITIONS\n    en : arguments {sorted(src_kind)}\n"
                f"    {lang}: names {seen}")
    for index, kind in val:
        want = src_kind[int(index)]
        if kind != want:
            return (f"POSITIONAL TYPE MISMATCH\n    en : argument {index} is %{want}\n"
                    f"    {lang}: uses %{index}${kind}")
    return None


NAMED = re.compile(r"%\d+\$#@\w+@")

# CLDR plural categories per target language. Validating against *English's* set would
# force a `one` bucket onto Japanese, Korean and Chinese, which have only `other` — the
# catalog would carry a rule the language never selects, and a translator reading it
# back would think the app distinguished singular where it does not. Conversely a
# missing `one` in French or German is a real bug, so the check has to know the target.
PLURAL_CATEGORIES = {
    "es": {"one", "other"},
    "fr": {"one", "other"},
    "de": {"one", "other"},
    "it": {"one", "other"},
    "pt-BR": {"one", "other"},
    "ja": {"other"},
    "ko": {"other"},
    "zh-Hans": {"other"},
}


def specifiers(text: str) -> Counter:
    """Specifier kinds, positions discarded — `%2$lld` counts as `%lld`, so a
    reordered translation still has to carry the same arguments. Order itself is
    `positional_error`'s job."""
    return Counter(kind for _, kind in SPECIFIER.findall(text))


def specifiers_named(text: str) -> Counter:
    """Placeholders of the `%1$#@argName@` form, which SPECIFIER deliberately ignores."""
    return Counter(NAMED.findall(text))


def load_map(path):
    spec = importlib.util.spec_from_file_location("langmap", path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return getattr(m, "TRANSLATIONS", {}), getattr(m, "PLURALS", {})


def english_value(entry, key):
    en = entry.get("localizations", {}).get("en", {})
    if "stringUnit" in en:
        return en["stringUnit"]["value"]
    return key  # key-as-value entries


def main():
    catalog_path, map_path, lang = sys.argv[1], sys.argv[2], sys.argv[3]
    # One map per language rather than per catalog: the three catalogs share keys
    # ("Start", "CONTRACTIONS", "%lld contraction") and splitting them invites the two
    # copies to drift. With --combined a key the map names but this catalog lacks is
    # not an error, because it belongs to one of the siblings. The check that matters —
    # every key in *this* catalog is covered — is unaffected and still fatal.
    combined = "--combined" in sys.argv
    translations, plurals = load_map(map_path)
    spec_mod = importlib.util.spec_from_file_location("langmap2", map_path)
    _m = importlib.util.module_from_spec(spec_mod); spec_mod.loader.exec_module(_m)
    substitutions = getattr(_m, "SUBSTITUTIONS", {})
    catalog = json.load(open(catalog_path))
    strings = catalog["strings"]

    errors, applied = [], 0
    covered = set(translations) | set(plurals) | set(substitutions)
    for key in set(strings) - covered:
        errors.append(f"UNCOVERED key: {key[:80]}")
    if not combined:
        for key in covered - set(strings):
            errors.append(f"key not in catalog: {key[:80]}")

    for key, value in translations.items():
        if key not in strings:
            continue
        source = english_value(strings[key], key)
        if specifiers(source) != specifiers(value):
            errors.append(
                f"SPECIFIER MISMATCH\n    key: {key[:70]}\n    en : {sorted(specifiers(source).elements())}"
                f"\n    {lang} : {sorted(specifiers(value).elements())}"
            )
            continue
        problem = positional_error(source, value, lang)
        if problem:
            errors.append(f"{problem}\n    key: {key[:70]}")
            continue
        strings[key].setdefault("localizations", {})[lang] = {
            "stringUnit": {"state": "translated", "value": value}
        }
        applied += 1

    for key, cases in plurals.items():
        if key not in strings:
            continue
        en = strings[key]["localizations"]["en"]["variations"]["plural"]
        expected = PLURAL_CATEGORIES.get(lang, set(en))
        for category in expected:
            if category not in cases:
                errors.append(f"plural '{key}' missing category '{category}' for {lang}")
        for category in cases:
            if category not in expected:
                errors.append(f"plural '{key}' has category '{category}' which {lang} does not use")
        for category, value in cases.items():
            source = en.get(category, en.get("other"))["stringUnit"]["value"]
            if specifiers(source) != specifiers(value):
                errors.append(f"SPECIFIER MISMATCH in plural '{key}' [{category}]")
        if any("SPECIFIER MISMATCH in plural '%s'" % key in e for e in errors):
            continue
        strings[key].setdefault("localizations", {})[lang] = {
            "variations": {
                "plural": {
                    c: {"stringUnit": {"state": "translated", "value": v}}
                    for c, v in cases.items()
                }
            }
        }
        applied += 1

    # Substitution entries: the outer value names %N$#@argName@ placeholders and each
    # named argument carries its own plural table. The English entry owns argNum and
    # formatSpecifier — those are positional facts about the call site, not translation
    # choices, so they are copied rather than re-declared and cannot drift.
    for key, spec in substitutions.items():
        if key not in strings:
            continue
        en = strings[key]["localizations"]["en"]
        en_subs = en.get("substitutions", {})
        outer = spec["value"]
        if specifiers_named(outer) != specifiers_named(en["stringUnit"]["value"]):
            errors.append(f"SUBSTITUTION placeholder mismatch in {key[:60]}")
            continue
        built = {}
        ok = True
        for arg, cases in spec["args"].items():
            if arg not in en_subs:
                errors.append(f"substitution '{arg}' not in en for {key[:60]}"); ok = False; continue
            en_arg = en_subs[arg]
            en_plural = en_arg["variations"]["plural"]
            expected = PLURAL_CATEGORIES.get(lang, set(en_plural))
            for category in expected:
                if category not in cases:
                    errors.append(f"substitution '{arg}' missing '{category}' for {lang} in {key[:50]}"); ok = False
            for category in cases:
                if category not in expected:
                    errors.append(f"substitution '{arg}' has '{category}', unused by {lang}, in {key[:50]}"); ok = False
            for category, value in cases.items():
                src = en_plural.get(category, en_plural.get("other"))["stringUnit"]["value"]
                if specifiers(src) != specifiers(value):
                    errors.append(f"SPECIFIER MISMATCH in substitution '{arg}' [{category}] of {key[:50]}"); ok = False
            built[arg] = {
                "argNum": en_arg["argNum"],
                "formatSpecifier": en_arg["formatSpecifier"],
                "variations": {"plural": {c: {"stringUnit": {"state": "translated", "value": v}}
                                          for c, v in cases.items()}},
            }
        if not ok:
            continue
        strings[key].setdefault("localizations", {})[lang] = {
            "stringUnit": {"state": "translated", "value": outer},
            "substitutions": built,
        }
        applied += 1

    if errors:
        print(f"REFUSED — {len(errors)} problem(s), catalog untouched:\n")
        for e in errors:
            print("  ✗", e)
        sys.exit(1)

    with open(catalog_path, "w") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"applied {applied} {lang} entries to {catalog_path}")


if __name__ == "__main__":
    main()
