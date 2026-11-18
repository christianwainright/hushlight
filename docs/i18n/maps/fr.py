#!/usr/bin/env python3
"""HL-008 · French (fr) — one map for all three catalogs.

Vocabulary, fixed once:
  provider           → votre professionnel de santé  (the standard neutral French
                       term; "sage-femme" alone would exclude obstetricians)
  labor and delivery → la maternité                  (the French ward, not a calque)
  guideline          → la règle
  stretch            → la série
  apart              → d'intervalle
  slip               → un faux départ
  Start / End        → Démarrer / Terminer

Register: no imperatives in the verdict — "Appeler votre professionnel de santé
maintenant est raisonnable", never "Appelez". "It looks like time." stays flat:
"Le moment semble venu." Em dashes and ` · ` survive verbatim. Caps come from the
type role, so instrument words are given as words.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "Chronomètre",
    "Go": "Aller à",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "Aucune app de courrier sur cet appareil. Écrivez à :",
    "This device cannot place calls. The number:": "Cet appareil ne peut pas appeler. Le numéro :",
    "Copy address": "Copier l’adresse",
    "Copy number": "Copier le numéro",
    "Copies the address": "Copie l’adresse",
    "Copies the number": "Copie le numéro",
    "This stretch": "Cette série",
    "Each one you time appears here as it happens, with the gap since the one before.": "Chaque contraction chronométrée apparaît ici aussitôt, avec l’écart depuis la précédente.",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "Cet iPad tient son propre relevé. Rien ici n’est partagé avec votre iPhone ni avec qui que ce soit.",
    # buttons, chrome, short labels
    "Start": "Démarrer", "End": "Terminer", "Call": "Appeler", "Copy": "Copier",
    "More": "Plus", "Share": "Partager", "Copied": "Copié", "Timing": "Chronométrage",
    "Guidance": "Repères", "Contractions": "Contractions", "For the call": "Pour l’appel",
    "How it works": "Comment ça marche", "One button": "Un seul bouton",
    "Yours alone": "À vous seule", "Report a problem": "Signaler un problème",
    "What this app is": "Ce qu’est cette app", "Your guideline": "Votre règle",
    "Start contraction": "Démarrer la contraction",
    "End contraction": "Terminer la contraction", "Tap when it begins": "Touchez quand elle commence",
    "Tap when it ends": "Touchez quand elle se termine", "Clear all history?": "Effacer tout l’historique ?",
    "Call your provider": "Appelez votre professionnel de santé",
    "Heartbeat while timing": "Battement pendant le chronométrage",
    "Breath pacer while timing": "Guide de respiration pendant le chronométrage",
    "Interval is start-to-start": "L’intervalle va d’un début à l’autre",
    "The timeline reads downward": "La chronologie se lit vers le bas",
    "Lock the phone freely": "Verrouillez le téléphone sans souci",
    "Your provider or L&D number": "Votre professionnel de santé ou le numéro de la maternité",
    "Your provider or labor and delivery number": "Votre professionnel de santé ou le numéro de la maternité",
    "Call right away — pattern aside": "Appelez tout de suite — indépendamment du rythme",
    "Nothing logged yet.": "Rien d’enregistré pour l’instant.",
    "No contractions yet.": "Pas encore de contractions.",
    "It looks like time.": "Le moment semble venu.",
    "History": "Historique", "Done": "OK", "Cancel": "Annuler", "Delete": "Supprimer",
    "Undo": "Annuler l’action", "Merge Up": "Fusionner avec la précédente",
    "Got it": "J’ai compris", "Keep a copy": "Garder une copie",
    "Clear the instrument": "Effacer l’instrument",
    "Clear All History…": "Effacer tout l’historique…",
    "Save a copy first…": "Enregistrer une copie d’abord…",
    "Clear Everything": "Tout effacer",
    "Privacy policy": "Politique de confidentialité", "Support": "Assistance",
    "Rate on the App Store": "Noter sur l’App Store",
    # instrument vocabulary (decision 0062 — the caps come from the type role)
    "CONTRACTIONS": "CONTRACTIONS", "NOW": "MAINTENANT", "RUNNING": "EN COURS",
    "LOCK SCREEN": "ÉCRAN VERROUILLÉ", "1 H AGO": "IL Y A 1 H",
    "INTERVAL": "Intervalle", "DURATION": "Durée", "PATTERN": "Rythme",
    "APART": "Intervalle", "LONG": "Durée", "HOLDING": "Tenue",
    "SINCE %@": "DEPUIS %@", "SINCE YESTERDAY %@": "DEPUIS HIER %@",
    "SINCE %@ %@": "DEPUIS %@ %@", "LAST %@ AGO": "IL Y A %@",
    "%lld TOTAL": "%lld AU TOTAL",
    "CTX": "CTX", "AVG %@ APART · %lld": "MOY %@ D’INTERVALLE · %lld",
    "LAST %@ APART · %lld": "DERN %@ D’INTERVALLE · %lld",
    "%lld logged": "%lld enregistrées",
    "Averaging %@ apart, %@": "%@ d’intervalle en moyenne, %@",
    "Last gap %@, %@": "Dernier intervalle %@, %@",
    "No contractions yet": "Pas encore de contractions",
    # VoiceOver
    "Opens guidance": "Ouvre les repères",
    "Starts timing a contraction": "Démarre le chronométrage d’une contraction",
    "Ends the contraction being timed": "Termine la contraction en cours",
    "Opens the clear-history confirmation": "Ouvre la confirmation d’effacement de l’historique",
    "Copies this sentence": "Copie cette phrase",
    "Shows the last stretch, to read or share": "Affiche la dernière série, à lire ou à partager",
    "Shows one sentence with the pattern, to read or share": "Affiche une phrase avec le rythme, à lire ou à partager",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "Ouvre le menu de partage avec cette phrase et toutes les contractions de cette série",
    "Drafts an email you can review before sending": "Rédige un e-mail que vous pouvez relire avant l’envoi",
    "Removes the slip. Undo is in History.": "Retire le faux départ. Annuler se trouve dans l’Historique.",
    # readout / timeline fragments
    "%@.": "%@.", "%@, %@": "%@, %@", "in %@": "en %@", "on %@": "le %@", "out %@": "sur %@",
    "Call %@": "Appeler %@", "%@ apart": "%@ d’intervalle", "since %@": "depuis %@",
    "lasted %@": "a duré %@", "lasting %@": "de %@",
    "Started %@": "Commencée %@", "Recorded %@": "Enregistrée %@", "Guideline %@": "Règle %@",
    "going for %@": "en cours depuis %@", "still running": "toujours en cours",
    "since %@ at %@": "depuis %@ à %@", "under a minute": "moins d’une minute",
    "average %@ long": "%@ de durée en moyenne", "average %@ apart": "%@ d’intervalle en moyenne",
    "ranging %@ to %@": "de %@ à %@", "averaging %@ apart": "%@ d’intervalle en moyenne",
    "Contractions, %@": "Contractions, %@", "Last stretch, %@": "Dernière série, %@",
    "Last stretch: %@": "Dernière série : %@",
    "Last stretch, %@ over %@": "Dernière série, %@ sur %@",
    "Last stretch: %@ over %@": "Dernière série : %@ sur %@",
    "since yesterday at %@": "depuis hier à %@",
    "closer than an hour ago": "plus rapprochées qu’il y a une heure",
    "farther apart than an hour ago": "plus espacées qu’il y a une heure",
    "not enough evidence yet": "pas encore assez d’éléments",
    "not enough contractions yet": "pas encore assez de contractions",
    "%@ after the previous one": "%@ après la précédente",
    "contractions in the last hour": "contractions dans la dernière heure",
    "over three minutes — check this one": "plus de trois minutes — à vérifier",
    "under twenty seconds — likely a slip, check this one":
        "moins de vingt secondes — sans doute un faux départ, à vérifier",
    "Last contraction ended %@ ago": "La dernière contraction s’est terminée il y a %@",
    "Last contraction ended %@ ago.": "La dernière contraction s’est terminée il y a %@.",
    "Contractions, last one ended %@ ago": "Contractions, la dernière s’est terminée il y a %@",
    "Contractions, %@, last one ended %@ ago": "Contractions, %@, la dernière s’est terminée il y a %@",
    "Not enough in the last hour to average.": "Pas assez dans la dernière heure pour faire une moyenne.",
    "Timing this contraction — nothing else in the last hour.": "Chronométrage en cours — rien d’autre dans la dernière heure.",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "Dernière contraction il y a %@. Pas assez dans la dernière heure pour faire une moyenne.",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "Dernière contraction il y a %@ — pas assez dans la dernière heure pour faire une moyenne.",
    "Averaging %@ apart, %@ — was %@.": "%@ d’intervalle en moyenne, %@ — était %@.",
    "Averaging every %@, lasting %@, for %@.": "Toutes les %@ en moyenne, de %@, depuis %@.",
    # slip strip
    "Recorded %@ — likely a slip.": "Enregistrée %@ — sans doute un faux départ.",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "Enregistrée %@ — sans doute un faux départ. Elle est déjà hors des moyennes.",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "Plus de trois minutes. Cela signifie souvent qu’un appui de fin a été oublié. La terminer maintenant la met à part des moyennes.",
    # partial line
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "Pas encore à %@ — la durée et l’heure y sont ; l’intervalle est de %@, et la règle demande %@ ou moins.%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "Pas encore à %@. L’intervalle va de %@ à %@ ; la règle demande %@ ou moins. La durée et l’heure y sont.%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "Pas encore à %@. Cette série dure sans interruption depuis %@ ; la règle demande une heure. L’intervalle et la durée y sont.%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "Pas encore à %@ — l’intervalle et la durée y sont ; cette série dure sans interruption depuis %@, et la règle demande une heure.%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "Pas encore à %@. Les contractions durent %@ en moyenne ; la règle demande environ une minute. L’intervalle et l’heure y sont.%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "Pas encore à %@ — l’intervalle et l’heure y sont ; les contractions durent %@ en moyenne, et la règle demande environ une minute.%@",
    # verdict (LOAD-BEARING)
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Cela correspond à la règle %@ qu’utilisent beaucoup de professionnels. Appeler votre professionnel de santé maintenant est raisonnable — ses consignes passent avant.",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Cela correspondait à la règle %@ qu’utilisent beaucoup de professionnels. Appeler votre professionnel de santé maintenant est raisonnable — ses consignes passent avant.",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "Cela correspondait à la règle %@ qu’utilisent beaucoup de professionnels — une contraction est en cours. Appeler votre professionnel de santé maintenant est raisonnable — ses consignes passent avant.",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "Cela correspondait à la règle %@ qu’utilisent beaucoup de professionnels — dernière contraction il y a %@. Appeler votre professionnel de santé maintenant est raisonnable — ses consignes passent avant.",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "C’est plus rapproché que ce que demande la règle %@, avant l’heure qu’elle demande aussi. Appeler votre professionnel de santé maintenant est raisonnable — ses consignes passent avant.",
    # call-right-away card (LOAD-BEARING)
    "Your water breaks — note the time and the color of the fluid.":
        "Vous perdez les eaux — notez l’heure et la couleur du liquide.",
    "Bleeding, more than spotting.": "Un saignement, plus que quelques traces.",
    "The baby is moving less than usual.": "Le bébé bouge moins que d’habitude.",
    "Regular contractions before 37 weeks.": "Des contractions régulières avant 37 semaines.",
    "Anything that feels wrong to you.": "Tout ce qui vous semble anormal.",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "Rien de tout cela n’attend un chronomètre. Appelez directement votre professionnel de santé ou la maternité.",
    # Guidance prose
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "Chaque professionnel donne des consignes différentes — un deuxième bébé, la distance jusqu’à la maternité et vos antécédents changent tout cela. Si le vôtre vous a donné une règle, indiquez-la ici et suivez la sienne.",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "Reste sur ce téléphone. Une fois enregistré, un bouton Appeler apparaît à côté du constat sur le chronomètre et sous la liste ci-dessous — pour que l’appel que cette app suggère soit un seul geste, pas une recherche dans les Contacts à 3 h du matin.",
    "A soft pulse every 15 seconds while a contraction is timed":
        "Une pulsation légère toutes les 15 secondes pendant le chronométrage d’une contraction",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "Pour que le téléphone puisse rester face vers le bas ou dans une poche sans cesser d’être fiable. Désactivé sauf si vous le voulez ; silencieux en mode économie d’énergie.",
    "Counted breaths under the timer — in for 4, out for 6":
        "Des respirations comptées sous le chronomètre — 4 à l’inspiration, 6 à l’expiration",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "Une cadence lente pour respirer pendant le chronométrage d’une contraction. La lueur garde le même rythme.",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "Toutes les 5 minutes, d’environ une minute, pendant une heure — la règle la plus répandue. Les professionnels diffèrent ; la pastille du chronomètre fixe la vôtre. Quand votre rythme y correspond vraiment, l’app le dit et suggère l’appel.",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "Pas de compte, pas de publicité, pas de réseau. Tout reste sur ce téléphone, et Effacer tout l’historique le supprime quand vous le décidez.",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "Rédige un e-mail que vous pouvez lire et modifier avant l’envoi. Les horaires de vos contractions n’y figurent jamais.",
    # How It Works
    "Free forever. No account. Works in airplane mode.": "Gratuit pour toujours. Sans compte. Fonctionne en mode avion.",
    "Free forever · no account · works in airplane mode": "Gratuit pour toujours · sans compte · fonctionne en mode avion",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "Touchez la barre quand une contraction commence, touchez-la de nouveau quand elle se termine. C’est tout. Les appuis ratés se corrigent dans l’Historique — balayez pour supprimer, et Annuler reprend le dernier geste.",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "Touchez le bouton quand une contraction commence — tout ce qui précède se construit à partir de ce seul geste. La pastille en haut garde la règle que votre professionnel vous a donnée.",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "Le chronomètre démarre au geste, et le geste arrive quelques secondes après la contraction — les durées enregistrées sont donc un peu en retard sur la minute ressentie. La vérification de durée en tient compte ; les chiffres du chronomètre restent exactement ce qui a été enregistré.",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "La plus récente en haut, l’écart entre chaque paire affiché là où il s’est produit. Les chiffres restent des tirets tant qu’il n’y a pas de quoi dire quelque chose — un tiret est honnête, une supposition ne l’est pas.",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "Le chronomètre suit l’horloge, pas l’écran. Dès qu’un rythme est en cours, le bouton est aussi sur l’écran verrouillé — démarrez et terminez sans déverrouiller.",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "Chaque contraction que vous chronométrez apparaît ici avec sa durée et l’intervalle depuis la précédente.",
    "History has every contraction. The next tap starts a new stretch.":
        "L’Historique contient toutes les contractions. Le prochain geste démarre une nouvelle série.",
    # LaborKit — disclaimer + privacy (LOAD-BEARING)
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "Un chronomètre avec de l’arithmétique. Il mesure les contractions et rapporte le rythme au regard de la règle que vous avez choisie. Il ne diagnostique pas le travail et ne constitue pas un avis médical — les consignes de votre professionnel de santé passent toujours avant. En cas de doute, appelez.",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "Tout reste sur ce téléphone. Pas de compte, pas de statistiques, rien n’est envoyé nulle part.",
    # LaborKit — call summary + report email
    "every %@ on average": "toutes les %@ en moyenne",
    "every %@ on average (ranging %@–%@)": "toutes les %@ en moyenne (de %@ à %@)",
    "lasting about %@": "d’environ %@",
    "Hushlight problem report": "Signalement de problème Hushlight",
    "Describe what happened above this line.": "Décrivez ce qui s’est passé au-dessus de cette ligne.",
    "— About this app and phone (you can delete any line) —":
        "— À propos de cette app et de ce téléphone (vous pouvez supprimer n’importe quelle ligne) —",
    "App: Hushlight %@": "App : Hushlight %@", "System: %@ · %@": "Système : %@ · %@",
    "Guideline: %@": "Règle : %@", "Recorded: %@ across %@": "Enregistré : %@ sur %@",
    "Live Activity on screen: %@": "Activité en direct à l’écran : %@",
    "yes": "oui", "no": "non",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "Les horaires de vos contractions ne figurent pas dans cet e-mail. Si une correction en a besoin, nous vous le demanderons, et les envoyer restera votre décision.",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "Un intervalle qui varie avant de se stabiliser, c’est souvent l’allure des premières séries. Une série chronométrée de temps en temps montre le même rythme — cela ne demande pas une surveillance continue.",
}

PLURALS = {
    "%lld contraction": {"one": "%lld contraction", "other": "%lld contractions"},
    "%lld episode": {"one": "%lld épisode", "other": "%lld épisodes"},
    "%lld contraction in this stretch": {"one": "%lld contraction dans cette série", "other": "%lld contractions dans cette série"},
    "%lld minutes": {"one": "%lld minute", "other": "%lld minutes"},
    "%lld seconds": {"one": "%lld seconde", "other": "%lld secondes"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "one": "Toujours en cours — plus de %lld minute signifie souvent un appui de fin oublié. La terminer maintenant la met à part des moyennes.",
        "other": "Toujours en cours — plus de %lld minutes signifie souvent un appui de fin oublié. La terminer maintenant la met à part des moyennes.",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {"hoursArg": {"one": "%1$lld heure", "other": "%1$lld heures"},
                 "minutesArg": {"one": "%2$lld minute", "other": "%2$lld minutes"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {"minutesArg": {"one": "%1$lld minute", "other": "%1$lld minutes"},
                 "secondsArg": {"one": "%2$lld seconde", "other": "%2$lld secondes"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@ : des contractions toutes les %2$#@minutesArg@ ou moins, d’environ une minute chacune, pendant une heure sans longue interruption. Le chronomètre lit les trois à partir de vos gestes et le dit quand le rythme y est.",
        "args": {"minutesArg": {"one": "%2$lld minute", "other": "%2$lld minutes"}},
    },
}

NEVER_SAYS = [
    "vous êtes en travail",
    "le travail a commencé",
    "le bébé arrive",
    "vous n’avez pas besoin d’aller",
    "inutile d’aller",
    "vous devez",
    "allez à la maternité",
    "allez à l’hôpital",
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
        ' (était %@).',
    ' — %@ apart against %@ on %@.':
        ' — %@ d’intervalle contre %@ le %@.',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '« Toutes les 5 minutes » mesure l’écart entre les débuts des contractions — comme le mesurent les professionnels. Durée, c’est la longueur de chacune ; Rythme, c’est depuis combien de temps dure cette série. Le chronométrage commence à l’appui, donc les durées enregistrées sont un peu en retard sur la contraction ressentie.',
    '%@ before the next one':
        '%@ avant la suivante',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@, %@.',
    '%@, met':
        '%@, atteint',
    '%@, not yet':
        '%@, pas encore',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        'Une contraction est en cours de chronométrage. Cela la supprime avec toutes les autres contractions de ce téléphone. Il n’y a pas de retour en arrière.',
    'Averaging %@ apart — ':
        '%@ d’intervalle en moyenne — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        'Toutes les %@ en moyenne sur %lld contractions chronométrées, depuis %@.',
    'Contraction %lld, lasted %@, at %@':
        'Contraction %lld, a duré %@, à %@',
    'Contraction %lld, running, %@':
        'Contraction %lld, en cours, %@',
    'Contractions %@ — %lld so far.':
        'Contractions %@ — %lld jusqu’ici.',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        'Rapports de plantage conservés sur ce téléphone : %lld · Blocages : %lld',
    'Delete %lld Flagged':
        'Supprimer %lld signalées',
    'Delete %lld Flagged…':
        'Supprimer %lld signalées…',
    'Delete flagged records?':
        'Supprimer les enregistrements signalés ?',
    'Guideline':
        'Règle',
    'Last stretch, %@, %@':
        'Dernière série, %@, %@',
    'Last stretch, %@, %@ over %@':
        'Dernière série, %@, %@ sur %@',
    'Last stretch, %@: %@':
        'Dernière série, %@ : %@',
    'Last stretch, %@: %@ over %@':
        'Dernière série, %@ : %@ sur %@',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Pas encore à %@ — %@ d’intervalle et %@ de durée en moyenne sur %lld contractions chronométrées.%@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        'Pas encore à %@ — %@ d’intervalle en moyenne sur %lld contractions chronométrées ; pas encore assez de contractions terminées pour moyenner leur durée.',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Pas encore à %@. %@ d’intervalle et %@ de durée en moyenne sur %lld contractions chronométrées.%@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        'Pas encore à %@. %@ d’intervalle en moyenne sur %lld contractions chronométrées. Pas encore assez de contractions terminées pour moyenner leur durée.',
    'Optional':
        'Facultatif',
    'Start or stop a contraction':
        'Démarre ou arrête une contraction',
    "The guideline's three legs, over the last hour":
        'Les trois volets de la règle, sur la dernière heure',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Ce sont les enregistrements déjà marqués CHECK — un appui de fin manqué de plus de trois minutes, ou un appui de moins de vingt secondes. Les contractions chronométrées ne sont pas touchées, et Annuler l’action les restaure toutes.',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        'Ces moyennes portent sur toute la série. Les chiffres du chronomètre portent sur la dernière heure, ils peuvent donc différer pendant que les contractions se rapprochent.',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        'Trente secondes — et cela vous attend sous le point d’interrogation en haut dès que vous le voulez.',
    'This deletes every contraction on this phone. There is no undo.':
        'Cela supprime toutes les contractions de ce téléphone. Il n’y a pas de retour en arrière.',
    'This stretch is ':
        'Cette série est ',
    'This stretch is %@, %@ apart against %@ on %@.':
        'Cette série est %@, %@ d’intervalle contre %@ le %@.',
    'This stretch: %@.':
        'Cette série : %@.',
    'Timing this contraction — %lld in the last hour.':
        'Chronométrage en cours — %lld dans la dernière heure.',
    'about the same as your last stretch':
        'à peu près comme votre série précédente',
    'closer together than your last stretch':
        'plus rapprochée que votre série précédente',
    'farther apart than your last stretch':
        'plus espacée que votre série précédente',
    'now':
        'maintenant',
    'one hour ago':
        'il y a une heure',
    'over %@':
        'sur %@',
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
        '%@ DE DURÉE',
    '%@ · FROM %@ · %lld':
        '%@ · DEPUIS %@ · %lld',
    '%lld H':
        '%lld H',
    '%lld H %lld M':
        '%lld H %lld M',
    '%lld M':
        '%lld M',
    'CHECK · OVER %lld MIN':
        'À VÉRIFIER · PLUS DE %lld MIN',
    'CHECK · UNDER %lld S':
        'À VÉRIFIER · MOINS DE %lld S',
    'OVER %@':
        'SUR %@',
    'THIS STRETCH · AVG %@ APART':
        'CETTE SÉRIE · MOY %@ D’INTERVALLE',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'Ce sont les enregistrements déjà marqués À VÉRIFIER — un appui de fin manqué de plus de trois minutes, ou un appui de moins de vingt secondes. Les contractions chronométrées ne sont pas touchées, et Annuler l’action les restaure toutes.',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": 'Contraction',
    "Start or stop a contraction": 'Démarrer ou terminer une contraction',
    "One tap starts the timing; the next ends it.": 'Un toucher démarre le chronométrage ; le suivant l’arrête.',
    "Open Hushlight to time this one.": 'Ouvrez Hushlight pour chronométrer celle-ci.',
})
