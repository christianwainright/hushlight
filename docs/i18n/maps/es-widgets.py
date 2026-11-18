#!/usr/bin/env python3
"""HL-008 · Spanish (es) for the Live Activity's catalog.

Two notes that are decisions rather than lookups:

  * English's `one` plural buckets are deliberately pinned to read like `other`
    ("1 minutes"), because the QA harness hard-parses that shape — HL-007
    documents the compromise at the pin. **Spanish gets real CLDR categories**,
    which is exactly what that note says other languages get: "1 minuto",
    "2 minutos". Copying English's pinned oddity here would export a bug.
  * `Start` / `End` are the same two words the app's own slab uses, and they must
    stay the same two words on the Lock Screen — a reader glancing at a phone at
    3am should not meet a synonym. `Iniciar` / `Terminar`.
"""

TRANSLATIONS = {
    "%lld logged": "%lld registradas",
    "Averaging %@ apart, %@": "En promedio %@ de separación, %@",
    "Last gap %@, %@": "Último intervalo %@, %@",
    "No contractions yet": "Aún no hay contracciones",
    "Start": "Iniciar",
    "End": "Terminar",
    "Start contraction": "Iniciar contracción",
    "End contraction": "Terminar contracción",
}

PLURALS = {
    "%lld contraction": {"one": "%lld contracción", "other": "%lld contracciones"},
    "%lld minutes": {"one": "%lld minuto", "other": "%lld minutos"},
    "%lld seconds": {"one": "%lld segundo", "other": "%lld segundos"},
}

SUBSTITUTIONS = {
    "%lld minutes %lld seconds": {
        # Spanish keeps the same order — "2 minutos 30 segundos" — so the outer
        # placeholders stay in position.
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {
            "minutesArg": {"one": "%1$lld minuto", "other": "%1$lld minutos"},
            "secondsArg": {"one": "%2$lld segundo", "other": "%2$lld segundos"},
        },
    },
}


# ---- HL-046 · backfill ------------------------------------------------------
# HL-008 added these thirty-five keys straight into the catalogs and never wrote
# them back here, so this file stopped being the source it claims to be and the
# coverage check could not see the gap. Values are the Spanish already shipping.
TRANSLATIONS.update({
    'AVG %@ APART · %lld': 'PROM %@ DE SEPARACIÓN · %lld',
    'CONTRACTIONS': 'CONTRACCIONES',
    'CTX': 'CTX',
    'LAST %@ APART · %lld': 'ÚLT %@ DE SEPARACIÓN · %lld',
})


# HL-065 · Control Center, the Action button and Siri.
TRANSLATIONS.update({
    'Contraction': 'Contracción',
    'Start or stop a contraction': 'Iniciar o terminar una contracción',
    'One tap starts the timing; the next ends it.': 'Un toque empieza a cronometrar; el siguiente lo termina.',
})
