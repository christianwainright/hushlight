#!/usr/bin/env python3
"""Add a language to VerifiedLanguages: the `verified` set and its `neverSays` list.

usage: verify-language.py <map.py> <langcode> <one-line rationale for the list>

Both halves land together on purpose. `VerifiedLanguages` says a verified language
without a `neverSays` list is "half a signature" — and `LanguageGateTests` enforces it —
so doing them in one step removes the chance of a code arriving without its fixture.

The list is also checked against the catalogs before it is written: a banned phrase that
appears in the app's own shipped copy would make T0-14 fail, and it is far easier to see
that here than in a test log.
"""
import importlib.util
import json
import pathlib
import re
import sys

CATALOGS = [
    "Hushlight/Localizable.xcstrings",
    "HushlightWidgets/Localizable.xcstrings",
    "Packages/LaborKit/Sources/LaborKit/Resources/Localizable.xcstrings",
]


def shipped_values(lang):
    out = []
    for path in CATALOGS:
        for entry in json.load(open(path))["strings"].values():
            loc = entry.get("localizations", {}).get(lang, {})
            if "stringUnit" in loc:
                out.append(loc["stringUnit"]["value"])
            for var in loc.get("variations", {}).get("plural", {}).values():
                out.append(var["stringUnit"]["value"])
            for sub in loc.get("substitutions", {}).values():
                for var in sub["variations"]["plural"].values():
                    out.append(var["stringUnit"]["value"])
    return out


def main():
    map_path, lang, rationale = sys.argv[1], sys.argv[2], sys.argv[3]
    spec = importlib.util.spec_from_file_location("m", map_path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    never = m.NEVER_SAYS

    clashes = [(b, v) for v in shipped_values(lang) for b in never if b.lower() in v.lower()]
    if clashes:
        print(f"REFUSED — {lang}: banned phrase(s) appear in shipped copy:")
        for b, v in clashes:
            print(f"  ✗ {b!r} in {v[:80]!r}")
        sys.exit(1)

    p = pathlib.Path("Packages/LaborKit/Sources/LaborKit/VerifiedLanguages.swift")
    s = p.read_text()

    match = re.search(r'public static let verified: Set<String> = \[([^\]]*)\]', s)
    codes = [c.strip().strip('"') for c in match.group(1).split(",") if c.strip()]
    if lang not in codes:
        codes.append(lang)
        s = s[:match.start()] + 'public static let verified: Set<String> = [' + \
            ", ".join(f'"{c}"' for c in codes) + ']' + s[match.end():]

    if f'"{lang}": [' not in s:
        entries = "\n".join(f'            "{phrase}",' for phrase in never)
        block = (f'\n        // {rationale}\n'
                 f'        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy\n'
                 f'        "{lang}": [\n{entries}\n        ],\n'
                 f'        // lint-localizable:ignore-end\n')
        anchor = "    ]\n}"
        assert s.count(anchor) == 1
        s = s.replace(anchor, block + "    ]\n}")

    p.write_text(s)
    print(f"{lang}: verified, {len(never)} neverSays phrases, no clash with shipped copy")


if __name__ == "__main__":
    main()
