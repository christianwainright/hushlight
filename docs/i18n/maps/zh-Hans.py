#!/usr/bin/env python3
"""HL-008 · Simplified Chinese (zh-Hans).

Vocabulary: provider → 助产士或医生; labor and delivery → 产房; guideline → 标准;
stretch → 这一阵; apart → 间隔; slip → 误触; Start / End → 开始 / 结束.

Register: plain, calm, second person 你. **No imperatives in the verdict** —
「现在联系…是合理的」, never 「请联系」. 宫缩 is the clinical word for a contraction and
the one a Chinese-speaking reader expects; the app never says 要生了 or 临产,
because naming the outcome is the diagnosis it does not make.

Chinese has one CLDR plural category (`other`), so plural entries supply only that.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "计时",
    "Go": "前往",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "此设备没有邮件应用。请写信至：",
    "This device cannot place calls. The number:": "此设备无法拨打电话。号码：",
    "Copy address": "复制地址",
    "Copy number": "复制号码",
    "Copies the address": "复制地址",
    "Copies the number": "复制号码",
    "This stretch": "本轮",
    "Each one you time appears here as it happens, with the gap since the one before.": "你计时的每次宫缩都会即时显示在这里，并标出与上一次的间隔。",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "这台iPad保存自己的记录。这里的内容不会与你的iPhone或任何人共享。",
    "Start": "开始", "End": "结束", "Call": "拨打", "Copy": "复制",
    "More": "更多", "Share": "分享", "Copied": "已复制", "Timing": "计时中",
    "Guidance": "标准与联系方式", "Contractions": "宫缩", "For the call": "打电话时用",
    "How it works": "使用方法", "One button": "只有一个按钮",
    "Yours alone": "只属于你", "Report a problem": "反馈问题",
    "What this app is": "关于这个应用", "Your guideline": "你的标准",
    "Start contraction": "开始记录宫缩",
    "End contraction": "结束这次宫缩", "Tap when it begins": "开始时轻点",
    "Tap when it ends": "结束时轻点", "Clear all history?": "清除全部记录？",
    "Call your provider": "拨打助产士或医生的电话",
    "Heartbeat while timing": "计时中的轻震",
    "Breath pacer while timing": "计时中的呼吸引导",
    "Interval is start-to-start": "间隔从这次开始算到下次开始",
    "The timeline reads downward": "记录自上而下阅读",
    "Lock the phone freely": "可以放心锁屏",
    "Your provider or L&D number": "助产士、医生或产房的电话",
    "Your provider or labor and delivery number": "助产士、医生或产房的电话",
    "Call right away — pattern aside": "立即联系 — 与间隔无关",
    "Nothing logged yet.": "还没有记录。",
    "No contractions yet.": "还没有宫缩。",
    "It looks like time.": "看起来时候到了。",
    "History": "记录", "Done": "完成", "Cancel": "取消", "Delete": "删除",
    "Undo": "撤销", "Merge Up": "与上一条合并",
    "Got it": "知道了", "Keep a copy": "保留一份",
    "Clear the instrument": "清空计时",
    "Clear All History…": "清除全部记录…",
    "Save a copy first…": "先保存一份…",
    "Clear Everything": "全部清除",
    "Privacy policy": "隐私政策", "Support": "支持",
    "Rate on the App Store": "在 App Store 评分",
    "CONTRACTIONS": "宫缩", "NOW": "现在", "RUNNING": "计时中",
    "LOCK SCREEN": "锁定屏幕", "1 H AGO": "1 小时前",
    "INTERVAL": "间隔", "DURATION": "时长", "PATTERN": "持续",
    "APART": "间隔", "LONG": "时长", "HOLDING": "持续",
    "SINCE %@": "自 %@", "SINCE YESTERDAY %@": "自昨天 %@",
    "SINCE %@ %@": "自 %@ %@", "LAST %@ AGO": "上次在 %@ 前",
    "%lld TOTAL": "共 %lld 次",
    "CTX": "宫缩", "AVG %@ APART · %lld": "平均间隔 %@ · %lld",
    "LAST %@ APART · %lld": "上次间隔 %@ · %lld",
    "%lld logged": "已记录 %lld 次",
    "Averaging %@ apart, %@": "平均间隔 %@，%@",
    "Last gap %@, %@": "上次间隔 %@，%@",
    "No contractions yet": "还没有宫缩",
    "Opens guidance": "打开标准与联系方式",
    "Starts timing a contraction": "开始为一次宫缩计时",
    "Ends the contraction being timed": "结束正在计时的宫缩",
    "Opens the clear-history confirmation": "打开清除记录的确认",
    "Copies this sentence": "复制这句话",
    "Shows the last stretch, to read or share": "显示最近这一阵，可阅读或分享",
    "Shows one sentence with the pattern, to read or share": "用一句话显示间隔情况，可阅读或分享",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "打开分享面板，包含这句话和这一阵的全部宫缩",
    "Drafts an email you can review before sending": "起草一封你可以在发送前查看的邮件",
    "Removes the slip. Undo is in History.": "移除这次误触。撤销在记录里。",
    "%@.": "%@。", "%@, %@": "%@，%@", "in %@": "吸气 %@", "on %@": "%@", "out %@": "呼气 %@",
    "Call %@": "拨打 %@", "%@ apart": "间隔 %@", "since %@": "自 %@",
    "lasted %@": "持续 %@", "lasting %@": "时长 %@",
    "Started %@": "%@ 开始", "Recorded %@": "记录 %@", "Guideline %@": "标准 %@",
    "going for %@": "已持续 %@", "still running": "仍在计时",
    "since %@ at %@": "自 %@ %@", "under a minute": "不到一分钟",
    "average %@ long": "平均时长 %@", "average %@ apart": "平均间隔 %@",
    "ranging %@ to %@": "%@ 到 %@", "averaging %@ apart": "平均间隔 %@",
    "Contractions, %@": "宫缩，%@", "Last stretch, %@": "最近这一阵，%@",
    "Last stretch: %@": "最近这一阵：%@",
    "Last stretch, %@ over %@": "最近这一阵，%@，历时 %@",
    "Last stretch: %@ over %@": "最近这一阵：%@，历时 %@",
    "since yesterday at %@": "自昨天 %@",
    "closer than an hour ago": "比一小时前更密",
    "farther apart than an hour ago": "比一小时前更疏",
    "not enough evidence yet": "还没有足够的依据",
    "not enough contractions yet": "宫缩次数还不够",
    "%@ after the previous one": "距上一次 %@",
    "contractions in the last hour": "最近一小时的宫缩",
    "over three minutes — check this one": "超过三分钟 — 请核对",
    "under twenty seconds — likely a slip, check this one":
        "不到二十秒 — 可能是误触，请核对",
    "Last contraction ended %@ ago": "上次宫缩结束于 %@ 前",
    "Last contraction ended %@ ago.": "上次宫缩结束于 %@ 前。",
    "Contractions, last one ended %@ ago": "宫缩，上次结束于 %@ 前",
    "Contractions, %@, last one ended %@ ago": "宫缩，%@，上次结束于 %@ 前",
    "Not enough in the last hour to average.": "最近一小时的次数不足以取平均。",
    "Timing this contraction — nothing else in the last hour.": "正在计时 — 最近一小时没有其他记录。",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "上次宫缩在 %@ 前。最近一小时的次数不足以取平均。",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "上次宫缩在 %@ 前 — 最近一小时的次数不足以取平均。",
    "Averaging %@ apart, %@ — was %@.": "平均间隔 %@，%@ — 此前 %@。",
    "Averaging every %@, lasting %@, for %@.": "平均每 %@ 一次，时长 %@，已持续 %@。",
    "Recorded %@ — likely a slip.": "记录 %@ — 可能是误触。",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "记录 %@ — 可能是误触。它已不计入平均。",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "超过三分钟。这通常表示漏点了结束。现在结束会把它排除在平均之外。",
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "还没到 %@ — 时长和持续时间已经达到；间隔为 %@，而标准要求 %@ 或更密。%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "还没到 %@。间隔在 %@ 到 %@ 之间；标准要求 %@ 或更密。时长和持续时间已经达到。%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "还没到 %@。这一阵已连续 %@；标准要求一小时。间隔和时长已经达到。%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "还没到 %@ — 间隔和时长已经达到；这一阵已连续 %@，而标准要求一小时。%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "还没到 %@。宫缩平均时长 %@；标准要求约一分钟。间隔和持续时间已经达到。%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "还没到 %@ — 间隔和持续时间已经达到；宫缩平均时长 %@，而标准要求约一分钟。%@",
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "这符合许多医护人员使用的 %@ 标准。现在联系你的助产士或医生是合理的 — 他们的指示优先。",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "这曾符合许多医护人员使用的 %@ 标准。现在联系你的助产士或医生是合理的 — 他们的指示优先。",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "这曾符合许多医护人员使用的 %@ 标准 — 现在正在计时一次。现在联系你的助产士或医生是合理的 — 他们的指示优先。",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "这曾符合许多医护人员使用的 %@ 标准 — 上次宫缩在 %@ 前。现在联系你的助产士或医生是合理的 — 他们的指示优先。",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "这比 %@ 标准要求的更密，而且还没到它同样要求的一小时。现在联系你的助产士或医生是合理的 — 他们的指示优先。",
    "Your water breaks — note the time and the color of the fluid.":
        "破水时 — 记下时间和羊水的颜色。",
    "Bleeding, more than spotting.": "出血，多于少量血丝。",
    "The baby is moving less than usual.": "宝宝的胎动比平时少。",
    "Regular contractions before 37 weeks.": "37 周之前出现规律宫缩。",
    "Anything that feels wrong to you.": "任何你觉得不对劲的情况。",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "这些都不需要等计时。直接联系你的助产士、医生或产房。",
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "每位医护人员的建议不同 — 是否二胎、到医院的距离、你以往的情况都会改变它。如果你收到过一个标准，在这里设定并按他们的来。",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "只保存在这部手机上。设定后，计时页判断旁边和下方列表里会出现拨打按钮 — 这样这个应用一直建议的那通电话，只需一次轻点，而不是凌晨三点在通讯录里翻找。",
    "A soft pulse every 15 seconds while a contraction is timed":
        "宫缩计时期间每 15 秒一次轻微震动",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "这样手机即使扣着放或装在口袋里也依然可靠。默认关闭，你需要时才开；低电量模式下保持安静。",
    "Counted breaths under the timer — in for 4, out for 6":
        "计时下方的计数呼吸 — 吸气 4 拍，呼气 6 拍",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "宫缩计时期间可以跟着呼吸的慢节奏。光晕保持同样的节奏。",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "每 5 分钟一次，每次约一分钟，持续一小时 — 这是被广泛使用的标准。医护人员的建议不同；计时页上的标签设定你的那一个。当你的间隔真正达到时，应用会说明并建议打电话。",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "没有账户，没有广告，不联网。一切都留在这部手机上，「清除全部记录」随时由你清空。",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "起草一封你可以在发送前阅读和修改的邮件。你的宫缩时间从不包含在内。",
    "Free forever. No account. Works in airplane mode.": "永久免费。无需账户。飞行模式下也能用。",
    "Free forever · no account · works in airplane mode": "永久免费 · 无需账户 · 飞行模式下可用",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "宫缩开始时轻点长条，结束时再点一次。就这么简单。点错了可以在记录里修正 — 左滑删除，撤销可以收回上一次操作。",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "开始时轻点按钮 — 上面的一切都由这一次轻点建立起来。上方的标签保存着别人给你的标准。",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "计时从轻点开始，而轻点比宫缩晚几秒 — 所以记录的时长会比你感觉到的略短。时长判断已经把这一点计算在内；计时页上的数字仍然是记录下来的原值。",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "最新的在上方，每两次之间的间隔就印在它发生的位置。在数据足够说明问题之前，数字保持为破折号 — 破折号是诚实的，猜测不是。",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "计时靠的是时钟，不是屏幕。一旦这一阵开始，按钮也会出现在锁定屏幕上 — 不解锁也能开始和结束。",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "你计时的每一次宫缩都会出现在这里，附带时长和距上一次的间隔。",
    "History has every contraction. The next tap starts a new stretch.":
        "记录里保存着每一次宫缩。下一次轻点会开始新的一阵。",
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "一个会算术的秒表。它测量宫缩，并对照你选择的标准说明间隔情况。它不诊断分娩，也不是医疗建议 — 你的助产士或医生的指示始终优先。拿不准时，打电话。",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "一切都留在这部手机上。没有账户，没有分析，不向任何地方发送。",
    "every %@ on average": "平均每 %@ 一次",
    "every %@ on average (ranging %@–%@)": "平均每 %@ 一次（%@ 到 %@）",
    "lasting about %@": "时长约 %@",
    "Hushlight problem report": "Hushlight 问题反馈",
    "Describe what happened above this line.": "请在这一行上方描述发生了什么。",
    "— About this app and phone (you can delete any line) —":
        "— 关于这个应用和这部手机（任何一行都可以删除） —",
    "App: Hushlight %@": "应用：Hushlight %@", "System: %@ · %@": "系统：%@ · %@",
    "Guideline: %@": "标准：%@", "Recorded: %@ across %@": "已记录：%@／%@",
    "Live Activity on screen: %@": "实时活动显示：%@",
    "yes": "是", "no": "否",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "你的宫缩时间不在这封邮件里。如果修复需要它们，我们会来问，是否发送始终由你决定。",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "在稳定下来之前间隔忽长忽短，正是早期这一阵常见的样子。偶尔计一次也能看出同样的趋势 — 不需要一直盯着。",
}

PLURALS = {
    "%lld contraction": {"other": "%lld 次"},
    "%lld episode": {"other": "%lld 段"},
    "%lld contraction in this stretch": {"other": "这一阵 %lld 次"},
    "%lld minutes": {"other": "%lld 分钟"},
    "%lld seconds": {"other": "%lld 秒"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "other": "仍在计时 — 超过 %lld 分钟通常表示漏点了结束。现在结束会把它排除在平均之外。",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@ %2$#@minutesArg@",
        "args": {"hoursArg": {"other": "%1$lld 小时"}, "minutesArg": {"other": "%2$lld 分钟"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@ %2$#@secondsArg@",
        "args": {"minutesArg": {"other": "%1$lld 分钟"}, "secondsArg": {"other": "%2$lld 秒"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@：宫缩间隔 %2$#@minutesArg@ 或更密，每次约一分钟，持续一小时且中间没有长时间中断。计时会从你的轻点中读出这三项，并在间隔达到时说明。",
        "args": {"minutesArg": {"other": "%2$lld 分钟"}},
    },
}

NEVER_SAYS = [
    "你已经临产",
    "分娩开始了",
    "宝宝要出来了",
    "要生了",
    "不需要去",
    "不用去",
    "你必须",
    "去医院",
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
        '（此前 %@）。',
    ' — %@ apart against %@ on %@.':
        ' — 间隔 %@，此前 %@（%@）。',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '“每 5 分钟”指的是两次宫缩开始之间的间隔 — 和医护人员的测法一致。时长是每一次持续多久；持续是这一阵已经进行了多久。计时从轻点那一刻开始，所以记录的时长会比实际感觉到的宫缩略短一些。',
    '%@ before the next one':
        '距下一次 %@',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@，%@。',
    '%@, met':
        '%@，已达到',
    '%@, not yet':
        '%@，还没有',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        '还有一次宫缩正在计时。此操作会连同这部手机上的其他所有宫缩一并删除。无法撤销。',
    'Averaging %@ apart — ':
        '平均间隔 %@ — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        '在已计时的 %2$lld 次宫缩中平均每 %1$@ 一次，已持续 %3$@。',
    'Contraction %lld, lasted %@, at %@':
        '第 %lld 次宫缩，持续 %@，%@',
    'Contraction %lld, running, %@':
        '第 %lld 次宫缩，计时中，%@',
    'Contractions %@ — %lld so far.':
        '宫缩 %@ — 目前 %lld 次。',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        '手机上保存的崩溃报告：%lld · 卡顿：%lld',
    'Delete %lld Flagged':
        '删除 %lld 条已标记',
    'Delete %lld Flagged…':
        '删除 %lld 条已标记…',
    'Delete flagged records?':
        '删除已标记的记录？',
    'Guideline':
        '标准',
    'Last stretch, %@, %@':
        '最近这一阵，%@，%@',
    'Last stretch, %@, %@ over %@':
        '最近这一阵，%@，%@，历时 %@',
    'Last stretch, %@: %@':
        '最近这一阵，%@：%@',
    'Last stretch, %@: %@ over %@':
        '最近这一阵，%@：%@，历时 %@',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        '还没到 %1$@ — 在已计时的 %4$lld 次宫缩中，平均间隔 %2$@，时长 %3$@。%5$@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        '还没到 %1$@ — 在已计时的 %3$lld 次宫缩中平均间隔 %2$@；已结束的次数还不足以计算平均时长。',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        '还没到 %1$@。在已计时的 %4$lld 次宫缩中，平均间隔 %2$@，时长 %3$@。%5$@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        '还没到 %1$@。在已计时的 %3$lld 次宫缩中平均间隔 %2$@。已结束的次数还不足以计算平均时长。',
    'Optional':
        '可不填',
    'Start or stop a contraction':
        '开始或停止记录一次宫缩',
    "The guideline's three legs, over the last hour":
        '标准的三个条件，最近一小时',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        '这些是已标记 CHECK 的记录 — 结束轻点晚了三分钟以上，或不足二十秒的轻点。已计时的宫缩不受影响，撤销可以把它们全部恢复。',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        '这些平均值覆盖整一阵。计时页面的数字覆盖最近一小时，所以在宫缩越来越密时两者可能不同。',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        '三十秒就能读完 — 想再看时，它一直在上方的问号里等着。',
    'This deletes every contraction on this phone. There is no undo.':
        '这会删除这部手机上的所有宫缩记录。无法撤销。',
    'This stretch is ':
        '这一阵',
    'This stretch is %@, %@ apart against %@ on %@.':
        '这一阵%@，间隔 %@，此前 %@（%@）。',
    'This stretch: %@.':
        '这一阵：%@。',
    'Timing this contraction — %lld in the last hour.':
        '正在计时 — 最近一小时 %lld 次。',
    'about the same as your last stretch':
        '和上一阵差不多',
    'closer together than your last stretch':
        '比上一阵更密',
    'farther apart than your last stretch':
        '比上一阵更疏',
    'now':
        '现在',
    'one hour ago':
        '一小时前',
    'over %@':
        '历时 %@',
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
        '时长 %@',
    '%@ · FROM %@ · %lld':
        '%@ · 自 %@ · %lld',
    '%lld H':
        '%lld 小时',
    '%lld H %lld M':
        '%lld 小时 %lld 分',
    '%lld M':
        '%lld 分',
    'CHECK · OVER %lld MIN':
        '待核对 · 超过 %lld 分钟',
    'CHECK · UNDER %lld S':
        '待核对 · 不足 %lld 秒',
    'OVER %@':
        '历时 %@',
    'THIS STRETCH · AVG %@ APART':
        '这一阵 · 平均间隔 %@',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        '这些是已标记“待核对”的记录 — 结束轻点晚了三分钟以上，或不足二十秒的轻点。已计时的宫缩不受影响，撤销可以把它们全部恢复。',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": '宫缩',
    "Start or stop a contraction": '开始或结束一次宫缩',
    "One tap starts the timing; the next ends it.": '轻点一次开始计时，再点一次结束。',
    "Open Hushlight to time this one.": '请打开 Hushlight 记录这一次。',
})
