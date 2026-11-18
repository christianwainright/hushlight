#!/usr/bin/env python3
"""HL-008 · Korean (ko).

Vocabulary: provider → 담당 의료진 (the team seeing you — neutral across 조산사 and
산부인과 의사, both common in Korea); labor and delivery → 분만실; guideline → 기준;
stretch → 이번 진통; apart → 간격; slip → 잘못 누름; Start / End → 시작 / 종료.

Register: 해요체 — polite but warm. 합니다체 would sound like a hospital form, and
this app is a quiet voice at 3am. **No imperatives in the verdict**:
「지금 연락하는 것이 적절해요」, never 「연락하세요」.

Korean has one CLDR plural category (`other`), so plural entries supply only that.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "타이머",
    "Go": "이동",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "이 기기에 메일 앱이 없습니다. 보낼 주소:",
    "This device cannot place calls. The number:": "이 기기에서는 전화를 걸 수 없습니다. 번호:",
    "Copy address": "주소 복사",
    "Copy number": "번호 복사",
    "Copies the address": "주소를 복사합니다",
    "Copies the number": "번호를 복사합니다",
    "This stretch": "이번 흐름",
    "Each one you time appears here as it happens, with the gap since the one before.": "측정한 진통은 바로 여기에 표시되며, 이전 진통과의 간격도 함께 보입니다.",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "이 iPad는 자체 기록을 보관합니다. 여기 있는 내용은 iPhone이나 다른 누구와도 공유되지 않습니다.",
    "Start": "시작", "End": "종료", "Call": "전화", "Copy": "복사",
    "More": "더 보기", "Share": "공유", "Copied": "복사됨", "Timing": "측정 중",
    "Guidance": "기준과 연락처", "Contractions": "진통", "For the call": "전화할 때",
    "How it works": "사용 방법", "One button": "버튼 하나",
    "Yours alone": "오직 당신의 것", "Report a problem": "문제 신고",
    "What this app is": "이 앱에 대해", "Your guideline": "나의 기준",
    "Start contraction": "진통 시작",
    "End contraction": "진통 종료", "Tap when it begins": "시작되면 누르세요",
    "Tap when it ends": "끝나면 누르세요", "Clear all history?": "기록을 모두 지울까요?",
    "Call your provider": "담당 의료진에게 전화",
    "Heartbeat while timing": "측정 중 진동",
    "Breath pacer while timing": "측정 중 호흡 안내",
    "Interval is start-to-start": "간격은 시작에서 시작까지예요",
    "The timeline reads downward": "기록은 위에서 아래로 읽어요",
    "Lock the phone freely": "화면을 잠가도 괜찮아요",
    "Your provider or L&D number": "담당 의료진 또는 분만실 번호",
    "Your provider or labor and delivery number": "담당 의료진 또는 분만실 번호",
    "Call right away — pattern aside": "바로 연락하세요 — 간격과 관계없이",
    "Nothing logged yet.": "아직 기록이 없어요.",
    "No contractions yet.": "아직 진통이 없어요.",
    "It looks like time.": "그때가 온 것 같아요.",
    "History": "기록", "Done": "완료", "Cancel": "취소", "Delete": "삭제",
    "Undo": "실행 취소", "Merge Up": "이전 기록과 합치기",
    "Got it": "알겠어요", "Keep a copy": "사본 보관",
    "Clear the instrument": "측정 화면 비우기",
    "Clear All History…": "기록 모두 지우기…",
    "Save a copy first…": "먼저 사본 저장…",
    "Clear Everything": "모두 지우기",
    "Privacy policy": "개인정보 처리방침", "Support": "지원",
    "Rate on the App Store": "App Store에서 평가하기",
    "CONTRACTIONS": "진통", "NOW": "지금", "RUNNING": "측정 중",
    "LOCK SCREEN": "잠금 화면", "1 H AGO": "1시간 전",
    "INTERVAL": "간격", "DURATION": "길이", "PATTERN": "지속",
    "APART": "간격", "LONG": "길이", "HOLDING": "지속",
    "SINCE %@": "%@부터", "SINCE YESTERDAY %@": "어제 %@부터",
    "SINCE %@ %@": "%@ %@부터", "LAST %@ AGO": "마지막 %@ 전",
    "%lld TOTAL": "총 %lld",
    "CTX": "진통", "AVG %@ APART · %lld": "평균 %@ 간격 · %lld",
    "LAST %@ APART · %lld": "최근 %@ 간격 · %lld",
    "%lld logged": "%lld회 기록",
    "Averaging %@ apart, %@": "평균 %@ 간격, %@",
    "Last gap %@, %@": "최근 간격 %@, %@",
    "No contractions yet": "아직 진통이 없어요",
    "Opens guidance": "기준과 연락처를 엽니다",
    "Starts timing a contraction": "진통 측정을 시작합니다",
    "Ends the contraction being timed": "측정 중인 진통을 종료합니다",
    "Opens the clear-history confirmation": "기록 삭제 확인을 엽니다",
    "Copies this sentence": "이 문장을 복사합니다",
    "Shows the last stretch, to read or share": "최근 진통을 보여줍니다. 읽거나 공유할 수 있어요",
    "Shows one sentence with the pattern, to read or share": "간격을 담은 한 문장을 보여줍니다. 읽거나 공유할 수 있어요",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "이 문장과 이번 진통의 모든 기록을 공유 시트로 엽니다",
    "Drafts an email you can review before sending": "보내기 전에 확인할 수 있는 이메일을 작성합니다",
    "Removes the slip. Undo is in History.": "잘못 누른 기록을 지웁니다. 실행 취소는 기록에 있어요.",
    "%@.": "%@.", "%@, %@": "%@, %@", "in %@": "들이쉬기 %@", "on %@": "%@", "out %@": "내쉬기 %@",
    "Call %@": "%@에 전화", "%@ apart": "%@ 간격", "since %@": "%@부터",
    "lasted %@": "%@ 지속", "lasting %@": "길이 %@",
    "Started %@": "%@에 시작", "Recorded %@": "%@ 기록", "Guideline %@": "기준 %@",
    "going for %@": "%@ 진행 중", "still running": "측정 중",
    "since %@ at %@": "%@ %@부터", "under a minute": "1분 미만",
    "average %@ long": "평균 길이 %@", "average %@ apart": "평균 %@ 간격",
    "ranging %@ to %@": "%@에서 %@", "averaging %@ apart": "평균 %@ 간격",
    "Contractions, %@": "진통, %@", "Last stretch, %@": "최근 진통, %@",
    "Last stretch: %@": "최근 진통: %@",
    "Last stretch, %@ over %@": "최근 진통, %@를 %@ 동안",
    "Last stretch: %@ over %@": "최근 진통: %@를 %@ 동안",
    "since yesterday at %@": "어제 %@부터",
    "closer than an hour ago": "한 시간 전보다 짧은 간격",
    "farther apart than an hour ago": "한 시간 전보다 긴 간격",
    "not enough evidence yet": "아직 판단할 근거가 부족해요",
    "not enough contractions yet": "아직 진통 횟수가 부족해요",
    "%@ after the previous one": "이전에서 %@",
    "contractions in the last hour": "최근 한 시간의 진통",
    "over three minutes — check this one": "3분 초과 — 확인해 보세요",
    "under twenty seconds — likely a slip, check this one":
        "20초 미만 — 잘못 눌렀을 수 있어요, 확인해 보세요",
    "Last contraction ended %@ ago": "마지막 진통이 끝난 지 %@",
    "Last contraction ended %@ ago.": "마지막 진통이 끝난 지 %@.",
    "Contractions, last one ended %@ ago": "진통, 마지막이 끝난 지 %@",
    "Contractions, %@, last one ended %@ ago": "진통, %@, 마지막이 끝난 지 %@",
    "Not enough in the last hour to average.": "최근 한 시간으로는 평균을 낼 만큼이 안 돼요.",
    "Timing this contraction — nothing else in the last hour.": "이 진통을 측정 중 — 최근 한 시간에 다른 기록은 없어요.",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "마지막 진통에서 %@. 최근 한 시간으로는 평균을 낼 만큼이 안 돼요.",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "마지막 진통에서 %@ — 최근 한 시간으로는 평균을 낼 만큼이 안 돼요.",
    "Averaging %@ apart, %@ — was %@.": "평균 %@ 간격, %@ — 이전 %@.",
    "Averaging every %@, lasting %@, for %@.": "평균 %@ 간격, 길이 %@, %@ 동안.",
    "Recorded %@ — likely a slip.": "%@ 기록 — 잘못 눌렀을 수 있어요.",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "%@ 기록 — 잘못 눌렀을 수 있어요. 이미 평균에서는 빠져 있어요.",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "3분이 넘었어요. 대개 종료를 누르지 않은 경우예요. 지금 종료하면 평균에서는 빠집니다.",
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "아직 %@은 아니에요 — 길이와 시간은 충족했어요. 간격은 %@이고, 기준은 %@ 이하예요.%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "아직 %@은 아니에요. 간격은 %@에서 %@. 기준은 %@ 이하예요. 길이와 시간은 충족했어요.%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "아직 %@은 아니에요. 이번 진통은 %@ 동안 끊기지 않았어요. 기준은 한 시간이에요. 간격과 길이는 충족했어요.%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "아직 %@은 아니에요 — 간격과 길이는 충족했어요. 이번 진통은 %@ 동안 끊기지 않았고, 기준은 한 시간이에요.%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "아직 %@은 아니에요. 진통 길이는 평균 %@. 기준은 약 1분이에요. 간격과 시간은 충족했어요.%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "아직 %@은 아니에요 — 간격과 시간은 충족했어요. 진통 길이는 평균 %@이고, 기준은 약 1분이에요.%@",
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "많은 의료진이 쓰는 %@ 기준을 충족해요. 지금 담당 의료진에게 연락하는 것이 적절해요 — 그쪽 지시가 우선입니다.",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "많은 의료진이 쓰는 %@ 기준을 충족했어요. 지금 담당 의료진에게 연락하는 것이 적절해요 — 그쪽 지시가 우선입니다.",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "많은 의료진이 쓰는 %@ 기준을 충족했어요 — 지금 한 번을 측정 중이에요. 지금 담당 의료진에게 연락하는 것이 적절해요 — 그쪽 지시가 우선입니다.",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "많은 의료진이 쓰는 %@ 기준을 충족했어요 — 마지막 진통에서 %@. 지금 담당 의료진에게 연락하는 것이 적절해요 — 그쪽 지시가 우선입니다.",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "%@ 기준이 요구하는 것보다 간격이 짧고, 기준이 함께 요구하는 한 시간에는 이르지 않았어요. 지금 담당 의료진에게 연락하는 것이 적절해요 — 그쪽 지시가 우선입니다.",
    "Your water breaks — note the time and the color of the fluid.":
        "양수가 터졌을 때 — 시각과 양수의 색을 적어 두세요.",
    "Bleeding, more than spotting.": "출혈이 소량의 비침보다 많을 때.",
    "The baby is moving less than usual.": "아기의 움직임이 평소보다 적을 때.",
    "Regular contractions before 37 weeks.": "37주 이전의 규칙적인 진통.",
    "Anything that feels wrong to you.": "평소와 다르다고 느껴지는 모든 것.",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "이 중 어느 것도 측정을 기다리지 않아요. 담당 의료진이나 분만실로 바로 연락하세요.",
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "의료진마다 안내가 달라요 — 둘째인지, 병원까지의 거리, 그동안의 경과에 따라 달라집니다. 받은 기준이 있다면 여기에 설정하고 그쪽을 따르세요.",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "이 기기에만 저장돼요. 설정하면 측정 화면의 판단 옆과 아래 목록에 전화 버튼이 생깁니다 — 이 앱이 계속 권하는 연락이, 새벽 3시에 연락처를 뒤지는 대신 한 번 누르는 일이 됩니다.",
    "A soft pulse every 15 seconds while a contraction is timed":
        "진통을 측정하는 동안 15초마다 부드러운 진동",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "기기를 엎어 두거나 주머니에 넣어도 믿을 수 있도록. 원할 때만 켜지고, 저전력 모드에서는 조용합니다.",
    "Counted breaths under the timer — in for 4, out for 6":
        "측정 아래에서 세는 호흡 — 4에 들이쉬고, 6에 내쉬기",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "진통을 측정하는 동안 함께 호흡할 느린 박자. 빛도 같은 리듬을 유지해요.",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "5분마다, 한 번에 약 1분, 한 시간 동안 — 널리 쓰이는 기준이에요. 의료진마다 다르며, 측정 화면의 표시로 내 기준을 정합니다. 정말로 충족했을 때 앱이 알려주고 연락을 권해요.",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "계정 없음, 광고 없음, 네트워크 없음. 모든 것이 이 기기에 남고, 기록 모두 지우기로 언제든 없앨 수 있어요.",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "보내기 전에 읽고 고칠 수 있는 이메일을 작성해요. 진통 시각은 절대 포함되지 않아요.",
    "Free forever. No account. Works in airplane mode.": "영원히 무료. 계정 없음. 비행기 모드에서도 작동해요.",
    "Free forever · no account · works in airplane mode": "영원히 무료 · 계정 없음 · 비행기 모드에서도 작동",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "진통이 시작되면 막대를 누르고, 끝나면 다시 누르세요. 그게 전부예요. 잘못 누른 것은 기록에서 고칠 수 있어요 — 밀어서 삭제하고, 실행 취소로 마지막 동작을 되돌립니다.",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "시작되면 버튼을 누르세요 — 위의 모든 것이 그 한 번의 누름에서 만들어져요. 위쪽 표시에는 받은 기준이 담깁니다.",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "측정은 누르는 순간 시작되고, 누름은 진통보다 몇 초 늦어요 — 그래서 기록된 길이는 느낀 시간보다 조금 짧습니다. 길이 판정은 그것을 감안해요. 화면의 숫자는 기록된 그대로예요.",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "가장 최근이 위에, 각 쌍 사이의 간격은 그 일이 있었던 자리에 그대로 표시돼요. 의미를 가질 만큼 모이기 전까지 숫자는 대시로 남습니다 — 대시는 정직하고, 추측은 그렇지 않아요.",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "측정은 화면이 아니라 시계로 흘러가요. 진통이 이어지면 잠금 화면에도 버튼이 생깁니다 — 잠금을 풀지 않고 시작하고 끝낼 수 있어요.",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "측정한 모든 진통이 길이와 이전 진통에서의 간격과 함께 여기에 나타나요.",
    "History has every contraction. The next tap starts a new stretch.":
        "기록에는 모든 진통이 남아요. 다음 누름부터 새로운 진통이 시작됩니다.",
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "계산이 붙은 스톱워치예요. 진통을 재고, 고른 기준에 견주어 간격을 알려줍니다. 진통을 진단하지 않고 의학적 조언도 아니에요 — 담당 의료진의 지시가 언제나 우선입니다. 망설여지면 연락하세요.",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "모든 것이 이 기기에 남아요. 계정 없음, 분석 없음, 어디로도 전송하지 않아요.",
    "every %@ on average": "평균 %@마다",
    "every %@ on average (ranging %@–%@)": "평균 %@마다 (%@~%@)",
    "lasting about %@": "길이 약 %@",
    "Hushlight problem report": "Hushlight 문제 신고",
    "Describe what happened above this line.": "이 줄 위에 무슨 일이 있었는지 적어 주세요.",
    "— About this app and phone (you can delete any line) —":
        "— 이 앱과 기기에 대해 (어느 줄이든 지워도 됩니다) —",
    "App: Hushlight %@": "앱: Hushlight %@", "System: %@ · %@": "시스템: %@ · %@",
    "Guideline: %@": "기준: %@", "Recorded: %@ across %@": "기록: %@ / %@",
    "Live Activity on screen: %@": "실시간 활동 표시: %@",
    "yes": "예", "no": "아니요",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "진통 시각은 이 이메일에 없어요. 수정에 필요하면 저희가 여쭤보고, 보낼지는 계속 당신이 정합니다.",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "자리를 잡기 전 간격이 들쭉날쭉한 것은 초기 진통에서 흔한 모습이에요. 가끔 재어도 같은 흐름이 보입니다 — 계속 지켜볼 필요는 없어요.",
}

PLURALS = {
    "%lld contraction": {"other": "%lld회"},
    "%lld episode": {"other": "%lld건"},
    "%lld contraction in this stretch": {"other": "이번 진통에서 %lld회"},
    "%lld minutes": {"other": "%lld분"},
    "%lld seconds": {"other": "%lld초"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "other": "아직 측정 중 — %lld분이 넘는 것은 대개 종료를 누르지 않은 경우예요. 지금 종료하면 평균에서는 빠집니다.",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {"hoursArg": {"other": "%1$lld시간"}, "minutesArg": {"other": "%2$lld분"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {"minutesArg": {"other": "%1$lld분"}, "secondsArg": {"other": "%2$lld초"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@: 진통이 %2$#@minutesArg@ 이하 간격으로, 한 번에 약 1분씩, 긴 끊김 없이 한 시간 이어지는 것. 측정은 당신의 누름에서 세 가지를 모두 읽고, 다 갖춰지면 알려줍니다.",
        "args": {"minutesArg": {"other": "%2$lld분"}},
    },
}

NEVER_SAYS = [
    "진통이 시작되었습니다",
    "분만이 시작되었습니다",
    "아기가 나옵니다",
    "갈 필요 없습니다",
    "가지 않아도 됩니다",
    "해야 합니다",
    "병원으로 가세요",
    "분만실로 가세요",
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
        ' (이전 %@).',
    ' — %@ apart against %@ on %@.':
        ' — %@ 간격 (이전 %@, %@).',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '“5분마다”는 진통이 시작된 지점부터 다음 진통이 시작될 때까지의 간격을 말해요 — 의료진이 재는 방식과 같아요. 길이는 한 번이 얼마나 이어지는지, 지속은 이번 진통이 얼마나 계속되고 있는지예요. 측정은 누른 순간부터 시작하므로, 기록된 길이는 실제로 느낀 진통보다 조금 짧게 남아요.',
    '%@ before the next one':
        '다음까지 %@',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@, %@.',
    '%@, met':
        '%@, 충족',
    '%@, not yet':
        '%@, 아직',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        '측정 중인 진통이 있어요. 이 작업은 그 기록과 이 기기의 다른 모든 진통을 함께 지웁니다. 되돌릴 수 없어요.',
    'Averaging %@ apart — ':
        '평균 %@ 간격 — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        '측정한 %2$lld회에서 평균 %1$@ 간격, %3$@ 동안.',
    'Contraction %lld, lasted %@, at %@':
        '진통 %lld, %@ 지속, %@',
    'Contraction %lld, running, %@':
        '진통 %lld, 측정 중, %@',
    'Contractions %@ — %lld so far.':
        '진통 %@ — 지금까지 %lld회.',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        '기기에 남은 충돌 보고서: %lld · 멈춤: %lld',
    'Delete %lld Flagged':
        '표시된 %lld개 삭제',
    'Delete %lld Flagged…':
        '표시된 %lld개 삭제…',
    'Delete flagged records?':
        '표시된 기록을 지울까요?',
    'Guideline':
        '기준',
    'Last stretch, %@, %@':
        '최근 진통, %@, %@',
    'Last stretch, %@, %@ over %@':
        '최근 진통, %@, %@를 %@ 동안',
    'Last stretch, %@: %@':
        '최근 진통, %@: %@',
    'Last stretch, %@: %@ over %@':
        '최근 진통, %@: %@를 %@ 동안',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        '아직 %1$@은 아니에요 — 측정한 %4$lld회에서 평균 %2$@ 간격, 길이 %3$@.%5$@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        '아직 %1$@은 아니에요 — 측정한 %3$lld회에서 평균 %2$@ 간격. 길이의 평균을 내기에는 끝난 횟수가 아직 부족해요.',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        '아직 %1$@은 아니에요. 측정한 %4$lld회에서 평균 %2$@ 간격, 길이 %3$@.%5$@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        '아직 %1$@은 아니에요. 측정한 %3$lld회에서 평균 %2$@ 간격. 길이의 평균을 내기에는 끝난 횟수가 아직 부족해요.',
    'Optional':
        '선택 사항',
    'Start or stop a contraction':
        '진통 측정을 시작하거나 멈춥니다',
    "The guideline's three legs, over the last hour":
        '기준의 세 가지 조건, 최근 한 시간',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'CHECK 표시가 붙은 기록이에요 — 종료 탭이 3분 넘게 늦었거나, 20초 미만인 탭입니다. 제대로 측정된 진통은 그대로 남고, 실행 취소로 모두 되돌릴 수 있어요.',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        '이 평균은 진통 전체를 대상으로 해요. 타이머 화면의 숫자는 최근 한 시간을 대상으로 하기 때문에, 간격이 좁아지는 동안에는 서로 다를 수 있어요.',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        '30초면 읽어요 — 다시 보고 싶으면 위쪽 물음표 아래에 늘 있어요.',
    'This deletes every contraction on this phone. There is no undo.':
        '이 기기의 모든 진통 기록을 지웁니다. 되돌릴 수 없어요.',
    'This stretch is ':
        '이번 진통은 ',
    'This stretch is %@, %@ apart against %@ on %@.':
        '이번 진통은 %@, %@ 간격 (이전 %@, %@).',
    'This stretch: %@.':
        '이번 진통: %@.',
    'Timing this contraction — %lld in the last hour.':
        '이 진통을 측정 중 — 최근 한 시간에 %lld회.',
    'about the same as your last stretch':
        '지난번 진통과 비슷한 정도',
    'closer together than your last stretch':
        '지난번 진통보다 간격이 짧은 편',
    'farther apart than your last stretch':
        '지난번 진통보다 간격이 긴 편',
    'now':
        '지금',
    'one hour ago':
        '한 시간 전',
    'over %@':
        '%@ 동안',
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
        '길이 %@',
    '%@ · FROM %@ · %lld':
        '%@ · %@부터 · %lld',
    '%lld H':
        '%lld시간',
    '%lld H %lld M':
        '%lld시간 %lld분',
    '%lld M':
        '%lld분',
    'CHECK · OVER %lld MIN':
        '확인 · %lld분 초과',
    'CHECK · UNDER %lld S':
        '확인 · %lld초 미만',
    'OVER %@':
        '%@ 동안',
    'THIS STRETCH · AVG %@ APART':
        '이번 진통 · 평균 %@ 간격',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        '‘확인’ 표시가 붙은 기록이에요 — 종료 탭이 3분 넘게 늦었거나, 20초 미만인 탭입니다. 제대로 측정된 진통은 그대로 남고, 실행 취소로 모두 되돌릴 수 있어요.',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": '진통',
    "Start or stop a contraction": '진통 측정 시작 또는 종료',
    "One tap starts the timing; the next ends it.": '한 번 누르면 측정이 시작되고, 다음에 누르면 끝납니다.',
    "Open Hushlight to time this one.": '이번 진통을 측정하려면 Hushlight를 여세요.',
})
