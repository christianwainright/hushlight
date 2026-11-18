#!/usr/bin/env python3
"""HL-008 · Italian (it).

Vocabulary: provider → la tua ostetrica o il tuo medico (Italian maternity care is
ostetrica-led, and "operatore sanitario" reads bureaucratic); labor and delivery →
la sala parto; guideline → la regola; stretch → la serie; apart → di distanza;
slip → un falso avvio; Start / End → Avvia / Termina.

Register: `tu`. No imperatives in the verdict — "Chiamare ora … è ragionevole",
never "Chiama". Em dashes and ` · ` verbatim; caps come from the type role.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "Timer",
    "Go": "Vai a",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "Nessuna app di posta su questo dispositivo. Scrivi a:",
    "This device cannot place calls. The number:": "Questo dispositivo non può chiamare. Il numero:",
    "Copy address": "Copia indirizzo",
    "Copy number": "Copia numero",
    "Copies the address": "Copia l’indirizzo",
    "Copies the number": "Copia il numero",
    "This stretch": "Questa fase",
    "Each one you time appears here as it happens, with the gap since the one before.": "Ogni contrazione che cronometri compare qui subito, con l’intervallo dalla precedente.",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "Questo iPad tiene il proprio registro. Niente di questo viene condiviso con il tuo iPhone né con nessuno.",
    "Start": "Avvia", "End": "Termina", "Call": "Chiama", "Copy": "Copia",
    "More": "Altro", "Share": "Condividi", "Copied": "Copiato", "Timing": "In corso",
    "Guidance": "Riferimenti", "Contractions": "Contrazioni", "For the call": "Per la chiamata",
    "How it works": "Come funziona", "One button": "Un solo pulsante",
    "Yours alone": "Solo tuo", "Report a problem": "Segnala un problema",
    "What this app is": "Cos’è questa app", "Your guideline": "La tua regola",
    "Start contraction": "Avvia contrazione",
    "End contraction": "Termina contrazione", "Tap when it begins": "Tocca quando inizia",
    "Tap when it ends": "Tocca quando finisce", "Clear all history?": "Cancellare tutta la cronologia?",
    "Call your provider": "Chiama la tua ostetrica o il tuo medico",
    "Heartbeat while timing": "Battito durante il conteggio",
    "Breath pacer while timing": "Guida al respiro durante il conteggio",
    "Interval is start-to-start": "L’intervallo va da inizio a inizio",
    "The timeline reads downward": "La cronologia si legge verso il basso",
    "Lock the phone freely": "Blocca pure il telefono",
    "Your provider or L&D number": "La tua ostetrica, il tuo medico o il numero della sala parto",
    "Your provider or labor and delivery number": "La tua ostetrica, il tuo medico o il numero della sala parto",
    "Call right away — pattern aside": "Chiama subito — a prescindere dal ritmo",
    "Nothing logged yet.": "Ancora niente registrato.",
    "No contractions yet.": "Ancora nessuna contrazione.",
    "It looks like time.": "Sembra il momento.",
    "History": "Cronologia", "Done": "Fine", "Cancel": "Annulla", "Delete": "Elimina",
    "Undo": "Annulla azione", "Merge Up": "Unisci alla precedente",
    "Got it": "Ho capito", "Keep a copy": "Conserva una copia",
    "Clear the instrument": "Azzera lo strumento",
    "Clear All History…": "Cancella tutta la cronologia…",
    "Save a copy first…": "Salva prima una copia…",
    "Clear Everything": "Cancella tutto",
    "Privacy policy": "Informativa sulla privacy", "Support": "Assistenza",
    "Rate on the App Store": "Valuta sull’App Store",
    "CONTRACTIONS": "CONTRAZIONI", "NOW": "ADESSO", "RUNNING": "IN CORSO",
    "LOCK SCREEN": "SCHERMATA DI BLOCCO", "1 H AGO": "1 H FA",
    "INTERVAL": "Intervallo", "DURATION": "Durata", "PATTERN": "Ritmo",
    "APART": "Distanza", "LONG": "Durata", "HOLDING": "Continuità",
    "SINCE %@": "DALLE %@", "SINCE YESTERDAY %@": "DA IERI %@",
    "SINCE %@ %@": "DA %@ %@", "LAST %@ AGO": "%@ FA",
    "%lld TOTAL": "%lld IN TOTALE",
    "CTX": "CTZ", "AVG %@ APART · %lld": "MEDIA %@ DI DISTANZA · %lld",
    "LAST %@ APART · %lld": "ULT %@ DI DISTANZA · %lld",
    "%lld logged": "%lld registrate",
    "Averaging %@ apart, %@": "In media %@ di distanza, %@",
    "Last gap %@, %@": "Ultimo intervallo %@, %@",
    "No contractions yet": "Ancora nessuna contrazione",
    "Opens guidance": "Apre i riferimenti",
    "Starts timing a contraction": "Avvia il conteggio di una contrazione",
    "Ends the contraction being timed": "Termina la contrazione in corso",
    "Opens the clear-history confirmation": "Apre la conferma di cancellazione della cronologia",
    "Copies this sentence": "Copia questa frase",
    "Shows the last stretch, to read or share": "Mostra l’ultima serie, da leggere o condividere",
    "Shows one sentence with the pattern, to read or share": "Mostra una frase con il ritmo, da leggere o condividere",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "Apre il menu di condivisione con questa frase e tutte le contrazioni di questa serie",
    "Drafts an email you can review before sending": "Prepara un’email che puoi rileggere prima di inviarla",
    "Removes the slip. Undo is in History.": "Rimuove il falso avvio. Annulla si trova nella Cronologia.",
    "%@.": "%@.", "%@, %@": "%@, %@", "in %@": "in %@", "on %@": "il %@", "out %@": "fuori %@",
    "Call %@": "Chiama %@", "%@ apart": "%@ di distanza", "since %@": "dalle %@",
    "lasted %@": "durata %@", "lasting %@": "di %@",
    "Started %@": "Iniziata %@", "Recorded %@": "Registrata %@", "Guideline %@": "Regola %@",
    "going for %@": "in corso da %@", "still running": "ancora in corso",
    "since %@ at %@": "da %@ alle %@", "under a minute": "meno di un minuto",
    "average %@ long": "%@ di durata in media", "average %@ apart": "%@ di distanza in media",
    "ranging %@ to %@": "da %@ a %@", "averaging %@ apart": "%@ di distanza in media",
    "Contractions, %@": "Contrazioni, %@", "Last stretch, %@": "Ultima serie, %@",
    "Last stretch: %@": "Ultima serie: %@",
    "Last stretch, %@ over %@": "Ultima serie, %@ su %@",
    "Last stretch: %@ over %@": "Ultima serie: %@ su %@",
    "since yesterday at %@": "da ieri alle %@",
    "closer than an hour ago": "più ravvicinate di un’ora fa",
    "farther apart than an hour ago": "più distanziate di un’ora fa",
    "not enough evidence yet": "ancora non abbastanza elementi",
    "not enough contractions yet": "ancora non abbastanza contrazioni",
    "%@ after the previous one": "%@ dopo la precedente",
    "contractions in the last hour": "contrazioni nell’ultima ora",
    "over three minutes — check this one": "oltre tre minuti — da controllare",
    "under twenty seconds — likely a slip, check this one":
        "meno di venti secondi — probabilmente un falso avvio, da controllare",
    "Last contraction ended %@ ago": "L’ultima contrazione è finita %@ fa",
    "Last contraction ended %@ ago.": "L’ultima contrazione è finita %@ fa.",
    "Contractions, last one ended %@ ago": "Contrazioni, l’ultima è finita %@ fa",
    "Contractions, %@, last one ended %@ ago": "Contrazioni, %@, l’ultima è finita %@ fa",
    "Not enough in the last hour to average.": "Non abbastanza nell’ultima ora per una media.",
    "Timing this contraction — nothing else in the last hour.": "Conteggio in corso — nient’altro nell’ultima ora.",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "Ultima contrazione %@ fa. Non abbastanza nell’ultima ora per una media.",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "Ultima contrazione %@ fa — non abbastanza nell’ultima ora per una media.",
    "Averaging %@ apart, %@ — was %@.": "%@ di distanza in media, %@ — era %@.",
    "Averaging every %@, lasting %@, for %@.": "Ogni %@ in media, di %@, da %@.",
    "Recorded %@ — likely a slip.": "Registrata %@ — probabilmente un falso avvio.",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "Registrata %@ — probabilmente un falso avvio. È già fuori dalle medie.",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "Oltre tre minuti. Di solito significa che è mancato il tocco di fine. Terminarla adesso la mette da parte rispetto alle medie.",
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "Non ancora a %@ — durata e ora ci sono; la distanza è di %@, e la regola chiede %@ o meno.%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "Non ancora a %@. La distanza va da %@ a %@; la regola chiede %@ o meno. Durata e ora ci sono.%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "Non ancora a %@. Questa serie dura senza interruzioni da %@; la regola chiede un’ora. Distanza e durata ci sono.%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "Non ancora a %@ — distanza e durata ci sono; questa serie dura senza interruzioni da %@, e la regola chiede un’ora.%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "Non ancora a %@. Le contrazioni durano in media %@; la regola chiede circa un minuto. Distanza e ora ci sono.%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "Non ancora a %@ — distanza e ora ci sono; le contrazioni durano in media %@, e la regola chiede circa un minuto.%@",
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Questo soddisfa la regola %@ usata da molti professionisti. Chiamare ora la tua ostetrica o il tuo medico è ragionevole — le loro indicazioni vengono prima.",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Questo soddisfaceva la regola %@ usata da molti professionisti. Chiamare ora la tua ostetrica o il tuo medico è ragionevole — le loro indicazioni vengono prima.",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "Questo soddisfaceva la regola %@ usata da molti professionisti — ora ne è in corso una. Chiamare ora la tua ostetrica o il tuo medico è ragionevole — le loro indicazioni vengono prima.",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "Questo soddisfaceva la regola %@ usata da molti professionisti — ultima contrazione %@ fa. Chiamare ora la tua ostetrica o il tuo medico è ragionevole — le loro indicazioni vengono prima.",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "Sono più ravvicinate di quanto chieda la regola %@, prima dell’ora che chiede anch’essa. Chiamare ora la tua ostetrica o il tuo medico è ragionevole — le loro indicazioni vengono prima.",
    "Your water breaks — note the time and the color of the fluid.":
        "Rompi le acque — annota l’ora e il colore del liquido.",
    "Bleeding, more than spotting.": "Sanguinamento, più di poche tracce.",
    "The baby is moving less than usual.": "Il bambino si muove meno del solito.",
    "Regular contractions before 37 weeks.": "Contrazioni regolari prima delle 37 settimane.",
    "Anything that feels wrong to you.": "Qualsiasi cosa ti sembri sbagliata.",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "Niente di tutto questo aspetta un cronometro. Chiama direttamente la tua ostetrica, il tuo medico o la sala parto.",
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "I professionisti danno indicazioni diverse — un secondo figlio, la distanza dall’ospedale e la tua storia spostano tutto questo. Se ti è stata data una regola, impostala qui e segui la loro.",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "Resta su questo telefono. Una volta impostato, un pulsante Chiama compare accanto al responso sul cronometro e sotto l’elenco qui sotto — così la chiamata che questa app continua a suggerire è un tocco, non una ricerca tra i Contatti alle 3 di notte.",
    "A soft pulse every 15 seconds while a contraction is timed":
        "Un impulso leggero ogni 15 secondi mentre una contrazione viene cronometrata",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "Così il telefono può stare a faccia in giù o in tasca restando affidabile. Disattivo se non lo vuoi; silenzioso in Risparmio energetico.",
    "Counted breaths under the timer — in for 4, out for 6":
        "Respiri contati sotto il cronometro — 4 dentro, 6 fuori",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "Una cadenza lenta con cui respirare mentre una contrazione viene cronometrata. Il bagliore mantiene lo stesso ritmo.",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "Ogni 5 minuti, di circa un minuto, per un’ora — la regola più diffusa. I professionisti differiscono; la targhetta sul cronometro imposta la tua. Quando il tuo ritmo la soddisfa davvero, l’app lo dice e suggerisce la chiamata.",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "Nessun account, nessuna pubblicità, nessuna rete. Tutto resta su questo telefono, e Cancella tutta la cronologia lo rimuove quando vuoi tu.",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "Prepara un’email che puoi leggere e modificare prima di inviarla. Gli orari delle tue contrazioni non sono mai inclusi.",
    "Free forever. No account. Works in airplane mode.": "Gratis per sempre. Nessun account. Funziona in modalità aereo.",
    "Free forever · no account · works in airplane mode": "Gratis per sempre · nessun account · funziona in modalità aereo",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "Tocca la barra quando una contrazione inizia, toccala di nuovo quando finisce. È tutto qui. I tocchi sbagliati si correggono nella Cronologia — scorri per eliminare, e Annulla riprende l’ultimo tocco.",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "Tocca il pulsante quando ne inizia una — tutto quello sopra si costruisce da quel solo tocco. La targhetta in alto tiene la regola che ti è stata data.",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "Il conteggio parte dal tocco, e il tocco arriva qualche secondo dopo la contrazione — così le durate registrate restano un po’ indietro rispetto al minuto sentito. Il controllo della durata ne tiene conto; le cifre sul cronometro restano esattamente ciò che è stato registrato.",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "La più recente in alto, l’intervallo tra ogni coppia stampato proprio dove è avvenuto. Le cifre restano trattini finché non c’è abbastanza da significare qualcosa — un trattino è onesto, una supposizione no.",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "Il conteggio segue l’orologio, non lo schermo. Quando un ritmo è avviato, il pulsante sta anche sulla schermata di blocco — avvia e termina senza sbloccare.",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "Ogni contrazione che cronometri compare qui con la sua durata e l’intervallo dalla precedente.",
    "History has every contraction. The next tap starts a new stretch.":
        "La Cronologia contiene ogni contrazione. Il tocco successivo avvia una nuova serie.",
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "Un cronometro con dell’aritmetica. Misura le contrazioni e riporta il ritmo rispetto alla regola che hai scelto. Non diagnostica il travaglio e non è un parere medico — le indicazioni della tua ostetrica o del tuo medico vengono sempre prima. Nel dubbio, chiama.",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "Tutto resta su questo telefono. Nessun account, nessuna analisi, niente viene inviato da nessuna parte.",
    "every %@ on average": "ogni %@ in media",
    "every %@ on average (ranging %@–%@)": "ogni %@ in media (da %@ a %@)",
    "lasting about %@": "di circa %@",
    "Hushlight problem report": "Segnalazione di problema Hushlight",
    "Describe what happened above this line.": "Descrivi cosa è successo sopra questa riga.",
    "— About this app and phone (you can delete any line) —":
        "— Su questa app e questo telefono (puoi eliminare qualsiasi riga) —",
    "App: Hushlight %@": "App: Hushlight %@", "System: %@ · %@": "Sistema: %@ · %@",
    "Guideline: %@": "Regola: %@", "Recorded: %@ across %@": "Registrato: %@ in %@",
    "Live Activity on screen: %@": "Attività in tempo reale sullo schermo: %@",
    "yes": "sì", "no": "no",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "Gli orari delle tue contrazioni non sono in questa email. Se servissero per una correzione te li chiederemo, e inviarli resterà una tua decisione.",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "Una distanza che varia prima di stabilizzarsi è spesso l’aspetto delle prime serie. Una serie cronometrata ogni tanto mostra lo stesso ritmo — non serve un controllo continuo.",
}

PLURALS = {
    "%lld contraction": {"one": "%lld contrazione", "other": "%lld contrazioni"},
    "%lld episode": {"one": "%lld episodio", "other": "%lld episodi"},
    "%lld contraction in this stretch": {"one": "%lld contrazione in questa serie", "other": "%lld contrazioni in questa serie"},
    "%lld minutes": {"one": "%lld minuto", "other": "%lld minuti"},
    "%lld seconds": {"one": "%lld secondo", "other": "%lld secondi"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "one": "Ancora in corso — oltre %lld minuto di solito significa che è mancato il tocco di fine. Terminarla adesso la mette da parte rispetto alle medie.",
        "other": "Ancora in corso — oltre %lld minuti di solito significa che è mancato il tocco di fine. Terminarla adesso la mette da parte rispetto alle medie.",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {"hoursArg": {"one": "%1$lld ora", "other": "%1$lld ore"},
                 "minutesArg": {"one": "%2$lld minuto", "other": "%2$lld minuti"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {"minutesArg": {"one": "%1$lld minuto", "other": "%1$lld minuti"},
                 "secondsArg": {"one": "%2$lld secondo", "other": "%2$lld secondi"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@: contrazioni ogni %2$#@minutesArg@ o meno, ciascuna di circa un minuto, per un’ora senza lunghe pause. Il cronometro legge tutti e tre i dati dai tuoi tocchi e lo dice quando il ritmo c’è.",
        "args": {"minutesArg": {"one": "%2$lld minuto", "other": "%2$lld minuti"}},
    },
}

NEVER_SAYS = [
    "sei in travaglio",
    "il travaglio è iniziato",
    "il bambino sta arrivando",
    "non hai bisogno di andare",
    "non serve andare",
    "devi andare",
    "vai in ospedale",
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
        ' (era %@).',
    ' — %@ apart against %@ on %@.':
        ' — %@ di distanza contro %@ il %@.',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '«Ogni 5 minuti» misura lo spazio tra gli inizi delle contrazioni — come lo misurano i professionisti. Durata è quanto dura ciascuna; Ritmo è da quanto va avanti questa serie. Il conteggio parte dal tocco, quindi le durate registrate restano un po’ indietro rispetto alla contrazione sentita.',
    '%@ before the next one':
        '%@ prima della successiva',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@, %@.',
    '%@, met':
        '%@, soddisfatto',
    '%@, not yet':
        '%@, non ancora',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        'Una contrazione è ancora in corso. Questo la elimina insieme a tutte le altre contrazioni su questo telefono. Non si può annullare.',
    'Averaging %@ apart — ':
        '%@ di distanza in media — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        'Ogni %@ in media su %lld contrazioni cronometrate, da %@.',
    'Contraction %lld, lasted %@, at %@':
        'Contrazione %lld, durata %@, alle %@',
    'Contraction %lld, running, %@':
        'Contrazione %lld, in corso, %@',
    'Contractions %@ — %lld so far.':
        'Contrazioni %@ — %lld finora.',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        'Rapporti di arresto conservati su questo telefono: %lld · Blocchi: %lld',
    'Delete %lld Flagged':
        'Elimina %lld segnalate',
    'Delete %lld Flagged…':
        'Elimina %lld segnalate…',
    'Delete flagged records?':
        'Eliminare i record segnalati?',
    'Guideline':
        'Regola',
    'Last stretch, %@, %@':
        'Ultima serie, %@, %@',
    'Last stretch, %@, %@ over %@':
        'Ultima serie, %@, %@ su %@',
    'Last stretch, %@: %@':
        'Ultima serie, %@: %@',
    'Last stretch, %@: %@ over %@':
        'Ultima serie, %@: %@ su %@',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Non ancora a %@ — %@ di distanza e %@ di durata in media su %lld contrazioni cronometrate.%@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        'Non ancora a %@ — %@ di distanza in media su %lld contrazioni cronometrate; non ancora abbastanza terminate per fare la media della durata.',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Non ancora a %@. %@ di distanza e %@ di durata in media su %lld contrazioni cronometrate.%@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        'Non ancora a %@. %@ di distanza in media su %lld contrazioni cronometrate. Non ancora abbastanza terminate per fare la media della durata.',
    'Optional':
        'Facoltativo',
    'Start or stop a contraction':
        'Avvia o ferma una contrazione',
    "The guideline's three legs, over the last hour":
        'Le tre parti della regola, nell’ultima ora',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Sono i record già contrassegnati con CHECK — un tocco di fine mancato di oltre tre minuti, o un tocco sotto i venti secondi. Le contrazioni cronometrate non vengono toccate, e Annulla azione le riporta tutte indietro.',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        'Queste medie riguardano tutta la serie. I numeri del timer riguardano l’ultima ora, quindi possono differire mentre le contrazioni si avvicinano.',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        'Trenta secondi — e resta sotto il punto interrogativo in alto ogni volta che lo rivuoi.',
    'This deletes every contraction on this phone. There is no undo.':
        'Questo elimina tutte le contrazioni su questo telefono. Non si può annullare.',
    'This stretch is ':
        'Questa serie è ',
    'This stretch is %@, %@ apart against %@ on %@.':
        'Questa serie è %@, %@ di distanza contro %@ il %@.',
    'This stretch: %@.':
        'Questa serie: %@.',
    'Timing this contraction — %lld in the last hour.':
        'Conteggio in corso — %lld nell’ultima ora.',
    'about the same as your last stretch':
        'più o meno come la tua serie precedente',
    'closer together than your last stretch':
        'più ravvicinata della tua serie precedente',
    'farther apart than your last stretch':
        'più distanziata della tua serie precedente',
    'now':
        'adesso',
    'one hour ago':
        'un’ora fa',
    'over %@':
        'su %@',
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
        '%@ DI DURATA',
    '%@ · FROM %@ · %lld':
        '%@ · DALLE %@ · %lld',
    '%lld H':
        '%lld H',
    '%lld H %lld M':
        '%lld H %lld M',
    '%lld M':
        '%lld M',
    'CHECK · OVER %lld MIN':
        'DA CONTROLLARE · OLTRE %lld MIN',
    'CHECK · UNDER %lld S':
        'DA CONTROLLARE · SOTTO %lld S',
    'OVER %@':
        'SU %@',
    'THIS STRETCH · AVG %@ APART':
        'QUESTA SERIE · MEDIA %@ DI DISTANZA',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Sono i record già contrassegnati con DA CONTROLLARE — un tocco di fine mancato di oltre tre minuti, o un tocco sotto i venti secondi. Le contrazioni cronometrate non vengono toccate, e Annulla azione le riporta tutte indietro.',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": 'Contrazione',
    "Start or stop a contraction": 'Avvia o termina una contrazione',
    "One tap starts the timing; the next ends it.": 'Un tocco avvia il conteggio; il successivo lo termina.',
    "Open Hushlight to time this one.": 'Apri Hushlight per misurare questa.',
})
