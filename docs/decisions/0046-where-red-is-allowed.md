# 0046 · Where red is allowed, stated once

**Date:** 2026-08-26 · **Item:** the A1.3 walkthrough · **Status:** decided

## Context

CLAUDE.md's ratchet is absolute: *"No fear language, anywhere. The app never shouts;
red is not in its palette."* The palette obeys it — `PaletteContrastTests.noTokenIsRed`
walks every token in both appearances and fails if one lands in the alarm band.

But `role: .destructive` is not a token. It is a request to iOS, and iOS answers in
system red. There are three such requests in the app, and until now the rule governing
them lived in a single code comment on a fourth site (History's overflow menu item,
which deliberately drops the role). The walkthrough's lenses read that comment and
reached opposite conclusions about the other three — which is the signal that the rule
was never actually stated, only practised.

## Decision

**The app's own drawn surfaces carry no red. System-presented destructive affordances
keep the platform's.**

| Site | Who draws it | Ruling |
|---|---|---|
| The slip strip's `Delete` (`TimerScreen`) | **The app** — a capsule in its own bottom bar | **No role.** Red goes. |
| History's swipe-to-delete | iOS, in the swipe tray | Keeps `.destructive` |
| `Clear Everything` in the confirmation dialog | iOS, in a system dialog | Keeps `.destructive` |
| History's overflow menu item | The app, in its own menu | No role (already correct) |

## Rationale

**Why the app's own surfaces cannot use it.** The slip strip appears at the precise
moment a frightened woman has just made a mistake — a double tap that recorded six
seconds. The app's answer to that moment is a calm sentence and an offer. Rendering
the offer in the one colour this palette refuses turns a correction into an alarm, and
at accessibility sizes it becomes the loudest element on the screen: the walkthrough
caught it at AX5 dominating everything, including the contraction count. Nothing about
deleting a six-second mis-tap warrants the register the app reserves for nothing at all.

**Why system-presented ones keep it, and why that is not a loophole.** In a swipe tray
and a confirmation dialog, red is not decoration the app chose — it is the vocabulary
every other app on her phone has taught her, and it is doing safety work: it marks the
irreversible option in a list where the reversible one sits beside it. Replacing it
with this app's warm ember would make "delete every contraction on this phone, there is
no undo" *less* legible as the dangerous choice, not gentler. A ratchet that made an
irreversible action harder to distinguish would be protecting the palette at the user's
expense, which inverts what the ratchet is for.

The line is therefore not "red is fine when convenient" but: **the app never introduces
red into surfaces it composes; it does not fight the platform on surfaces the platform
composes for the purpose the platform's colour serves.**

**Rejected: purge all three.** Considered seriously, because the ratchet's wording is
absolute. It loses on the swipe tray and the dialog for the reason above — and a
destructive dialog button with no role also loses its keyboard/VoiceOver destructive
semantics, which is an accessibility regression traded for a tonal preference.

**Rejected: leave all three.** The slip strip is unambiguously the app's own chrome.
Leaving it would mean the ratchet stops at the first inconvenience, and the next agent
reads that as permission.

## Boundaries

No token changes; `noTokenIsRed` is untouched and still authoritative for the palette.
This entry governs `role:` only. Any future app-drawn control that wants a destructive
role must instead carry its weight in words, the way the confirmation dialog's own copy
already does ("There is no undo").
