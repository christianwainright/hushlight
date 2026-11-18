#!/usr/bin/env python3
"""HL-008 · Spanish (es) for LaborKit's catalog.

Register notes, because these are judgements and not lookups:

  * "your provider" is US-healthcare framing and "tu proveedor" is a calque that
    reads institutional. `tu profesional` covers médico / partera / obstetra
    without naming a system, which is what the English does too.
  * "labor and delivery" is a US ward name. `la sala de partos` is the room a
    Spanish speaker would actually be told to call.
  * The English deliberately avoids imperatives — "Calling your provider now is
    reasonable", not "Call your provider". Spanish keeps the nominalised form:
    "Llamar a tu profesional ahora es razonable". Never "Llama a".
  * "When unsure, call." is the one near-imperative in the source and stays soft:
    "Ante la duda, llama." reads as counsel rather than instruction.
  * Em dashes are load-bearing punctuation in this app and survive verbatim.
"""

TRANSLATIONS = {
    # ---- load-bearing (gated by LanguageGateTests) --------------------------
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "Un cronómetro con aritmética. Mide las contracciones e informa el patrón según la pauta que elegiste. No diagnostica el parto y no es consejo médico — las indicaciones de tu profesional siempre van primero. Ante la duda, llama.",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "Todo se queda en este teléfono. Sin cuenta, sin analítica, nada se envía a ningún lado.",

    # ---- call summary, spoken aloud over the phone --------------------------
    "every %@ on average": "cada %@ en promedio",
    "every %@ on average (ranging %@–%@)": "cada %@ en promedio (entre %@ y %@)",
    "lasting about %@": "de unos %@ de duración",
    "since %@": "desde las %@",

    # ---- Report a problem email --------------------------------------------
    "Hushlight problem report": "Informe de problema de Hushlight",
    "Describe what happened above this line.": "Describe lo que pasó encima de esta línea.",
    "— About this app and phone (you can delete any line) —":
        "— Sobre esta app y este teléfono (puedes borrar cualquier línea) —",
    "App: Hushlight %@": "App: Hushlight %@",
    "System: %@ · %@": "Sistema: %@ · %@",
    "Guideline: %@": "Pauta: %@",
    "Recorded: %@ across %@": "Registrado: %@ en %@",
    "Live Activity on screen: %@": "Actividad en vivo en pantalla: %@",
    "yes": "sí",
    "no": "no",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "Los horarios de tus contracciones no están en este correo. Si hacen falta para resolverlo, te lo pediremos, y enviarlos seguirá siendo decisión tuya.",

    # ---- the early-irregular sentence (decision 0041) -----------------------
    # Every word is about the timing data, never about her body: "how early
    # stretches often look", not "how early labor feels".
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "Un espaciado que varía antes de asentarse es como suelen verse las primeras rachas. Una racha cronometrada de vez en cuando muestra el mismo patrón — esto no necesita vigilancia continua.",
}

PLURALS = {
    "%lld contraction": {"one": "%lld contracción", "other": "%lld contracciones"},
    "%lld episode": {"one": "%lld episodio", "other": "%lld episodios"},
}


# ---- HL-046 -----------------------------------------------------------------
# The keys the compiler's own extractor found once `SWIFT_EMIT_LOC_STRINGS` was
# turned on. Sixteen of them replace a near-miss the catalog had carried since
# HL-008 and which had therefore never once resolved: `%@` where the code passes
# an integer, a dropped leading space, a copy edit the key was never updated for.
# Positional `%N$` specifiers appear wherever this language reorders the
# arguments — without them printf consumes them in written order and prints the
# count where the interval belongs.
TRANSLATIONS.update({
    'Contractions %@ — %lld so far.':
        'Contracciones %@ — %lld hasta ahora.',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        'Informes de fallo guardados en este teléfono: %lld · Bloqueos: %lld',
    'Start or stop a contraction':
        'Inicia o detiene una contracción',
})


# HL-065 · Control Center, the Action button and Siri.
TRANSLATIONS.update({
    'Open Hushlight to time this one.': 'Abre Hushlight para cronometrar esta.',
    'Recorded %@': 'Registrada %@',
    'Timing': 'Cronometrando',
})
