#!/usr/bin/env python3
"""HL-008 · German (de).

Vocabulary:
  provider           → deine Hebamme oder Ärztin   (German maternity care is
                       midwife-led; a neutral "Fachperson" reads Swiss/administrative)
  labor and delivery → den Kreißsaal
  guideline          → die Regel
  stretch            → die Serie
  apart              → Abstand
  slip               → ein Fehlstart
  Start / End        → Start / Ende

Register: `du`, not `Sie` — the app speaks quietly to one person at 3am, and `Sie`
would put a counter between them. No imperatives in the verdict: "Jetzt anzurufen ist
vernünftig", never "Ruf an". German is the length stress case (HL-006's pseudolocale
leg exists for it), so the compound-heavy phrasings are chosen short where a choice
existed — `Abstand` over `zeitlicher Abstand`, `Dauer` over `Kontraktionsdauer`.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "Timer",
    "Go": "Gehe zu",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "Kein Mail-Programm auf diesem Gerät. Schreib an:",
    "This device cannot place calls. The number:": "Dieses Gerät kann nicht anrufen. Die Nummer:",
    "Copy address": "Adresse kopieren",
    "Copy number": "Nummer kopieren",
    "Copies the address": "Kopiert die Adresse",
    "Copies the number": "Kopiert die Nummer",
    "This stretch": "Diese Phase",
    "Each one you time appears here as it happens, with the gap since the one before.": "Jede gemessene Wehe erscheint hier sofort, mit dem Abstand zur vorigen.",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "Dieses iPad führt seine eigene Aufzeichnung. Nichts davon wird mit deinem iPhone oder mit irgendjemandem geteilt.",
    "Start": "Start", "End": "Ende", "Call": "Anrufen", "Copy": "Kopieren",
    "More": "Mehr", "Share": "Teilen", "Copied": "Kopiert", "Timing": "Läuft",
    "Guidance": "Hinweise", "Contractions": "Wehen", "For the call": "Für den Anruf",
    "How it works": "So funktioniert es", "One button": "Ein Knopf",
    "Yours alone": "Nur deins", "Report a problem": "Problem melden",
    "What this app is": "Was diese App ist", "Your guideline": "Deine Regel",
    "Start contraction": "Wehe starten",
    "End contraction": "Wehe beenden", "Tap when it begins": "Tippe, wenn sie beginnt",
    "Tap when it ends": "Tippe, wenn sie endet", "Clear all history?": "Gesamten Verlauf löschen?",
    "Call your provider": "Ruf deine Hebamme oder Ärztin an",
    "Heartbeat while timing": "Pulsschlag während der Messung",
    "Breath pacer while timing": "Atemtakt während der Messung",
    "Interval is start-to-start": "Der Abstand zählt von Beginn zu Beginn",
    "The timeline reads downward": "Die Zeitleiste liest sich nach unten",
    "Lock the phone freely": "Sperr das Telefon ruhig",
    "Your provider or L&D number": "Deine Hebamme, Ärztin oder die Nummer vom Kreißsaal",
    "Your provider or labor and delivery number": "Deine Hebamme, Ärztin oder die Nummer vom Kreißsaal",
    "Call right away — pattern aside": "Sofort anrufen — unabhängig vom Muster",
    "Nothing logged yet.": "Noch nichts erfasst.",
    "No contractions yet.": "Noch keine Wehen.",
    "It looks like time.": "Es sieht nach dem Moment aus.",
    "History": "Verlauf", "Done": "Fertig", "Cancel": "Abbrechen", "Delete": "Löschen",
    "Undo": "Widerrufen", "Merge Up": "Mit der vorherigen verbinden",
    "Got it": "Verstanden", "Keep a copy": "Kopie behalten",
    "Clear the instrument": "Instrument leeren",
    "Clear All History…": "Gesamten Verlauf löschen…",
    "Save a copy first…": "Zuerst eine Kopie sichern…",
    "Clear Everything": "Alles löschen",
    "Privacy policy": "Datenschutz", "Support": "Hilfe",
    "Rate on the App Store": "Im App Store bewerten",
    "CONTRACTIONS": "WEHEN", "NOW": "JETZT", "RUNNING": "LÄUFT",
    "LOCK SCREEN": "SPERRBILDSCHIRM", "1 H AGO": "VOR 1 STD",
    "INTERVAL": "Abstand", "DURATION": "Dauer", "PATTERN": "Muster",
    "APART": "Abstand", "LONG": "Dauer", "HOLDING": "Anhaltend",
    "SINCE %@": "SEIT %@", "SINCE YESTERDAY %@": "SEIT GESTERN %@",
    "SINCE %@ %@": "SEIT %@ %@", "LAST %@ AGO": "VOR %@",
    "%lld TOTAL": "%lld INSGESAMT",
    "CTX": "WEH", "AVG %@ APART · %lld": "Ø %@ ABSTAND · %lld",
    "LAST %@ APART · %lld": "LETZT %@ ABSTAND · %lld",
    "%lld logged": "%lld erfasst",
    "Averaging %@ apart, %@": "Im Schnitt %@ Abstand, %@",
    "Last gap %@, %@": "Letzter Abstand %@, %@",
    "No contractions yet": "Noch keine Wehen",
    "Opens guidance": "Öffnet die Hinweise",
    "Starts timing a contraction": "Beginnt die Messung einer Wehe",
    "Ends the contraction being timed": "Beendet die laufende Wehe",
    "Opens the clear-history confirmation": "Öffnet die Bestätigung zum Löschen des Verlaufs",
    "Copies this sentence": "Kopiert diesen Satz",
    "Shows the last stretch, to read or share": "Zeigt die letzte Serie zum Lesen oder Teilen",
    "Shows one sentence with the pattern, to read or share": "Zeigt einen Satz mit dem Muster zum Lesen oder Teilen",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "Öffnet das Teilen-Menü mit diesem Satz und allen Wehen dieser Serie",
    "Drafts an email you can review before sending": "Entwirft eine E-Mail, die du vor dem Senden prüfen kannst",
    "Removes the slip. Undo is in History.": "Entfernt den Fehlstart. Widerrufen findest du im Verlauf.",
    "%@.": "%@.", "%@, %@": "%@, %@", "in %@": "in %@", "on %@": "am %@", "out %@": "aus %@",
    "Call %@": "%@ anrufen", "%@ apart": "%@ Abstand", "since %@": "seit %@",
    "lasted %@": "dauerte %@", "lasting %@": "mit %@",
    "Started %@": "Begann %@", "Recorded %@": "Erfasst %@", "Guideline %@": "Regel %@",
    "going for %@": "läuft seit %@", "still running": "läuft noch",
    "since %@ at %@": "seit %@ um %@", "under a minute": "unter einer Minute",
    "average %@ long": "im Schnitt %@ lang", "average %@ apart": "im Schnitt %@ Abstand",
    "ranging %@ to %@": "von %@ bis %@", "averaging %@ apart": "im Schnitt %@ Abstand",
    "Contractions, %@": "Wehen, %@", "Last stretch, %@": "Letzte Serie, %@",
    "Last stretch: %@": "Letzte Serie: %@",
    "Last stretch, %@ over %@": "Letzte Serie, %@ über %@",
    "Last stretch: %@ over %@": "Letzte Serie: %@ über %@",
    "since yesterday at %@": "seit gestern um %@",
    "closer than an hour ago": "enger als vor einer Stunde",
    "farther apart than an hour ago": "weiter auseinander als vor einer Stunde",
    "not enough evidence yet": "noch nicht genug Anhaltspunkte",
    "not enough contractions yet": "noch nicht genug Wehen",
    "%@ after the previous one": "%@ nach der vorherigen",
    "contractions in the last hour": "Wehen in der letzten Stunde",
    "over three minutes — check this one": "über drei Minuten — bitte prüfen",
    "under twenty seconds — likely a slip, check this one":
        "unter zwanzig Sekunden — wahrscheinlich ein Fehlstart, bitte prüfen",
    "Last contraction ended %@ ago": "Die letzte Wehe endete vor %@",
    "Last contraction ended %@ ago.": "Die letzte Wehe endete vor %@.",
    "Contractions, last one ended %@ ago": "Wehen, die letzte endete vor %@",
    "Contractions, %@, last one ended %@ ago": "Wehen, %@, die letzte endete vor %@",
    "Not enough in the last hour to average.": "Zu wenige in der letzten Stunde für einen Schnitt.",
    "Timing this contraction — nothing else in the last hour.": "Diese Wehe läuft — sonst nichts in der letzten Stunde.",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "Letzte Wehe vor %@. Zu wenige in der letzten Stunde für einen Schnitt.",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "Letzte Wehe vor %@ — zu wenige in der letzten Stunde für einen Schnitt.",
    "Averaging %@ apart, %@ — was %@.": "Im Schnitt %@ Abstand, %@ — war %@.",
    "Averaging every %@, lasting %@, for %@.": "Alle %@ im Schnitt, mit %@, seit %@.",
    "Recorded %@ — likely a slip.": "Erfasst %@ — wahrscheinlich ein Fehlstart.",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "Erfasst %@ — wahrscheinlich ein Fehlstart. Sie ist bereits aus den Mittelwerten heraus.",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "Über drei Minuten. Das heißt meist, dass ein Endtipp fehlt. Sie jetzt zu beenden stellt sie neben die Mittelwerte.",
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "Noch nicht bei %@ — Dauer und Stunde stimmen; der Abstand liegt bei %@, und die Regel verlangt %@ oder enger.%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "Noch nicht bei %@. Der Abstand liegt zwischen %@ und %@; die Regel verlangt %@ oder enger. Dauer und Stunde stimmen.%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "Noch nicht bei %@. Diese Serie läuft ununterbrochen seit %@; die Regel verlangt eine Stunde. Abstand und Dauer stimmen.%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "Noch nicht bei %@ — Abstand und Dauer stimmen; diese Serie läuft ununterbrochen seit %@, und die Regel verlangt eine Stunde.%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "Noch nicht bei %@. Die Wehen dauern im Schnitt %@; die Regel verlangt etwa eine Minute. Abstand und Stunde stimmen.%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "Noch nicht bei %@ — Abstand und Stunde stimmen; die Wehen dauern im Schnitt %@, und die Regel verlangt etwa eine Minute.%@",
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Das erfüllt die %@-Regel, die viele Fachleute verwenden. Jetzt deine Hebamme oder Ärztin anzurufen ist vernünftig — ihre Anweisungen gelten zuerst.",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Das erfüllte die %@-Regel, die viele Fachleute verwenden. Jetzt deine Hebamme oder Ärztin anzurufen ist vernünftig — ihre Anweisungen gelten zuerst.",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "Das erfüllte die %@-Regel, die viele Fachleute verwenden — gerade läuft eine. Jetzt deine Hebamme oder Ärztin anzurufen ist vernünftig — ihre Anweisungen gelten zuerst.",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "Das erfüllte die %@-Regel, die viele Fachleute verwenden — letzte Wehe vor %@. Jetzt deine Hebamme oder Ärztin anzurufen ist vernünftig — ihre Anweisungen gelten zuerst.",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "Das ist enger, als die %@-Regel verlangt, und vor der Stunde, die sie ebenfalls verlangt. Jetzt deine Hebamme oder Ärztin anzurufen ist vernünftig — ihre Anweisungen gelten zuerst.",
    "Your water breaks — note the time and the color of the fluid.":
        "Die Fruchtblase platzt — notiere die Uhrzeit und die Farbe der Flüssigkeit.",
    "Bleeding, more than spotting.": "Blutung, mehr als Schmierblutung.",
    "The baby is moving less than usual.": "Das Baby bewegt sich weniger als sonst.",
    "Regular contractions before 37 weeks.": "Regelmäßige Wehen vor 37 Wochen.",
    "Anything that feels wrong to you.": "Alles, was sich für dich falsch anfühlt.",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "Nichts davon wartet auf eine Uhr. Ruf direkt deine Hebamme, deine Ärztin oder den Kreißsaal an.",
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "Fachleute raten unterschiedlich — ein zweites Kind, die Entfernung zur Klinik und deine Vorgeschichte verschieben das alles. Wenn du eine Regel bekommen hast, trag sie hier ein und halte dich an ihre.",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "Bleibt auf diesem Telefon. Einmal gesetzt, erscheint ein Anruf-Knopf neben der Einschätzung auf der Uhr und unter der Liste — damit der Anruf, den diese App immer wieder nahelegt, ein Tipp ist und keine Suche in den Kontakten um 3 Uhr nachts.",
    "A soft pulse every 15 seconds while a contraction is timed":
        "Ein sanfter Impuls alle 15 Sekunden, während eine Wehe gemessen wird",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "Damit das Telefon mit dem Display nach unten oder in der Tasche liegen kann und trotzdem verlässlich bleibt. Aus, außer du willst es; still im Stromsparmodus.",
    "Counted breaths under the timer — in for 4, out for 6":
        "Gezählte Atemzüge unter der Uhr — 4 ein, 6 aus",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "Ein langsamer Takt zum Mitatmen, während eine Wehe gemessen wird. Das Leuchten hält denselben Rhythmus.",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "Alle 5 Minuten, etwa eine Minute lang, eine Stunde lang — die verbreitetste Regel. Fachleute raten unterschiedlich; das Feld auf der Uhr setzt deine. Wenn dein Muster sie wirklich erfüllt, sagt die App es und schlägt den Anruf vor.",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "Kein Konto, keine Werbung, kein Netz. Alles bleibt auf diesem Telefon, und Gesamten Verlauf löschen entfernt es, wann immer du willst.",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "Entwirft eine E-Mail, die du vor dem Senden lesen und ändern kannst. Deine Wehenzeiten sind nie enthalten.",
    "Free forever. No account. Works in airplane mode.": "Für immer kostenlos. Kein Konto. Funktioniert im Flugmodus.",
    "Free forever · no account · works in airplane mode": "Für immer kostenlos · kein Konto · funktioniert im Flugmodus",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "Tippe auf den Balken, wenn eine Wehe beginnt, und noch einmal, wenn sie endet. Das ist alles. Vertipper korrigierst du im Verlauf — streichen zum Löschen, und Widerrufen nimmt den letzten Tipp zurück.",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "Tippe auf den Knopf, wenn eine beginnt — alles darüber baut auf diesem einen Tipp auf. Das Feld oben hält die Regel, die du bekommen hast.",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "Die Messung beginnt beim Tippen, und das Tippen kommt ein paar Sekunden nach der Wehe — die erfassten Dauern liegen also etwas hinter der gefühlten Minute. Die Dauerprüfung berücksichtigt das; die Zahlen auf der Uhr bleiben genau das, was erfasst wurde.",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "Die neueste oben, der Abstand zwischen jedem Paar genau dort gedruckt, wo er entstand. Zahlen bleiben Striche, bis genug da ist, um etwas zu bedeuten — ein Strich ist ehrlich, eine Vermutung nicht.",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "Die Messung läuft über die Uhr, nicht über den Bildschirm. Sobald ein Muster läuft, sitzt der Knopf auch auf dem Sperrbildschirm — starten und beenden ohne Entsperren.",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "Jede Wehe, die du misst, erscheint hier mit ihrer Dauer und dem Abstand zur vorherigen.",
    "History has every contraction. The next tap starts a new stretch.":
        "Der Verlauf enthält jede Wehe. Der nächste Tipp beginnt eine neue Serie.",
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "Eine Stoppuhr mit Rechenteil. Sie misst Wehen und meldet das Muster an der Regel, die du gewählt hast. Sie diagnostiziert keine Geburt und ist keine medizinische Beratung — die Anweisungen deiner Hebamme oder Ärztin gelten immer zuerst. Im Zweifel: anrufen.",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "Alles bleibt auf diesem Telefon. Kein Konto, keine Analyse, nichts wird irgendwohin gesendet.",
    "every %@ on average": "im Schnitt alle %@",
    "every %@ on average (ranging %@–%@)": "im Schnitt alle %@ (von %@ bis %@)",
    "lasting about %@": "mit etwa %@",
    "Hushlight problem report": "Hushlight Problemmeldung",
    "Describe what happened above this line.": "Beschreibe über dieser Zeile, was passiert ist.",
    "— About this app and phone (you can delete any line) —":
        "— Über diese App und dieses Telefon (du kannst jede Zeile löschen) —",
    "App: Hushlight %@": "App: Hushlight %@", "System: %@ · %@": "System: %@ · %@",
    "Guideline: %@": "Regel: %@", "Recorded: %@ across %@": "Erfasst: %@ in %@",
    "Live Activity on screen: %@": "Live-Aktivität auf dem Bildschirm: %@",
    "yes": "ja", "no": "nein",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "Deine Wehenzeiten sind nicht in dieser E-Mail. Falls eine Korrektur sie braucht, fragen wir nach, und sie zu senden bleibt deine Entscheidung.",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "Ein Abstand, der schwankt, bevor er sich einpendelt, sieht bei frühen Serien oft so aus. Eine hin und wieder gemessene Serie zeigt dasselbe Muster — das braucht keine ununterbrochene Beobachtung.",
}

PLURALS = {
    "%lld contraction": {"one": "%lld Wehe", "other": "%lld Wehen"},
    "%lld episode": {"one": "%lld Episode", "other": "%lld Episoden"},
    "%lld contraction in this stretch": {"one": "%lld Wehe in dieser Serie", "other": "%lld Wehen in dieser Serie"},
    "%lld minutes": {"one": "%lld Minute", "other": "%lld Minuten"},
    "%lld seconds": {"one": "%lld Sekunde", "other": "%lld Sekunden"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "one": "Läuft noch — über %lld Minute heißt meist, dass ein Endtipp fehlt. Sie jetzt zu beenden stellt sie neben die Mittelwerte.",
        "other": "Läuft noch — über %lld Minuten heißt meist, dass ein Endtipp fehlt. Sie jetzt zu beenden stellt sie neben die Mittelwerte.",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {"hoursArg": {"one": "%1$lld Stunde", "other": "%1$lld Stunden"},
                 "minutesArg": {"one": "%2$lld Minute", "other": "%2$lld Minuten"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {"minutesArg": {"one": "%1$lld Minute", "other": "%1$lld Minuten"},
                 "secondsArg": {"one": "%2$lld Sekunde", "other": "%2$lld Sekunden"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@: Wehen alle %2$#@minutesArg@ oder enger, jede etwa eine Minute lang, eine Stunde lang ohne lange Pause. Die Uhr liest alle drei aus deinen Tipps und sagt es, wenn das Muster da ist.",
        "args": {"minutesArg": {"one": "%2$lld Minute", "other": "%2$lld Minuten"}},
    },
}

NEVER_SAYS = [
    "du bist in den wehen",
    "die geburt hat begonnen",
    "das baby kommt",
    "du musst nicht",
    "du musst",
    "fahr ins krankenhaus",
    "geh ins krankenhaus",
]


# ---- HL-046 -----------------------------------------------------------------
# The keys the compiler's own extractor found once `SWIFT_EMIT_LOC_STRINGS` was
# turned on. Sixteen of them replace a near-miss the catalog had carried since
# HL-008 and which had therefore never once resolved: `%@` where the code passes
# an integer, a dropped leading space, a copy edit the key was never updated for.
# Positional `%N$` specifiers appear wherever this language reorders the
# arguments — without them printf consumes them in written order and prints the
# count where the interval belongs.
TRANSLATIONS.update({
    ' (was %@).':
        ' (war %@).',
    ' — %@ apart against %@ on %@.':
        ' — %@ Abstand gegenüber %@ am %@.',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '„Alle 5 Minuten“ misst den Abstand zwischen den Anfängen der Wehen — so, wie Fachleute messen. Dauer ist, wie lang jede einzelne ist; Muster ist, wie lange diese Serie schon läuft. Die Messung beginnt beim Tippen, deshalb liegen die aufgezeichneten Längen etwas hinter der gefühlten Wehe.',
    '%@ before the next one':
        '%@ vor der nächsten',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@, %@.',
    '%@, met':
        '%@, erfüllt',
    '%@, not yet':
        '%@, noch nicht',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        'Eine Wehe läuft gerade. Das löscht sie zusammen mit allen anderen Wehen auf diesem Telefon. Es gibt kein Zurück.',
    'Averaging %@ apart — ':
        'Im Schnitt %@ Abstand — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        'Alle %@ im Schnitt über %lld gemessene Wehen, seit %@.',
    'Contraction %lld, lasted %@, at %@':
        'Wehe %lld, dauerte %@, um %@',
    'Contraction %lld, running, %@':
        'Wehe %lld, läuft, %@',
    'Contractions %@ — %lld so far.':
        'Wehen %@ — %lld bisher.',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        'Absturzberichte auf diesem Telefon: %lld · Hänger: %lld',
    'Delete %lld Flagged':
        '%lld markierte löschen',
    'Delete %lld Flagged…':
        '%lld markierte löschen…',
    'Delete flagged records?':
        'Markierte Einträge löschen?',
    'Guideline':
        'Regel',
    'Last stretch, %@, %@':
        'Letzte Serie, %@, %@',
    'Last stretch, %@, %@ over %@':
        'Letzte Serie, %@, %@ über %@',
    'Last stretch, %@: %@':
        'Letzte Serie, %@: %@',
    'Last stretch, %@: %@ over %@':
        'Letzte Serie, %@: %@ über %@',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Noch nicht bei %@ — im Schnitt %@ Abstand und %@ lang über %lld gemessene Wehen.%@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        'Noch nicht bei %@ — im Schnitt %@ Abstand über %lld gemessene Wehen; noch nicht genug beendete für einen Schnitt ihrer Dauer.',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Noch nicht bei %@. Im Schnitt %@ Abstand und %@ lang über %lld gemessene Wehen.%@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        'Noch nicht bei %@. Im Schnitt %@ Abstand über %lld gemessene Wehen. Noch nicht genug beendete für einen Schnitt ihrer Dauer.',
    'Optional':
        'Optional',
    'Start or stop a contraction':
        'Startet oder stoppt eine Wehe',
    "The guideline's three legs, over the last hour":
        'Die drei Teile der Regel, über die letzte Stunde',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Das sind die Einträge, die bereits mit CHECK markiert sind — ein um mehr als drei Minuten verpasster Stopp-Tipp oder ein Tipp unter zwanzig Sekunden. Gemessene Wehen bleiben unberührt, und Widerrufen holt alle zurück.',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        'Diese Durchschnitte gelten für die ganze Serie. Die Zahlen des Timers gelten für die letzte Stunde, sie können sich also unterscheiden, während die Wehen enger werden.',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        'Dreißig Sekunden — und es wartet oben unter dem Fragezeichen, wann immer du es wiederhaben willst.',
    'This deletes every contraction on this phone. There is no undo.':
        'Das löscht alle Wehen auf diesem Telefon. Es gibt kein Zurück.',
    'This stretch is ':
        'Diese Serie ist ',
    'This stretch is %@, %@ apart against %@ on %@.':
        'Diese Serie ist %@, %@ Abstand gegenüber %@ am %@.',
    'This stretch: %@.':
        'Diese Serie: %@.',
    'Timing this contraction — %lld in the last hour.':
        'Diese Wehe läuft — %lld in der letzten Stunde.',
    'about the same as your last stretch':
        'ungefähr wie deine letzte Serie',
    'closer together than your last stretch':
        'enger als deine letzte Serie',
    'farther apart than your last stretch':
        'weiter auseinander als deine letzte Serie',
    'now':
        'jetzt',
    'one hour ago':
        'vor einer Stunde',
    'over %@':
        'über %@',
})


# ---- HL-046 · the instrument band -------------------------------------------
# A Spanish screenshot of the History screen, taken to check the work above,
# still read `THIS STRETCH · AVG 5:00 APART · 1:02 LONG · OVER 1 H 5 M`. Mono-caps
# instrument vocabulary carries no lowercase letter, so the textual lint's
# prose test could never see it, and the strings were plain `String`s that no
# extractor could either. Decision 0062 already says this vocabulary translates;
# these are the words it had left. `CHECK` gets this language's own flag word,
# which is why the sweep dialog's copy is restated here to match it.
TRANSLATIONS.update({
    '%@ LONG':
        '%@ LANG',
    '%@ · FROM %@ · %lld':
        '%@ · SEIT %@ · %lld',
    '%lld H':
        '%lld STD',
    '%lld H %lld M':
        '%lld STD %lld MIN',
    '%lld M':
        '%lld MIN',
    'CHECK · OVER %lld MIN':
        'PRÜFEN · ÜBER %lld MIN',
    'CHECK · UNDER %lld S':
        'PRÜFEN · UNTER %lld S',
    'OVER %@':
        'ÜBER %@',
    'THIS STRETCH · AVG %@ APART':
        'DIESE SERIE · Ø %@ ABSTAND',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Das sind die Einträge, die bereits mit PRÜFEN markiert sind — ein um mehr als drei Minuten verpasster Stopp-Tipp oder ein Tipp unter zwanzig Sekunden. Gemessene Wehen bleiben unberührt, und Widerrufen holt alle zurück.',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": 'Wehe',
    "Start or stop a contraction": 'Eine Wehe starten oder beenden',
    "One tap starts the timing; the next ends it.": 'Ein Tipp startet die Messung, der nächste beendet sie.',
    "Open Hushlight to time this one.": 'Öffne Hushlight, um diese Wehe zu messen.',
})
