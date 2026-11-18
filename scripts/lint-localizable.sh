#!/bin/bash
# The HL-006 zero-literals gate, in one place — the same arrangement as
# lint-literals.sh and lint-logging.sh: `scripts/gate.sh` and CI both call this
# script, so the local gate and CI cannot drift into enforcing two different rules.
#
# Perfect static detection of "every user-facing string is localized" is
# impossible without a type-checker (a `String`-typed parameter and a
# `LocalizedStringKey`-typed one both accept a bare `"literal"`, and only the
# compiler knows which one a given call site resolved to). This script defines
# the rule mechanically instead, in three parts:
#
#   1. `Text("prose", comment: "…")` — SwiftUI's `Text` auto-keys a literal
#      argument into the String Catalog with no source change required, so a
#      bare `Text("…")` is not itself a violation. What IS a violation is a
#      `Text(…)` literal that reads as prose (contains a space and a lowercase
#      letter, once its `\(…)` interpolations are collapsed to a placeholder so
#      an interpolated *variable name* can never masquerade as prose) and
#      carries no `comment:` argument — HL-006 §1 requires every catalog entry
#      name what a translator needs, and `comment:` is the only way a `Text`
#      literal carries one. Mono-caps data vocabulary ("NOW", "RUNNING", data
#      column headers) and pure figures/symbols never contain a lowercase
#      letter once stripped, so they never match this rule — exactly the
#      HL-006 scope line that leaves them for HL-007.
#
#   2. `.accessibilityLabel(/Value/Hint)("…")` — these three modifiers have no
#      `LocalizedStringKey` overload at all (only a `Text` overload and a
#      verbatim `StringProtocol` one), so a literal argument here is *never*
#      auto-keyed. Flagged unconditionally, regardless of what the literal says.
#
#   3. Every other bare string literal that reads as prose (the same
#      space-and-a-lowercase-letter-after-interpolation-collapse test) and is
#      not one of the recognized compliant shapes below.
#
# What rule 3 recognizes as compliant, and therefore skips before it ever looks
# for a bare literal:
#   - `String(localized: "…", …)` — the actual fix this whole item exists to
#     apply; wrapped literals are never flagged, single-line or the multi-line
#     `"""…"""` form the longer sentences in this codebase use.
#   - `comment:` argument values — a comment explaining a key to a translator
#     is not itself user-facing text, and would otherwise be flagged as prose
#     every single time (making the gate un-passable by construction).
#   - `Text(…)`, `.accessibility(Label|Value|Hint)(…)` — rules 1 and 2 already
#     judged these; rule 3 does not re-litigate them under a looser test.
#   - `Button(…)`, `Picker(…)`, `TextField(…)`, `SecureField(…)`, `Link(…)`,
#     `NavigationLink(…)`, `Label(…)`, `Toggle(…)`, `.navigationTitle(…)` — every
#     one of these SwiftUI initializers/modifiers has a `LocalizedStringKey`
#     overload, so a literal argument auto-keys exactly as a bare `Text("…")`
#     does. HL-006 leaves them exactly where `Text` is left (no source change
#     required); a future HL-007-class pass that wants translator comments on
#     these too is free to route them through `Text(…)` first.
#   - `assertionFailure(…)`, `fatalError(…)`, `preconditionFailure(…)` —
#     developer-facing crash/debug messages, never shown to a user.
#   - Anything between a `// lint-localizable:ignore-start` and a
#     `// lint-localizable:ignore-end` comment, and any single line carrying a
#     trailing `// lint-localizable:ok` comment — the two escape hatches this
#     script recognizes, used exactly three times in the shipped tree:
#       * `Disclaimers.neverSays` — the T0-14 voice-rule fixture the tests
#         check shipped copy against, not shipped copy itself; HL-008 is the
#         item that re-cuts it per language.
#       * `Disclaimers.reviewNotes` — pasted verbatim into App Store Connect's
#         Notes for Review field, which Apple's reviewers read in English
#         regardless of the build's locale, and which is never rendered inside
#         the app itself.
#       * `ReportProblemButton.osVersion`'s "iOS" literal — Apple's product
#         name, never translated.
#
# Scope: `Hushlight/`, `HushlightWidgets/`, and
# `Packages/LaborKit/Sources/LaborKit/` — the three targets this item gives a
# String Catalog. `Hushlight/CrashDiagnostics.swift` is excluded outright: every
# string it builds is a MetricKit diagnostic detail written to on-device storage
# for a future Organizer match — grep confirms `DiagnosticSummary.detail` is
# never read by anything that renders UI, only its *counts* reach the
# Report-a-problem email, so nothing in that file is user-facing.
# `Packages/DesignKit` (preview-only strings, explicitly not user-facing per this
# item), `scripts/`, `.claude/`, `Packages/LaborSim` (the QA harness engine,
# linked into no app target) and every `Tests/`/`UITests` directory (pinned
# English fixtures, not shipped copy) are out of scope entirely — the same
# "never enters the app binary" reasoning `lint-literals.sh` and
# `lint-logging.sh` already use for `scripts/`.
#
# One more named limitation: rule 3 recognizes a compliant call by *name*
# (`String(`, `LocalizedStringResource(`), not by which overload it resolved
# to, so it blanks every `String(...)` span wholesale — including
# `String(format:)`/`String(decoding:)` calls that carry no localizable
# content at all. A hypothetical `String("Some sentence")` (the verbatim
# initializer, spelled to look like the fix) would slip past rule 3 the same
# way it would slip past a human skimming a diff; nothing in this codebase is
# shaped that way today; a future one should still get a code-review glance,
# not just a green gate.
set -uo pipefail
cd "$(dirname "$0")/.."

python3 - << 'PYEOF'
import json
import re
import os
import sys

SCOPE_DIRS = ["Hushlight", "HushlightWidgets", "Packages/LaborKit/Sources/LaborKit"]
EXCLUDE_FILES = {os.path.join("Hushlight", "CrashDiagnostics.swift")}

WHITELIST_CALLS = [
    "Button", "Picker", "TextField", "SecureField", "Link",
    "NavigationLink", "Label", "Toggle",
]
DEBUG_CALLS = ["assertionFailure", "fatalError", "preconditionFailure"]


def collect_files():
    files = []
    for d in SCOPE_DIRS:
        for dirpath, _, fnames in os.walk(d):
            if os.sep + "Tests" + os.sep in (dirpath + os.sep) or dirpath.endswith("Tests"):
                continue
            for f in fnames:
                if not f.endswith(".swift"):
                    continue
                p = os.path.join(dirpath, f)
                if p in EXCLUDE_FILES:
                    continue
                files.append(p)
    return sorted(files)


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def matching_bracket(text, open_index, open_ch="(", close_ch=")"):
    """`open_index` points at the opening bracket — returns the index just past
    its partner. String-literal-aware, so a bracket inside a `"…"` never counts."""
    depth = 0
    i = open_index
    n = len(text)
    in_string = False
    triple = False
    while i < n:
        c = text[i]
        if in_string:
            if triple:
                if text[i:i + 3] == '"""':
                    in_string = False
                    triple = False
                    i += 3
                    continue
            else:
                if c == "\\":
                    i += 2
                    continue
                if c == '"':
                    in_string = False
            i += 1
            continue
        if text[i:i + 3] == '"""':
            in_string = True
            triple = True
            i += 3
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def matching_paren(text, open_index):
    return matching_bracket(text, open_index)


def strip_comments(text):
    """Blank out every `//…` line comment (doc comments included) and `/*…*/`
    block comment, character-for-character (newlines kept, everything else
    replaced with a space) so line numbers in reported violations still point
    at the original file. String-literal-aware: a `//` inside a `"…"` or
    `\"\"\"…\"\"\"` literal — the URLs in `GuidanceScreen.swift`'s
    `privacyPolicyURL`/`supportURL`, for instance — is never mistaken for a
    comment start, and a quoted example inside a doc comment (this file's own
    header, or `PatternAnalysis.swift`'s "how long has this been happening")
    is never mistaken for a bare user-facing literal."""
    out = list(text)
    i, n = 0, len(text)
    in_string = False
    triple = False
    while i < n:
        c = text[i]
        if in_string:
            if triple:
                if text[i:i + 3] == '"""':
                    in_string = False
                    triple = False
                    i += 3
                    continue
            else:
                if c == "\\":
                    i += 2
                    continue
                if c == '"':
                    in_string = False
            i += 1
            continue
        if text[i:i + 3] == '"""':
            in_string = True
            triple = True
            i += 3
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if text[i:i + 2] == "//":
            j = i
            while j < n and text[j] != "\n":
                out[j] = " "
                j += 1
            i = j
            continue
        if text[i:i + 2] == "/*":
            j = text.index("*/", i + 2) + 2 if "*/" in text[i + 2:] else n
            for k in range(i, j):
                if text[k] != "\n":
                    out[k] = " "
            i = j
            continue
        i += 1
    return "".join(out)


def strip_interpolations(s):
    r"""Collapse every `\\(...)` (arbitrarily nested) to a single placeholder, so
    an interpolated *identifier* (which can contain lowercase letters and,
    across two adjacent interpolations, an incidental space) can never be
    mistaken for prose. This is the one piece of real Swift-awareness the
    otherwise-textual rule below needs."""
    out = []
    i, n = 0, len(s)
    while i < n:
        if s[i] == "\\" and i + 1 < n and s[i + 1] == "(":
            depth = 1
            j = i + 2
            while j < n and depth > 0:
                if s[j] == "(":
                    depth += 1
                elif s[j] == ")":
                    depth -= 1
                j += 1
            out.append("%@")
            i = j
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def is_prose(literal_text):
    """literal_text is the raw content between the quotes (no surrounding
    quote characters)."""
    collapsed = strip_interpolations(literal_text)
    return (" " in collapsed) and any(c.islower() for c in collapsed)


MONO_CAPS_WORD = re.compile(r"(?<![A-Za-z])[A-Z]{2,}(?![A-Za-z])")


def is_instrument_vocabulary(literal_text):
    r"""A mono-caps instrument phrase — `THIS STRETCH · AVG %@ APART`, `CHECK ·
    OVER 3 MIN`, `%@ · FROM %@ · %lld`.

    `is_prose` cannot see these: they carry no lowercase letter, which is exactly
    what made rule 3 skip them and what let them survive HL-006, HL-007 and
    HL-008 to be found, in English, on a Spanish History screen. Decision 0062
    settles that this vocabulary translates — the caps come from the type role,
    so `AHORA` and `Ahora` render identically — so a bare one is a defect.

    The test is an all-caps word of two or more letters plus a space, which is
    what separates a phrase from every non-UI literal in this tree: identifiers,
    URLs, SF Symbol names, reverse-DNS bundle ids and `CFBundle…` keys all lack
    the space. Its named limit is the single-letter unit: `\(hours) H \(minutes) M`
    has no two-letter caps word and would not be caught by this rule."""
    collapsed = "".join(split_interpolations(literal_text))
    return " " in collapsed and bool(MONO_CAPS_WORD.search(collapsed))


def find_calls(text, names):
    """Every `name(...)` call span in `text`, matched by bracket-depth so a
    literal containing its own parentheses (there are none in this tree, but
    the interpolations routinely do) never truncates the span early."""
    spans = []
    pattern = re.compile(r"\b(?:" + "|".join(re.escape(n) for n in names) + r")\s*\(")
    for m in pattern.finditer(text):
        open_paren = text.index("(", m.start())
        end = matching_paren(text, open_paren)
        spans.append((m.start(), end, text[m.start():end]))
    return spans


def first_literal_args(call_text):
    """Every top-level `"…"`/`\"\"\"…\"\"\"` literal that appears before the
    call's first top-level `comment:` keyword — i.e. the candidate "what is
    shown" arguments, as opposed to the translator note about them. Handles
    the plain-literal and the `cond ? "A" : "B"` ternary shapes this codebase
    uses; a literal build from any other expression is not something a purely
    textual scan can find, which is exactly the "perfect detection is
    impossible" limit this script's header names."""
    body = call_text[call_text.index("(") + 1:-1]
    comment_kw = re.search(r"\bcomment\s*:", body)
    head = body[:comment_kw.start()] if comment_kw else body
    literals = []
    i, n = 0, len(head)
    while i < n:
        if head[i:i + 3] == '"""':
            j = head.index('"""', i + 3)
            literals.append(head[i + 3:j])
            i = j + 3
        elif head[i] == '"':
            j = i + 1
            while j < n and head[j] != '"':
                if head[j] == "\\":
                    j += 1
                j += 1
            literals.append(head[i + 1:j])
            i = j + 1
        else:
            i += 1
    return literals, bool(comment_kw)


def blank_span(chars, start, end):
    for i in range(start, end):
        if chars[i] != "\n":
            chars[i] = " "


def strip_ignore_blocks(text):
    lines = text.split("\n")
    out = []
    active = False
    for line in lines:
        if "lint-localizable:ignore-start" in line:
            active = True
            out.append("")
            continue
        if "lint-localizable:ignore-end" in line:
            active = False
            out.append("")
            continue
        if active or "lint-localizable:ok" in line:
            out.append("")
        else:
            out.append(line)
    return "\n".join(out)



# --- Rules 4 and 5's machinery (HL-046) --------------------------------------

# Which String Catalog a file's auto-keyed literals must appear in. A literal
# inside an app or extension target keys into that target's own catalog; LaborKit
# reads its own through `bundle: .module`. Longest prefix wins, so LaborKit's
# path is not swallowed by a shorter one.
CATALOGS = {
    "Hushlight": os.path.join("Hushlight", "Localizable.xcstrings"),
    "HushlightWidgets": os.path.join("HushlightWidgets", "Localizable.xcstrings"),
    os.path.join("Packages", "LaborKit", "Sources", "LaborKit"):
        os.path.join("Packages", "LaborKit", "Sources", "LaborKit", "Resources",
                     "Localizable.xcstrings"),
}

# Calls whose first *positional* argument is a `LocalizedStringKey` — the shape
# that looks up a catalog key without any source change. `Text` plus the
# initializers rule 3 already exempts for exactly this reason.
AUTOKEY_CALLS = ["Text"] + WHITELIST_CALLS + ["navigationTitle"]


def load_catalog_keys():
    keys = {}
    for scope, catalog in CATALOGS.items():
        with open(catalog, encoding="utf-8") as fh:
            keys[scope] = set(json.load(fh).get("strings", {}).keys())
    return keys


CATALOG_KEYS = load_catalog_keys()
ANY_KEYS = set().union(*CATALOG_KEYS.values())
LABORKIT = os.path.join("Packages", "LaborKit", "Sources", "LaborKit")
MAIN_BUNDLE_LABEL = "every catalog (this call resolves against Bundle.main)"


def IN_PACKAGE(path):
    return path.startswith(LABORKIT + os.sep)


def catalog_for(path):
    """(catalog path, key set) for a source file, longest scope prefix first."""
    for scope in sorted(CATALOGS, key=len, reverse=True):
        if path == scope or path.startswith(scope + os.sep):
            return CATALOGS[scope], CATALOG_KEYS[scope]
    return None, None


SWIFT_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "0": "\0",
                 '"': '"', "'": "'", "\\": "\\"}


def unescape(s):
    """Swift's escape sequences resolved to the characters a catalog key holds —
    `\\"` is a quote in the key, not a backslash and a quote."""
    out, i, n = [], 0, len(s)
    while i < n:
        if s[i] == "\\" and i + 1 < n:
            out.append(SWIFT_ESCAPES.get(s[i + 1], s[i + 1]))
            i += 2
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def multiline_value(raw):
    """The value of a `\"\"\"…\"\"\"` literal: the opening newline dropped, the
    closing delimiter's indentation stripped from every line, and each trailing
    `\\` line-continuation closed up. Both LaborKit disclaimers are written this
    way, and the key they look up is the *result*, not the source rectangle."""
    lines = raw.split("\n")
    if lines and not lines[0].strip():
        lines = lines[1:]
    indent = ""
    if lines and not lines[-1].strip():
        indent = lines[-1]
        lines = lines[:-1]
    body = "\n".join(ln[len(indent):] if ln.startswith(indent) else ln.lstrip()
                     for ln in lines)
    return re.sub(r"\\\n", "", body)


# Swift writes `%@` for a String interpolation and `%lld` for an integer one,
# and which one a given `\(…)` became depends on the interpolated expression's
# *type* — the one thing a textual scan cannot know. Rule 4 matches any
# specifier rather than guessing, which keeps it honest in the direction that
# matters: it can miss a violation where two catalog keys differ only in their
# specifiers, and it can never invent one.
FORMAT_SPECIFIER = r"%(?:\d+\$)?(?:@|lld|ld|d|lf|\d*(?:\.\d+)?f)"


def leading_literal(call_text):
    """The call's first argument as written, when that argument is a bare string
    literal in positional position — the shape that keys into a catalog. A
    `\"\"\"…\"\"\"` literal comes back as its value; interpolations are left in
    place for the two probes below to read.

    None for everything else — a variable, a ternary, a labelled first argument
    (`Text(verbatim:)`), any expression. Those carry no statically knowable key,
    which is the type-checker limit this script's header names."""
    body = call_text[call_text.index("(") + 1:-1].lstrip()
    if body.startswith('"""'):
        end = body.find('"""', 3)
        return None if end == -1 else multiline_value(body[3:end])
    if body.startswith('"'):
        i, n = 1, len(body)
        while i < n and body[i] != '"':
            # An interpolation is skipped whole: `\(clauses.joined(separator: ", "))`
            # carries quotes of its own, and a scan that stopped at the first one
            # would read half a literal and miss the key it actually forms.
            if body[i] == "\\" and i + 1 < n and body[i + 1] == "(":
                i = matching_bracket(body, i + 1)
                continue
            if body[i] == "\\":
                i += 1
            i += 1
        return body[1:i]
    return None


def split_interpolations(raw):
    r"""`raw` cut into the literal text between its `\(…)` interpolations."""
    parts, buf, i, n = [], [], 0, len(raw)
    while i < n:
        if raw[i] == "\\" and i + 1 < n and raw[i + 1] == "(":
            depth, j = 1, i + 2
            while j < n and depth:
                if raw[j] == "(":
                    depth += 1
                elif raw[j] == ")":
                    depth -= 1
                j += 1
            parts.append("".join(buf))
            buf, i = [], j
        elif raw[i] == "\\" and i + 1 < n:
            buf.append(SWIFT_ESCAPES.get(raw[i + 1], raw[i + 1]))
            i += 2
        else:
            buf.append(raw[i])
            i += 1
    parts.append("".join(buf))
    return parts


def catalog_match(raw, keys):
    r"""Whether some key in `keys` is the one this literal looks up. Exact for a
    plain literal; for an interpolated one, every `\(…)` matches any format
    specifier (see `FORMAT_SPECIFIER`)."""
    parts = split_interpolations(raw)
    if len(parts) == 1:
        return parts[0] in keys
    pattern = re.compile("^" + FORMAT_SPECIFIER.join(re.escape(p) for p in parts) + "$")
    return any(pattern.match(k) for k in keys)


def top_level_args(body):
    """Split a call body on its top-level commas — bracket- and
    string-literal-aware, so a nested call or an interpolation never splits."""
    args, depth, start, i, n = [], 0, 0, 0, len(body)
    in_string = triple = False
    while i < n:
        c = body[i]
        if in_string:
            if triple:
                if body[i:i + 3] == '"""':
                    in_string = triple = False
                    i += 3
                    continue
            else:
                if c == "\\":
                    i += 2
                    continue
                if c == '"':
                    in_string = False
            i += 1
            continue
        if body[i:i + 3] == '"""':
            in_string = triple = True
            i += 3
            continue
        if c == '"':
            in_string = True
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            args.append(body[start:i])
            start = i + 1
        i += 1
    args.append(body[start:])
    return [a.strip() for a in args if a.strip()]


def struct_string_properties(text):
    """{struct name: {stored properties typed `String`}} for one file.

    This is rule 5's whole basis: a `String` property is a *verbatim* string by
    the time `Text(someStruct.label)` renders it, so a literal written at the
    call site can never reach a catalog. Naming the property `label` is not what
    makes it dangerous — its type is.

    Declarations are collected across every in-scope file, because a struct is
    routinely built somewhere other than where it is declared. The named cost of
    that: two structs sharing a name in different files would have their property
    sets unioned, and a literal passed to one could be flagged against the other's
    property. No name in this tree is declared twice today."""
    out = {}
    for m in re.finditer(r"\bstruct\s+([A-Za-z_]\w*)[^{]*\{", text):
        open_brace = text.index("{", m.start())
        close = matching_bracket(text, open_brace, "{", "}")
        body = text[open_brace + 1:close - 1]
        props = {pm.group(1) for pm in
                 re.finditer(r"\b(?:let|var)\s+([A-Za-z_]\w*)\s*:\s*String\b", body)}
        if props:
            out.setdefault(m.group(1), set()).update(props)
    return out


# Rule 5 needs every in-scope struct before it can judge any call site, so the
# declarations are collected in a pass of their own.
STRING_PROP_STRUCTS = {}
for _path in collect_files():
    with open(_path, encoding="utf-8") as _fh:
        _decls = struct_string_properties(strip_comments(_fh.read()))
    for _name, _props in _decls.items():
        STRING_PROP_STRUCTS.setdefault(_name, set()).update(_props)


violations = []  # (rule, path, line, snippet)

for path in collect_files():
    with open(path, encoding="utf-8") as fh:
        raw_text = fh.read()
    # Order matters: the ignore-block markers themselves live inside `//`
    # comments, so blocks have to be recognized before comments are blanked.
    text = strip_comments(strip_ignore_blocks(raw_text))

    # --- Rule 1: Text("prose") with no translator comment. ------------------
    for start, end, call_text in find_calls(text, ["Text"]):
        literals, has_comment = first_literal_args(call_text)
        if has_comment:
            continue
        if any(is_prose(lit) for lit in literals):
            violations.append(("Text(…) literal has no comment:", path, line_of(text, start),
                                call_text.splitlines()[0][:140]))

    # --- Rule 2: accessibilityLabel/Value/Hint literals, unconditional. -----
    for start, end, call_text in find_calls(
        text, ["accessibilityLabel", "accessibilityValue", "accessibilityHint"]
    ):
        arg = call_text[call_text.index("(") + 1:-1].strip()
        if arg.startswith('"'):
            violations.append(("accessibility literal outside a catalog", path,
                                line_of(text, start), call_text.splitlines()[0][:140]))

    # --- Rule 3: every other bare prose literal. -----------------------------
    # Consume (blank out) every span rule 3 must not re-inspect: String(localized:)
    # calls (the fix), Text(...) and accessibility(...) calls (rules 1/2 already
    # judged them), the SwiftUI initializers that auto-key like Text does, and
    # developer-only crash/debug messages. What is left over is, by construction,
    # a literal not on any recognized compliant path.
    chars = list(text)
    consumed_names = (
        ["String", "LocalizedStringResource"]
        + ["Text", "accessibilityLabel", "accessibilityValue", "accessibilityHint"]
        + WHITELIST_CALLS + DEBUG_CALLS
    )
    for start, end, call_text in find_calls(text, consumed_names):
        blank_span(chars, start, end)
    # `.navigationTitle(...)` is a modifier, not an initializer `find_calls`'s
    # `\bname(` pattern already matches it (the leading `.` is not part of the
    # word boundary check), so it rides along with WHITELIST_CALLS's own pass
    # only if named — add it explicitly since it is spelled with a leading dot
    # conventionally but the regex only needs the bare identifier.
    for start, end, _ in find_calls(text, ["navigationTitle"]):
        blank_span(chars, start, end)
    remainder = "".join(chars)

    for m in re.finditer(r'"""((?:(?!""").)*)"""|"((?:[^"\\]|\\.)*)"', remainder, re.DOTALL):
        literal = m.group(1) if m.group(1) is not None else m.group(2)
        snippet = remainder[max(0, m.start() - 40):m.start()].splitlines()[-1] if m.start() else ""
        if is_prose(literal):
            violations.append(("bare String literal, not String(localized:)", path,
                                line_of(text, m.start()), (snippet + m.group(0))[:160]))
        # --- Rule 6: bare mono-caps instrument vocabulary. -------------------
        elif is_instrument_vocabulary(literal):
            violations.append(("bare mono-caps instrument phrase, not String(localized:)",
                                path, line_of(text, m.start()),
                                (snippet + m.group(0))[:160]))

    # --- Rule 4: an auto-keyed literal with no String Catalog entry. --------
    # Rules 1 and 3 exempt `Text(…)` and the `LocalizedStringKey` initializers
    # because a literal there needs no source change to become a catalog key.
    # That is true of the *lookup* and was false of the catalogs: they are
    # `extractionState: manual`, nothing runs Xcode's extractor, and a key the
    # catalog does not carry falls back to the literal — silently, in English,
    # in every locale. Twenty-one keys shipped that way and only a Spanish
    # screenshot found them (HL-046).
    #
    # Only non-interpolated literals are checked. An interpolated one keys as a
    # format string whose specifiers depend on the interpolated *types*
    # (`%@` vs `%lld`), and picking the right one is the type-checker knowledge
    # this script's header says it does not have. Those are HL-008's
    # `String(localized:)` re-cuts anyway, which rule 4 does check.
    catalog_path, catalog_keys = catalog_for(path)
    if catalog_keys is not None:
        checked = [(st, ct, ct, catalog_path, catalog_keys)
                   for st, _, ct in find_calls(text, AUTOKEY_CALLS)]
        # `String(localized:)` and `LocalizedStringResource` name their bundle,
        # and the bundle decides which catalog has to carry the key. Inside a
        # target, that is the target's own. Inside LaborKit, `bundle: .module`
        # is the package's catalog and anything else resolves against
        # `Bundle.main` — whichever process loaded the framework, app or widget
        # extension, so the key is accepted in either. LaborKit carries one
        # such call (the App Intent title) on purpose.
        for name in ("String", "LocalizedStringResource"):
            for st, _, ct in find_calls(text, [name]):
                body = ct[ct.index("(") + 1:-1].lstrip()
                arg_text = ct
                if name == "String":
                    if not body.startswith("localized:"):
                        continue
                    arg_text = "(" + body[len("localized:"):]
                if IN_PACKAGE(path) and ".module" not in "".join(top_level_args(body)):
                    checked.append((st, ct, arg_text, MAIN_BUNDLE_LABEL, ANY_KEYS))
                else:
                    checked.append((st, ct, arg_text, catalog_path, catalog_keys))
        for start, snippet, arg_text, want_path, want_keys in checked:
            literal = leading_literal(arg_text)
            # A literal with no letter of its own has nothing to translate, and
            # a catalog entry for it would be nine identical copies of itself:
            # the "·" separator, the "5-1-1" and "0:38" figures the How It Works
            # art prints, and — the reason the test runs on the text *between*
            # the interpolations — `Text("\(prefix)\(direction)\(suffix)")`,
            # which glues three already-localized pieces and keys to nothing.
            if literal is None:
                continue
            if not any(c.isalpha() for c in "".join(split_interpolations(literal))):
                continue
            if not catalog_match(literal, want_keys):
                violations.append((f"key absent from {want_path}", path,
                                    line_of(text, start),
                                    snippet.splitlines()[0][:140]))

    # --- Rule 5: a literal written into a `String`-typed struct property. ----
    # `Text` renders a `String` through its *verbatim* initializer, so a literal
    # that reaches the screen this way is unreachable by any catalog — the
    # INTERVAL/DURATION/PATTERN/APART/LONG/HOLDING defect, which every rule
    # above misses because mono-caps vocabulary is not prose and the call site
    # is a struct initializer, not `Text`.
    for start, _, call_text in find_calls(text, sorted(STRING_PROP_STRUCTS)):
        props = STRING_PROP_STRUCTS[re.match(r"\w+", call_text).group(0)]
        for arg in top_level_args(call_text[call_text.index("(") + 1:-1]):
            m = re.match(r'([A-Za-z_]\w*)\s*:\s*"', arg)
            if m and m.group(1) in props:
                violations.append(("String literal into a String property "
                                    "(renders verbatim, never localized)", path,
                                    line_of(text, start), arg.splitlines()[0][:140]))

if violations:
    print("FAIL — user-facing literal(s) outside a String Catalog:")
    for rule, path, line, snippet in violations:
        print(f"  {path}:{line}: [{rule}] {snippet}")
    sys.exit(1)

print("PASS — no user-facing literals outside a String Catalog (Hushlight, HushlightWidgets, LaborKit)")
PYEOF
