#!/usr/bin/env python3
"""HL-008 · Brazilian Portuguese (pt-BR).

Vocabulary: provider → sua obstetra ou seu médico (Brazilian care is
obstetrician-led; "profissional de saúde" is kept for the longer prose where the
shorter pair would repeat awkwardly); labor and delivery → a maternidade;
guideline → a regra; stretch → a série; apart → de intervalo; slip → um toque solto;
Start / End → Iniciar / Encerrar.

Register: `você`. No imperatives in the verdict — "Ligar agora … é razoável", never
"Ligue". Em dashes and ` · ` verbatim; caps come from the type role.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "Cronômetro",
    "Go": "Ir para",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "Este aparelho não tem app de e-mail. Escreva para:",
    "This device cannot place calls. The number:": "Este aparelho não faz ligações. O número:",
    "Copy address": "Copiar endereço",
    "Copy number": "Copiar número",
    "Copies the address": "Copia o endereço",
    "Copies the number": "Copia o número",
    "This stretch": "Esta sequência",
    "Each one you time appears here as it happens, with the gap since the one before.": "Cada contração que você cronometrar aparece aqui na hora, com o intervalo desde a anterior.",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "Este iPad mantém o próprio registro. Nada daqui é compartilhado com o seu iPhone nem com ninguém.",
    "Start": "Iniciar", "End": "Encerrar", "Call": "Ligar", "Copy": "Copiar",
    "More": "Mais", "Share": "Compartilhar", "Copied": "Copiado", "Timing": "Marcando",
    "Guidance": "Orientações", "Contractions": "Contrações", "For the call": "Para a ligação",
    "How it works": "Como funciona", "One button": "Um botão",
    "Yours alone": "Só seu", "Report a problem": "Relatar um problema",
    "What this app is": "O que é este app", "Your guideline": "Sua regra",
    "Start contraction": "Iniciar contração",
    "End contraction": "Encerrar contração", "Tap when it begins": "Toque quando começar",
    "Tap when it ends": "Toque quando terminar", "Clear all history?": "Apagar todo o histórico?",
    "Call your provider": "Ligue para sua obstetra ou seu médico",
    "Heartbeat while timing": "Batida durante a marcação",
    "Breath pacer while timing": "Guia de respiração durante a marcação",
    "Interval is start-to-start": "O intervalo vai de início a início",
    "The timeline reads downward": "A linha do tempo se lê de cima para baixo",
    "Lock the phone freely": "Pode bloquear o telefone",
    "Your provider or L&D number": "Sua obstetra, seu médico ou o número da maternidade",
    "Your provider or labor and delivery number": "Sua obstetra, seu médico ou o número da maternidade",
    "Call right away — pattern aside": "Ligue agora mesmo — independentemente do padrão",
    "Nothing logged yet.": "Nada registrado ainda.",
    "No contractions yet.": "Nenhuma contração ainda.",
    "It looks like time.": "Parece que chegou a hora.",
    "History": "Histórico", "Done": "Concluir", "Cancel": "Cancelar", "Delete": "Excluir",
    "Undo": "Desfazer", "Merge Up": "Juntar com a anterior",
    "Got it": "Entendi", "Keep a copy": "Guardar uma cópia",
    "Clear the instrument": "Limpar o instrumento",
    "Clear All History…": "Apagar todo o histórico…",
    "Save a copy first…": "Salvar uma cópia antes…",
    "Clear Everything": "Apagar tudo",
    "Privacy policy": "Política de privacidade", "Support": "Suporte",
    "Rate on the App Store": "Avaliar na App Store",
    "CONTRACTIONS": "CONTRAÇÕES", "NOW": "AGORA", "RUNNING": "EM ANDAMENTO",
    "LOCK SCREEN": "TELA DE BLOQUEIO", "1 H AGO": "HÁ 1 H",
    "INTERVAL": "Intervalo", "DURATION": "Duração", "PATTERN": "Padrão",
    "APART": "Intervalo", "LONG": "Duração", "HOLDING": "Sustentada",
    "SINCE %@": "DESDE %@", "SINCE YESTERDAY %@": "DESDE ONTEM %@",
    "SINCE %@ %@": "DESDE %@ %@", "LAST %@ AGO": "HÁ %@",
    "%lld TOTAL": "%lld NO TOTAL",
    "CTX": "CTR", "AVG %@ APART · %lld": "MÉD %@ DE INTERVALO · %lld",
    "LAST %@ APART · %lld": "ÚLT %@ DE INTERVALO · %lld",
    "%lld logged": "%lld registradas",
    "Averaging %@ apart, %@": "Em média %@ de intervalo, %@",
    "Last gap %@, %@": "Último intervalo %@, %@",
    "No contractions yet": "Nenhuma contração ainda",
    "Opens guidance": "Abre as orientações",
    "Starts timing a contraction": "Começa a marcar uma contração",
    "Ends the contraction being timed": "Encerra a contração em andamento",
    "Opens the clear-history confirmation": "Abre a confirmação para apagar o histórico",
    "Copies this sentence": "Copia esta frase",
    "Shows the last stretch, to read or share": "Mostra a última série, para ler ou compartilhar",
    "Shows one sentence with the pattern, to read or share": "Mostra uma frase com o padrão, para ler ou compartilhar",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "Abre o menu de compartilhamento com esta frase e todas as contrações desta série",
    "Drafts an email you can review before sending": "Prepara um e-mail que você pode revisar antes de enviar",
    "Removes the slip. Undo is in History.": "Remove o toque solto. Desfazer está no Histórico.",
    "%@.": "%@.", "%@, %@": "%@, %@", "in %@": "em %@", "on %@": "em %@", "out %@": "fora %@",
    "Call %@": "Ligar para %@", "%@ apart": "%@ de intervalo", "since %@": "desde %@",
    "lasted %@": "durou %@", "lasting %@": "de %@",
    "Started %@": "Começou %@", "Recorded %@": "Registrada %@", "Guideline %@": "Regra %@",
    "going for %@": "em andamento há %@", "still running": "ainda em andamento",
    "since %@ at %@": "desde %@ às %@", "under a minute": "menos de um minuto",
    "average %@ long": "%@ de duração em média", "average %@ apart": "%@ de intervalo em média",
    "ranging %@ to %@": "de %@ a %@", "averaging %@ apart": "%@ de intervalo em média",
    "Contractions, %@": "Contrações, %@", "Last stretch, %@": "Última série, %@",
    "Last stretch: %@": "Última série: %@",
    "Last stretch, %@ over %@": "Última série, %@ em %@",
    "Last stretch: %@ over %@": "Última série: %@ em %@",
    "since yesterday at %@": "desde ontem às %@",
    "closer than an hour ago": "mais próximas do que há uma hora",
    "farther apart than an hour ago": "mais espaçadas do que há uma hora",
    "not enough evidence yet": "ainda não há elementos suficientes",
    "not enough contractions yet": "ainda não há contrações suficientes",
    "%@ after the previous one": "%@ depois da anterior",
    "contractions in the last hour": "contrações na última hora",
    "over three minutes — check this one": "mais de três minutos — confira esta",
    "under twenty seconds — likely a slip, check this one":
        "menos de vinte segundos — provavelmente um toque solto, confira esta",
    "Last contraction ended %@ ago": "A última contração terminou há %@",
    "Last contraction ended %@ ago.": "A última contração terminou há %@.",
    "Contractions, last one ended %@ ago": "Contrações, a última terminou há %@",
    "Contractions, %@, last one ended %@ ago": "Contrações, %@, a última terminou há %@",
    "Not enough in the last hour to average.": "Não há o bastante na última hora para uma média.",
    "Timing this contraction — nothing else in the last hour.": "Marcando esta contração — nada mais na última hora.",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "Última contração há %@. Não há o bastante na última hora para uma média.",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "Última contração há %@ — não há o bastante na última hora para uma média.",
    "Averaging %@ apart, %@ — was %@.": "%@ de intervalo em média, %@ — era %@.",
    "Averaging every %@, lasting %@, for %@.": "A cada %@ em média, de %@, por %@.",
    "Recorded %@ — likely a slip.": "Registrada %@ — provavelmente um toque solto.",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "Registrada %@ — provavelmente um toque solto. Já está fora das médias.",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "Mais de três minutos. Isso geralmente significa que faltou o toque de fim. Encerrá-la agora a deixa de fora das médias.",
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "Ainda não em %@ — a duração e a hora estão lá; o intervalo está em %@, e a regra pede %@ ou menos.%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "Ainda não em %@. O intervalo vai de %@ a %@; a regra pede %@ ou menos. A duração e a hora estão lá.%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "Ainda não em %@. Esta série está sem interrupção há %@; a regra pede uma hora. O intervalo e a duração estão lá.%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "Ainda não em %@ — o intervalo e a duração estão lá; esta série está sem interrupção há %@, e a regra pede uma hora.%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "Ainda não em %@. As contrações estão durando %@ em média; a regra pede cerca de um minuto. O intervalo e a hora estão lá.%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "Ainda não em %@ — o intervalo e a hora estão lá; as contrações estão durando %@ em média, e a regra pede cerca de um minuto.%@",
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Isso atende à regra %@ que muitos profissionais usam. Ligar agora para sua obstetra ou seu médico é razoável — as orientações deles vêm primeiro.",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "Isso atendeu à regra %@ que muitos profissionais usam. Ligar agora para sua obstetra ou seu médico é razoável — as orientações deles vêm primeiro.",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "Isso atendeu à regra %@ que muitos profissionais usam — há uma em andamento agora. Ligar agora para sua obstetra ou seu médico é razoável — as orientações deles vêm primeiro.",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "Isso atendeu à regra %@ que muitos profissionais usam — última contração há %@. Ligar agora para sua obstetra ou seu médico é razoável — as orientações deles vêm primeiro.",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "Isso está mais próximo do que a regra %@ pede, antes da hora que ela também pede. Ligar agora para sua obstetra ou seu médico é razoável — as orientações deles vêm primeiro.",
    "Your water breaks — note the time and the color of the fluid.":
        "Sua bolsa rompe — anote a hora e a cor do líquido.",
    "Bleeding, more than spotting.": "Sangramento, mais do que um leve manchado.",
    "The baby is moving less than usual.": "O bebê está se mexendo menos que o normal.",
    "Regular contractions before 37 weeks.": "Contrações regulares antes das 37 semanas.",
    "Anything that feels wrong to you.": "Qualquer coisa que pareça errada para você.",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "Nada disso espera um cronômetro. Ligue direto para sua obstetra, seu médico ou a maternidade.",
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "Cada profissional orienta de um jeito — um segundo bebê, a distância até a maternidade e o seu histórico mudam tudo isso. Se o seu deu uma regra, coloque-a aqui e siga a dele.",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "Fica neste telefone. Depois de salvo, um botão Ligar aparece ao lado do parecer no cronômetro e abaixo da lista — para que a ligação que este app sugere seja um toque, não uma busca nos Contatos às 3 da manhã.",
    "A soft pulse every 15 seconds while a contraction is timed":
        "Um pulso leve a cada 15 segundos enquanto uma contração é marcada",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "Para que o telefone possa ficar virado para baixo ou no bolso e ainda ser confiável. Desligado a não ser que você queira; silencioso no Modo de Baixo Consumo.",
    "Counted breaths under the timer — in for 4, out for 6":
        "Respirações contadas sob o cronômetro — 4 para inspirar, 6 para expirar",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "Uma cadência lenta para respirar enquanto uma contração é marcada. O brilho mantém o mesmo ritmo.",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "A cada 5 minutos, com cerca de um minuto, por uma hora — a regra mais usada. Os profissionais divergem; a etiqueta no cronômetro define a sua. Quando seu padrão realmente atender a ela, o app avisa e sugere a ligação.",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "Sem conta, sem anúncios, sem rede. Tudo fica neste telefone, e Apagar todo o histórico remove quando você quiser.",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "Prepara um e-mail que você pode ler e editar antes de enviar. Os horários das suas contrações nunca são incluídos.",
    "Free forever. No account. Works in airplane mode.": "Grátis para sempre. Sem conta. Funciona em modo avião.",
    "Free forever · no account · works in airplane mode": "Grátis para sempre · sem conta · funciona em modo avião",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "Toque na barra quando uma contração começar e toque de novo quando ela terminar. É só isso. Toques errados se corrigem no Histórico — deslize para excluir, e Desfazer volta o último toque.",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "Toque no botão quando uma começar — tudo acima se constrói a partir desse único toque. A etiqueta lá em cima guarda a regra que lhe deram.",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "A marcação começa no toque, e o toque vem alguns segundos depois da contração — então as durações registradas ficam um pouco atrás do minuto sentido. A verificação de duração leva isso em conta; os números no cronômetro continuam exatamente o que foi registrado.",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "A mais recente no topo, o intervalo entre cada par impresso exatamente onde aconteceu. Os números continuam travessões até haver o bastante para significar algo — um travessão é honesto, um palpite não é.",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "A marcação corre pelo relógio, não pela tela. Quando um padrão está em andamento, o botão fica também na tela de bloqueio — inicie e encerre sem desbloquear.",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "Cada contração que você marca aparece aqui com sua duração e o intervalo desde a anterior.",
    "History has every contraction. The next tap starts a new stretch.":
        "O Histórico tem todas as contrações. O próximo toque começa uma nova série.",
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "Um cronômetro com aritmética. Ele mede as contrações e informa o padrão em relação à regra que você escolheu. Não diagnostica trabalho de parto e não é orientação médica — as orientações da sua obstetra ou do seu médico vêm sempre primeiro. Na dúvida, ligue.",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "Tudo fica neste telefone. Sem conta, sem análises, nada é enviado a lugar nenhum.",
    "every %@ on average": "a cada %@ em média",
    "every %@ on average (ranging %@–%@)": "a cada %@ em média (de %@ a %@)",
    "lasting about %@": "de cerca de %@",
    "Hushlight problem report": "Relato de problema do Hushlight",
    "Describe what happened above this line.": "Descreva o que aconteceu acima desta linha.",
    "— About this app and phone (you can delete any line) —":
        "— Sobre este app e este telefone (você pode apagar qualquer linha) —",
    "App: Hushlight %@": "App: Hushlight %@", "System: %@ · %@": "Sistema: %@ · %@",
    "Guideline: %@": "Regra: %@", "Recorded: %@ across %@": "Registrado: %@ em %@",
    "Live Activity on screen: %@": "Atividade ao vivo na tela: %@",
    "yes": "sim", "no": "não",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "Os horários das suas contrações não estão neste e-mail. Se forem necessários para uma correção, vamos pedir, e enviá-los continuará sendo decisão sua.",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "Um intervalo que varia antes de se firmar é a cara das primeiras séries. Uma série marcada de vez em quando mostra o mesmo padrão — isso não precisa de acompanhamento contínuo.",
}

PLURALS = {
    "%lld contraction": {"one": "%lld contração", "other": "%lld contrações"},
    "%lld episode": {"one": "%lld episódio", "other": "%lld episódios"},
    "%lld contraction in this stretch": {"one": "%lld contração nesta série", "other": "%lld contrações nesta série"},
    "%lld minutes": {"one": "%lld minuto", "other": "%lld minutos"},
    "%lld seconds": {"one": "%lld segundo", "other": "%lld segundos"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "one": "Ainda marcando — mais de %lld minuto geralmente significa que faltou o toque de fim. Encerrá-la agora a deixa de fora das médias.",
        "other": "Ainda marcando — mais de %lld minutos geralmente significa que faltou o toque de fim. Encerrá-la agora a deixa de fora das médias.",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {"hoursArg": {"one": "%1$lld hora", "other": "%1$lld horas"},
                 "minutesArg": {"one": "%2$lld minuto", "other": "%2$lld minutos"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {"minutesArg": {"one": "%1$lld minuto", "other": "%1$lld minutos"},
                 "secondsArg": {"one": "%2$lld segundo", "other": "%2$lld segundos"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@: contrações a cada %2$#@minutesArg@ ou menos, cada uma com cerca de um minuto, por uma hora sem uma pausa longa. O cronômetro lê os três a partir dos seus toques e avisa quando o padrão está lá.",
        "args": {"minutesArg": {"one": "%2$lld minuto", "other": "%2$lld minutos"}},
    },
}

NEVER_SAYS = [
    "você está em trabalho de parto",
    "o trabalho de parto começou",
    "o bebê está chegando",
    "não precisa ir",
    "não é necessário ir",
    "você tem que",
    "vá para a maternidade",
    "vá para o hospital",
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
        ' — %@ de intervalo contra %@ em %@.',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '“A cada 5 minutos” mede o intervalo entre os inícios das contrações — do jeito que os profissionais medem. Duração é quanto cada uma dura; Padrão é há quanto tempo esta série vem acontecendo. A marcação começa no toque, então as durações registradas ficam um pouco atrás da contração sentida.',
    '%@ before the next one':
        '%@ antes da próxima',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@, %@.',
    '%@, met':
        '%@, atendido',
    '%@, not yet':
        '%@, ainda não',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        'Uma contração ainda está sendo marcada. Isso a exclui junto com todas as outras contrações neste telefone. Não há como desfazer.',
    'Averaging %@ apart — ':
        '%@ de intervalo em média — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        'A cada %@ em média em %lld contrações marcadas, por %@.',
    'Contraction %lld, lasted %@, at %@':
        'Contração %lld, durou %@, às %@',
    'Contraction %lld, running, %@':
        'Contração %lld, em andamento, %@',
    'Contractions %@ — %lld so far.':
        'Contrações %@ — %lld até agora.',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        'Relatórios de falha guardados neste telefone: %lld · Travamentos: %lld',
    'Delete %lld Flagged':
        'Excluir %lld marcadas',
    'Delete %lld Flagged…':
        'Excluir %lld marcadas…',
    'Delete flagged records?':
        'Excluir os registros marcados?',
    'Guideline':
        'Regra',
    'Last stretch, %@, %@':
        'Última série, %@, %@',
    'Last stretch, %@, %@ over %@':
        'Última série, %@, %@ em %@',
    'Last stretch, %@: %@':
        'Última série, %@: %@',
    'Last stretch, %@: %@ over %@':
        'Última série, %@: %@ em %@',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Ainda não em %@ — %@ de intervalo e %@ de duração em média em %lld contrações marcadas.%@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        'Ainda não em %@ — %@ de intervalo em média em %lld contrações marcadas; ainda não há encerradas suficientes para calcular a média da duração.',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        'Ainda não em %@. %@ de intervalo e %@ de duração em média em %lld contrações marcadas.%@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        'Ainda não em %@. %@ de intervalo em média em %lld contrações marcadas. Ainda não há encerradas suficientes para calcular a média da duração.',
    'Optional':
        'Opcional',
    'Start or stop a contraction':
        'Inicia ou para uma contração',
    "The guideline's three legs, over the last hour":
        'As três partes da regra, na última hora',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'São os registros já marcados com CHECK — um toque de fim perdido por mais de três minutos, ou um toque com menos de vinte segundos. As contrações marcadas não são afetadas, e Desfazer traz todas de volta.',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        'Estas médias cobrem a série inteira. Os números do cronômetro cobrem a última hora, então podem diferir enquanto as contrações vão ficando mais próximas.',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        'Trinta segundos — e fica esperando sob o ponto de interrogação lá em cima sempre que você quiser de volta.',
    'This deletes every contraction on this phone. There is no undo.':
        'Isso exclui todas as contrações neste telefone. Não há como desfazer.',
    'This stretch is ':
        'Esta série está ',
    'This stretch is %@, %@ apart against %@ on %@.':
        'Esta série está %@, %@ de intervalo contra %@ em %@.',
    'This stretch: %@.':
        'Esta série: %@.',
    'Timing this contraction — %lld in the last hour.':
        'Marcando esta contração — %lld na última hora.',
    'about the same as your last stretch':
        'mais ou menos como sua série anterior',
    'closer together than your last stretch':
        'mais próxima que sua série anterior',
    'farther apart than your last stretch':
        'mais espaçada que sua série anterior',
    'now':
        'agora',
    'one hour ago':
        'há uma hora',
    'over %@':
        'em %@',
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
        '%@ DE DURAÇÃO',
    '%@ · FROM %@ · %lld':
        '%@ · DESDE %@ · %lld',
    '%lld H':
        '%lld H',
    '%lld H %lld M':
        '%lld H %lld M',
    '%lld M':
        '%lld M',
    'CHECK · OVER %lld MIN':
        'CONFERIR · MAIS DE %lld MIN',
    'CHECK · UNDER %lld S':
        'CONFERIR · MENOS DE %lld S',
    'OVER %@':
        'EM %@',
    'THIS STRETCH · AVG %@ APART':
        'ESTA SÉRIE · MÉD %@ DE INTERVALO',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'São os registros já marcados com CONFERIR — um toque de fim perdido por mais de três minutos, ou um toque com menos de vinte segundos. As contrações marcadas não são afetadas, e Desfazer traz todas de volta.',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": 'Contração',
    "Start or stop a contraction": 'Iniciar ou encerrar uma contração',
    "One tap starts the timing; the next ends it.": 'Um toque começa a marcação; o seguinte a encerra.',
    "Open Hushlight to time this one.": 'Abra o Hushlight para marcar esta.',
})
