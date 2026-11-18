#!/usr/bin/env python3
"""HL-008 · Spanish (es) for the app target's catalog — 149 keys.

The vocabulary held constant across every surface, decided once here so the app
does not drift between screens:

  provider          → profesional        (not "proveedor": a calque that reads as
                                          US insurance; "profesional" covers médico,
                                          partera and obstetra without naming a system)
  labor and delivery→ la sala de partos  (L&D is a US ward name)
  guideline         → pauta              (not "guía", which reads as a manual)
  stretch           → racha              (a run of contractions, not "tramo")
  contraction       → contracción
  apart             → de separación
  History / Guidance→ Historial / Orientación
  Start / End       → Iniciar / Terminar (identical to the Live Activity's words)
  slip              → toque suelto       (a stray tap, not a "resbalón")

Register rules carried from the English, which are the whole point:

  * **No imperatives in the verdict or the medical copy.** "Calling your provider
    now is reasonable" stays nominalised — "Llamar a tu profesional ahora es
    razonable" — never "Llama a tu profesional". The app reports; it does not order.
  * **No fear register.** "It looks like time." is deliberately flat, and
    "Parece que es el momento." matches it. Not "¡Ya es hora!".
  * **Em dashes are load-bearing** and survive verbatim, as do the ` · ` separators.
  * **A dash is honest, a guess isn't** — the em-dash-for-absent-figure rule
    (decisions 0022–0026) is grammar-independent and none of this touches it.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "Temporizador",
    "Go": "Ir a",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "Este dispositivo no tiene app de correo. Escribe a:",
    "This device cannot place calls. The number:": "Este dispositivo no puede llamar. El número:",
    "Copy address": "Copiar dirección",
    "Copy number": "Copiar número",
    "Copies the address": "Copia la dirección",
    "Copies the number": "Copia el número",
    "This stretch": "Esta racha",
    "Each one you time appears here as it happens, with the gap since the one before.": "Cada contracción que midas aparece aquí al momento, con el intervalo desde la anterior.",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "Este iPad guarda su propio registro. Nada de esto se comparte con tu iPhone ni con nadie.",
    # ---- buttons, chrome, short labels --------------------------------------
    "Start": "Iniciar",
    "End": "Terminar",
    "Call": "Llamar",
    "Copy": "Copiar",
    "More": "Más",
    "Share": "Compartir",
    "Copied": "Copiado",
    "Timing": "Cronometrando",
    "Guidance": "Orientación",
    "Contractions": "Contracciones",
    "For the call": "Para la llamada",
    "How it works": "Cómo funciona",
    "One button": "Un botón",
    "Yours alone": "Solo tuyo",
    "Report a problem": "Informar de un problema",
    "What this app is": "Qué es esta app",
    "Your guideline": "Tu pauta",
    "Start contraction": "Iniciar contracción",
    "End contraction": "Terminar contracción",
    "Tap when it begins": "Toca cuando empiece",
    "Tap when it ends": "Toca cuando termine",
    "Clear all history?": "¿Borrar todo el historial?",
    "Call your provider": "Llama a tu profesional",
    "Heartbeat while timing": "Latido mientras cronometra",
    "Breath pacer while timing": "Guía de respiración mientras cronometra",
    "Interval is start-to-start": "El intervalo va de inicio a inicio",
    "The timeline reads downward": "La línea de tiempo se lee hacia abajo",
    "Lock the phone freely": "Bloquea el teléfono sin problema",
    "Your provider or L&D number": "Tu profesional o el número de la sala de partos",
    "Your provider or labor and delivery number":
        "Tu profesional o el número de la sala de partos",
    "Call right away — pattern aside": "Llama de inmediato — al margen del patrón",
    "Nothing logged yet.": "Aún no hay nada registrado.",
    "No contractions yet.": "Aún no hay contracciones.",
    "It looks like time.": "Parece que es el momento.",

    # ---- VoiceOver labels and hints ----------------------------------------
    "Opens guidance": "Abre la orientación",
    "Starts timing a contraction": "Empieza a cronometrar una contracción",
    "Ends the contraction being timed": "Termina la contracción que se cronometra",
    "Opens the clear-history confirmation": "Abre la confirmación para borrar el historial",
    "Copies this sentence": "Copia esta frase",
    "Shows the last stretch, to read or share": "Muestra la última racha, para leer o compartir",
    "Shows one sentence with the pattern, to read or share":
        "Muestra una frase con el patrón, para leer o compartir",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "Abre el menú de compartir con esta frase y todas las contracciones de esta racha",
    "Drafts an email you can review before sending":
        "Redacta un correo que puedes revisar antes de enviar",
    "Removes the slip. Undo is in History.":
        "Quita el toque suelto. Deshacer está en el Historial.",

    # ---- readout, tape, timeline fragments ----------------------------------
    "%@.": "%@.",
    "%@, %@": "%@, %@",
    "in %@": "en %@",
    "on %@": "el %@",
    "out %@": "fuera %@",
    "Call %@": "Llamar a %@",
    "%@ apart": "%@ de separación",
    "since %@": "desde las %@",
    "lasted %@": "duró %@",
    "lasting %@": "de %@",
    "Started %@": "Empezó %@",
    "Recorded %@": "Registrada %@",
    "Guideline %@": "Pauta %@",
    "going for %@": "lleva %@",
    "still running": "aún en curso",
    "since %@ at %@": "desde %@ a las %@",
    "under a minute": "menos de un minuto",
    "average %@ long": "%@ de duración en promedio",
    "average %@ apart": "%@ de separación en promedio",
    "ranging %@ to %@": "entre %@ y %@",
    "averaging %@ apart": "%@ de separación en promedio",
    "Contractions, %@": "Contracciones, %@",
    "Last stretch, %@": "Última racha, %@",
    "Last stretch: %@": "Última racha: %@",
    "Last stretch, %@ over %@": "Última racha, %@ en %@",
    "Last stretch: %@ over %@": "Última racha: %@ en %@",
    "since yesterday at %@": "desde ayer a las %@",
    "closer than an hour ago": "más juntas que hace una hora",
    "farther apart than an hour ago": "más separadas que hace una hora",
    "not enough evidence yet": "aún no hay evidencia suficiente",
    "not enough contractions yet": "aún no hay suficientes contracciones",
    "%@ after the previous one": "%@ después de la anterior",
    "contractions in the last hour": "contracciones en la última hora",
    "over three minutes — check this one": "más de tres minutos — revisa esta",
    "under twenty seconds — likely a slip, check this one":
        "menos de veinte segundos — probablemente un toque suelto, revisa esta",
    "Last contraction ended %@ ago": "La última contracción terminó hace %@",
    "Last contraction ended %@ ago.": "La última contracción terminó hace %@.",
    "Contractions, last one ended %@ ago": "Contracciones, la última terminó hace %@",
    "Contractions, %@, last one ended %@ ago": "Contracciones, %@, la última terminó hace %@",
    "Not enough in the last hour to average.": "No hay suficientes en la última hora para promediar.",
    "Timing this contraction — nothing else in the last hour.":
        "Cronometrando esta contracción — nada más en la última hora.",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "La última contracción hace %@. No hay suficientes en la última hora para promediar.",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "La última contracción hace %@ — no hay suficientes en la última hora para promediar.",
    "Averaging %@ apart, %@ — was %@.": "%@ de separación en promedio, %@ — era %@.",
    "Averaging every %@, lasting %@, for %@.": "Cada %@ en promedio, de %@, durante %@.",

    # ---- the slip strip -----------------------------------------------------
    "Recorded %@ — likely a slip.": "Registrada %@ — probablemente un toque suelto.",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "Registrada %@ — probablemente un toque suelto. Ya está fuera de los promedios.",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "Más de tres minutos. Eso suele significar un toque de fin que no se dio. Terminarla ahora la aparta de los promedios.",

    # ---- the partial line, every branch -------------------------------------
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "Todavía no en %@ — la duración y la hora están; la separación va en %@, y la pauta pide %@ o menos.%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "Todavía no en %@. La separación va de %@ a %@; la pauta pide %@ o menos. La duración y la hora están.%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "Todavía no en %@. Esta racha lleva %@ sin interrupción; la pauta pide una hora. La separación y la duración están.%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "Todavía no en %@ — la separación y la duración están; esta racha lleva %@ sin interrupción, y la pauta pide una hora.%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "Todavía no en %@. Las contracciones promedian %@; la pauta pide alrededor de un minuto. La separación y la hora están.%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "Todavía no en %@ — la separación y la hora están; las contracciones promedian %@, y la pauta pide alrededor de un minuto.%@",

    # ---- the verdict, latched and live (LOAD-BEARING) -----------------------
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Eso cumple la pauta %@ que usan muchos profesionales. Llamar a tu profesional ahora es razonable — sus indicaciones van primero.",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Eso cumplió la pauta %@ que usan muchos profesionales. Llamar a tu profesional ahora es razonable — sus indicaciones van primero.",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "Eso cumplió la pauta %@ que usan muchos profesionales — ahora hay una en curso. Llamar a tu profesional ahora es razonable — sus indicaciones van primero.",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "Eso cumplió la pauta %@ que usan muchos profesionales — la última contracción hace %@. Llamar a tu profesional ahora es razonable — sus indicaciones van primero.",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "Eso es más junto de lo que pide la pauta %@, antes de la hora que también pide. Llamar a tu profesional ahora es razonable — sus indicaciones van primero.",

    # ---- the call-right-away card (LOAD-BEARING) ---------------------------
    "Your water breaks — note the time and the color of the fluid.":
        "Rompes aguas — anota la hora y el color del líquido.",
    "Bleeding, more than spotting.": "Sangrado, más que un manchado.",
    "The baby is moving less than usual.": "El bebé se mueve menos de lo habitual.",
    "Regular contractions before 37 weeks.": "Contracciones regulares antes de las 37 semanas.",
    "Anything that feels wrong to you.": "Cualquier cosa que sientas que no está bien.",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "Nada de esto espera a un cronómetro. Llama directamente a tu profesional o a la sala de partos.",

    # ---- Guidance prose -----------------------------------------------------
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "Cada profesional indica algo distinto — un segundo bebé, la distancia al hospital y tu historia mueven esto. Si el tuyo te dio una regla, ponla aquí y sigue la suya.",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "Se queda en este teléfono. Una vez guardado, aparece un botón de Llamar junto al veredicto en el cronómetro y bajo la lista de abajo — así la llamada que esta app sigue sugiriendo es un toque, no una búsqueda en Contactos a las 3 de la mañana.",
    "A soft pulse every 15 seconds while a contraction is timed":
        "Un pulso suave cada 15 segundos mientras se cronometra una contracción",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "Para que el teléfono pueda estar boca abajo o en un bolsillo y aun así ser fiable. Apagado salvo que lo quieras; en silencio en Modo de Bajo Consumo.",
    "Counted breaths under the timer — in for 4, out for 6":
        "Respiraciones contadas bajo el cronómetro — 4 al inspirar, 6 al espirar",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "Una cadencia lenta para respirar mientras se cronometra una contracción. El resplandor mantiene el mismo ritmo.",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "Cada 5 minutos, de alrededor de un minuto, durante una hora — la regla más usada. Los profesionales difieren; la ficha del cronómetro fija la tuya. Cuando tu patrón realmente la cumpla, la app lo dice y sugiere la llamada.",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "Sin cuenta, sin anuncios, sin red. Todo se queda en este teléfono, y Borrar Todo el Historial lo elimina cuando tú quieras.",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "Redacta un correo que puedes leer y editar antes de enviar. Los horarios de tus contracciones nunca se incluyen.",

    # ---- How It Works -------------------------------------------------------
    "Free forever. No account. Works in airplane mode.":
        "Gratis para siempre. Sin cuenta. Funciona en modo avión.",
    "Free forever · no account · works in airplane mode":
        "Gratis para siempre · sin cuenta · funciona en modo avión",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "Toca la barra cuando empiece una contracción y tócala otra vez cuando termine. Ese es todo el trabajo. Los toques equivocados se arreglan en el Historial — desliza para borrar, y Deshacer retira el último toque.",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "Toca el botón cuando empiece una — todo lo de arriba se construye desde ese toque. La ficha de arriba guarda la pauta que te dio tu profesional.",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "El cronómetro empieza en el toque, y el toque llega unos segundos después que la contracción — así que las duraciones registradas van un poco por detrás del minuto sentido. La comprobación de duración lo tiene en cuenta; las cifras del cronómetro se quedan exactamente en lo que se registró.",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "La más reciente arriba, con el intervalo entre cada par impreso justo donde ocurrió. Las cifras siguen siendo guiones hasta que haya suficiente para significar algo — un guion es honesto, una suposición no.",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "El cronómetro corre con el reloj, no con la pantalla. Cuando hay un patrón en marcha, el botón también vive en la pantalla de bloqueo — inicia y termina sin desbloquear.",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "Cada contracción que cronometras aparece aquí con su duración y el intervalo desde la anterior.",
    "History has every contraction. The next tap starts a new stretch.":
        "El Historial tiene todas las contracciones. El siguiente toque empieza una racha nueva.",
}

PLURALS = {
    "%lld contraction": {"one": "%lld contracción", "other": "%lld contracciones"},
    "%lld contraction in this stretch": {
        "one": "%lld contracción en esta racha",
        "other": "%lld contracciones en esta racha",
    },
    # English pins `one` to read like `other` for the harness (HL-007); Spanish
    # gets real CLDR categories, which is what that note says other languages get.
    "%lld minutes": {"one": "%lld minuto", "other": "%lld minutos"},
    "%lld seconds": {"one": "%lld segundo", "other": "%lld segundos"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "one": "Aún cronometrando — más de %lld minuto suele significar un toque de fin que no se dio. Terminarla ahora la aparta de los promedios.",
        "other": "Aún cronometrando — más de %lld minutos suele significar un toque de fin que no se dio. Terminarla ahora la aparta de los promedios.",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {
            "hoursArg": {"one": "%1$lld hora", "other": "%1$lld horas"},
            "minutesArg": {"one": "%2$lld minuto", "other": "%2$lld minutos"},
        },
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {
            "minutesArg": {"one": "%1$lld minuto", "other": "%1$lld minutos"},
            "secondsArg": {"one": "%2$lld segundo", "other": "%2$lld segundos"},
        },
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@: contracciones cada %2$#@minutesArg@ o menos, cada una de alrededor de un minuto, sostenidas durante una hora sin una pausa larga. El cronómetro lee las tres cosas de tus toques y lo dice cuando el patrón está.",
        "args": {
            "minutesArg": {"one": "%2$lld minuto", "other": "%2$lld minutos"},
        },
    },
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
    ' (was %@).':
        ' (era %@).',
    ' — %@ apart against %@ on %@.':
        ' — %@ de separación frente a %@ el %@.',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '«Cada 5 minutos» mide el hueco entre los comienzos de las contracciones — como lo miden los profesionales. Duración es cuánto dura cada una; Patrón es cuánto lleva esta racha. El cronómetro empieza en el toque, así que las duraciones registradas van un poco por detrás de la contracción sentida.',
    '%@ before the next one':
        '%@ antes de la siguiente',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@, %@.',
    '%@, met':
        '%@, cumplido',
    '%@, not yet':
        '%@, todavía no',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        'Se está cronometrando una contracción. Esto la elimina junto con todas las demás contracciones de este teléfono. No se puede deshacer.',
    'Averaging %@ apart — ':
        '%@ de separación en promedio — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        'Cada %@ en promedio en %lld contracciones cronometradas, durante %@.',
    'Contraction %lld, lasted %@, at %@':
        'Contracción %lld, duró %@, a las %@',
    'Contraction %lld, running, %@':
        'Contracción %lld, en curso, %@',
    'Delete %lld Flagged':
        'Eliminar %lld marcadas',
    'Delete %lld Flagged…':
        'Eliminar %lld marcadas…',
    'Delete flagged records?':
        '¿Eliminar los registros marcados?',
    'Guideline':
        'Pauta',
    'Last stretch, %@, %@':
        'Última racha, %@, %@',
    'Last stretch, %@, %@ over %@':
        'Última racha, %@, %@ en %@',
    'Last stretch, %@: %@':
        'Última racha, %@: %@',
    'Last stretch, %@: %@ over %@':
        'Última racha, %@: %@ en %@',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Todavía no en %@ — %@ de separación y %@ de duración en promedio en %lld contracciones cronometradas.%@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        'Todavía no en %@ — %@ de separación en promedio en %lld contracciones cronometradas; aún no hay suficientes terminadas para promediar su duración.',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Todavía no en %@. %@ de separación y %@ de duración en promedio en %lld contracciones cronometradas.%@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        'Todavía no en %@. %@ de separación en promedio en %lld contracciones cronometradas. Aún no hay suficientes terminadas para promediar su duración.',
    'Optional':
        'Opcional',
    "The guideline's three legs, over the last hour":
        'Las tres partes de la pauta, en la última hora',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Son los registros ya marcados con CHECK — un toque de fin que se pasó más de tres minutos, o un toque de menos de veinte segundos. Las contracciones cronometradas no se tocan, y Deshacer las devuelve todas.',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        'Estos promedios cubren toda la racha. Las cifras del cronómetro cubren la última hora, así que pueden diferir mientras las contracciones se van juntando.',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        'Treinta segundos — y espera bajo el signo de interrogación de arriba cuando lo quieras de vuelta.',
    'This deletes every contraction on this phone. There is no undo.':
        'Esto elimina todas las contracciones de este teléfono. No se puede deshacer.',
    'This stretch is ':
        'Esta racha está ',
    'This stretch is %@, %@ apart against %@ on %@.':
        'Esta racha está %@, %@ de separación frente a %@ el %@.',
    'This stretch: %@.':
        'Esta racha: %@.',
    'Timing this contraction — %lld in the last hour.':
        'Cronometrando esta contracción — %lld en la última hora.',
    'about the same as your last stretch':
        'más o menos igual que tu racha anterior',
    'closer together than your last stretch':
        'más junta que tu racha anterior',
    'farther apart than your last stretch':
        'más separada que tu racha anterior',
    'now':
        'ahora',
    'one hour ago':
        'hace una hora',
    'over %@':
        'en %@',
})


# ---- HL-046 · backfill ------------------------------------------------------
# HL-008 added these thirty-five keys straight into the catalogs and never wrote
# them back here, so this file stopped being the source it claims to be and the
# coverage check could not see the gap. Values are the Spanish already shipping.
TRANSLATIONS.update({
    '%lld TOTAL': '%lld EN TOTAL',
    '1 H AGO': 'HACE 1 H',
    'APART': 'Separación',
    'CONTRACTIONS': 'CONTRACCIONES',
    'Cancel': 'Cancelar',
    'Clear All History…': 'Borrar Todo el Historial…',
    'Clear Everything': 'Borrar Todo',
    'Clear the instrument': 'Borrar el instrumento',
    'DURATION': 'Duración',
    'Delete': 'Eliminar',
    'Done': 'Listo',
    'Got it': 'Entendido',
    'HOLDING': 'Sostenida',
    'History': 'Historial',
    'INTERVAL': 'Intervalo',
    'Keep a copy': 'Guardar una copia',
    'LAST %@ AGO': 'HACE %@',
    'LOCK SCREEN': 'PANTALLA DE BLOQUEO',
    'LONG': 'Duración',
    'Merge Up': 'Unir con la anterior',
    'NOW': 'AHORA',
    'PATTERN': 'Patrón',
    'Privacy policy': 'Política de privacidad',
    'RUNNING': 'EN CURSO',
    'Rate on the App Store': 'Valorar en el App Store',
    'SINCE %@': 'DESDE %@',
    'SINCE %@ %@': 'DESDE %@ %@',
    'SINCE YESTERDAY %@': 'DESDE AYER %@',
    'Save a copy first…': 'Guardar una copia primero…',
    'Support': 'Soporte',
    'Undo': 'Deshacer',
})

# ---- HL-046 · neverSays -----------------------------------------------------
# Spanish predates this convention: its list lived only in `VerifiedLanguages`,
# so `verify-language.py` had never been able to run against it while every other
# locale was checked. Same phrases, mirrored here so es is verified like the rest.
NEVER_SAYS = [
    "estás de parto",
    "estás en trabajo de parto",
    "ya viene el bebé",
    "no necesitas ir",
    "no hace falta ir",
    "tienes que",
    "debes ir",
    "ve al hospital",
    "vete al hospital",
]


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
        '%@ DE DURACIÓN',
    '%@ · FROM %@ · %lld':
        '%@ · DESDE %@ · %lld',
    '%lld H':
        '%lld H',
    '%lld H %lld M':
        '%lld H %lld M',
    '%lld M':
        '%lld M',
    'CHECK · OVER %lld MIN':
        'REVISAR · MÁS DE %lld MIN',
    'CHECK · UNDER %lld S':
        'REVISAR · MENOS DE %lld S',
    'OVER %@':
        'EN %@',
    'THIS STRETCH · AVG %@ APART':
        'ESTA RACHA · PROM %@ DE SEPARACIÓN',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Son los registros ya marcados con REVISAR — un toque de fin que se pasó más de tres minutos, o un toque de menos de veinte segundos. Las contracciones cronometradas no se tocan, y Deshacer las devuelve todas.',
})


# HL-065 · Control Center, the Action button and Siri.
TRANSLATIONS.update({
    'Contraction': 'Contracción',
})
