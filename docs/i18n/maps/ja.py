#!/usr/bin/env python3
"""HL-008 · Japanese (ja).

Vocabulary: provider → 助産師さんや医師 (Japanese maternity care is midwife-led;
かかりつけ carries "the one who has been seeing you"); labor and delivery → 産院;
guideline → 目安 (a reference point, not 規則 which reads as a regulation);
stretch → 一連; apart → 間隔; slip → 誤タップ; Start / End → 開始 / 終了.

Register: です/ます, quiet. **No imperatives in the verdict** — 「連絡するのは妥当です」,
never 「連絡してください」, which would make the app the instruction-giver the whole
design refuses to be. 陣痛 is used for the contraction itself; the app never says
出産/分娩 (birth/delivery), because naming the outcome is the diagnosis it does not make.

Japanese has one CLDR plural category (`other`), so every plural entry supplies only
that — English's `one` would be a rule this language never selects.
Em dashes and ` · ` are kept: they are the design's own punctuation and read cleanly
in Japanese typography.
"""

TRANSLATIONS = {
    # HL-058b (the keyboard's menu titles).
    "Timer": "タイマー",
    "Go": "移動",
    # HL-057 (the hand-off fallbacks) and HL-058a (the iPad ledger and Guidance).
    "No mail app on this device. Write to:": "この端末にはメールアプリがありません。宛先：",
    "This device cannot place calls. The number:": "この端末では電話をかけられません。番号：",
    "Copy address": "アドレスをコピー",
    "Copy number": "番号をコピー",
    "Copies the address": "アドレスをコピーします",
    "Copies the number": "番号をコピーします",
    "This stretch": "今回の連続",
    "Each one you time appears here as it happens, with the gap since the one before.": "計測した陣痛はその場でここに表示され、前回からの間隔も示されます。",
    "This iPad keeps its own record. Nothing here is shared with your iPhone or with anyone.": "このiPadは独自の記録を保持します。ここにある内容はiPhoneにも誰にも共有されません。",
    "Start": "開始", "End": "終了", "Call": "電話", "Copy": "コピー",
    "More": "その他", "Share": "共有", "Copied": "コピーしました", "Timing": "計測中",
    "Guidance": "目安と連絡先", "Contractions": "陣痛", "For the call": "電話のときに",
    "How it works": "使いかた", "One button": "ボタンひとつ",
    "Yours alone": "あなただけのもの", "Report a problem": "問題を報告",
    "What this app is": "このアプリについて", "Your guideline": "あなたの目安",
    "Start contraction": "陣痛を開始",
    "End contraction": "陣痛を終了", "Tap when it begins": "始まったらタップ",
    "Tap when it ends": "終わったらタップ", "Clear all history?": "履歴をすべて消去しますか？",
    "Call your provider": "助産師さんや医師に電話",
    "Heartbeat while timing": "計測中の鼓動",
    "Breath pacer while timing": "計測中の呼吸ガイド",
    "Interval is start-to-start": "間隔は始まりから始まりまで",
    "The timeline reads downward": "記録は上から下へ読みます",
    "Lock the phone freely": "画面は閉じてかまいません",
    "Your provider or L&D number": "助産師さん・医師・産院の電話番号",
    "Your provider or labor and delivery number": "助産師さん・医師・産院の電話番号",
    "Call right away — pattern aside": "すぐに連絡を — 間隔に関係なく",
    "Nothing logged yet.": "まだ記録はありません。",
    "No contractions yet.": "まだ陣痛はありません。",
    "It looks like time.": "そのときが来たようです。",
    "History": "履歴", "Done": "完了", "Cancel": "キャンセル", "Delete": "削除",
    "Undo": "取り消す", "Merge Up": "前の記録と統合",
    "Got it": "わかりました", "Keep a copy": "控えを残す",
    "Clear the instrument": "計測をクリア",
    "Clear All History…": "履歴をすべて消去…",
    "Save a copy first…": "先に控えを保存…",
    "Clear Everything": "すべて消去",
    "Privacy policy": "プライバシーポリシー", "Support": "サポート",
    "Rate on the App Store": "App Storeで評価",
    "CONTRACTIONS": "陣痛", "NOW": "現在", "RUNNING": "計測中",
    "LOCK SCREEN": "ロック画面", "1 H AGO": "1時間前",
    "INTERVAL": "間隔", "DURATION": "長さ", "PATTERN": "継続",
    "APART": "間隔", "LONG": "長さ", "HOLDING": "継続",
    "SINCE %@": "%@から", "SINCE YESTERDAY %@": "昨日%@から",
    "SINCE %@ %@": "%@%@から", "LAST %@ AGO": "最後は%@前",
    "%lld TOTAL": "合計%lld",
    "CTX": "陣痛", "AVG %@ APART · %lld": "平均%@間隔 · %lld",
    "LAST %@ APART · %lld": "直近%@間隔 · %lld",
    "%lld logged": "%lld回記録",
    "Averaging %@ apart, %@": "平均%@間隔、%@",
    "Last gap %@, %@": "直近の間隔%@、%@",
    "No contractions yet": "まだ陣痛はありません",
    "Opens guidance": "目安と連絡先を開きます",
    "Starts timing a contraction": "陣痛の計測を開始します",
    "Ends the contraction being timed": "計測中の陣痛を終了します",
    "Opens the clear-history confirmation": "履歴消去の確認を開きます",
    "Copies this sentence": "この文をコピーします",
    "Shows the last stretch, to read or share": "直近の一連を表示します。読むことも共有することもできます",
    "Shows one sentence with the pattern, to read or share": "間隔をまとめた一文を表示します。読むことも共有することもできます",
    "Opens the share sheet with this sentence and every contraction in this stretch":
        "この文とこの一連のすべての陣痛を共有シートで開きます",
    "Drafts an email you can review before sending": "送信前に確認できるメールを下書きします",
    "Removes the slip. Undo is in History.": "誤タップを取り除きます。取り消しは履歴にあります。",
    "%@.": "%@。", "%@, %@": "%@、%@", "in %@": "吸う%@", "on %@": "%@", "out %@": "吐く%@",
    "Call %@": "%@に電話", "%@ apart": "%@間隔", "since %@": "%@から",
    "lasted %@": "%@継続", "lasting %@": "長さ%@",
    "Started %@": "%@に開始", "Recorded %@": "%@を記録", "Guideline %@": "目安 %@",
    "going for %@": "%@継続中", "still running": "計測中",
    "since %@ at %@": "%@の%@から", "under a minute": "1分未満",
    "average %@ long": "平均の長さ%@", "average %@ apart": "平均%@間隔",
    "ranging %@ to %@": "%@から%@", "averaging %@ apart": "平均%@間隔",
    "Contractions, %@": "陣痛、%@", "Last stretch, %@": "直近の一連、%@",
    "Last stretch: %@": "直近の一連：%@",
    "Last stretch, %@ over %@": "直近の一連、%@を%@で",
    "Last stretch: %@ over %@": "直近の一連：%@を%@で",
    "since yesterday at %@": "昨日の%@から",
    "closer than an hour ago": "1時間前より短い間隔",
    "farther apart than an hour ago": "1時間前より長い間隔",
    "not enough evidence yet": "まだ判断できる材料がありません",
    "not enough contractions yet": "まだ陣痛の回数が足りません",
    "%@ after the previous one": "前から%@",
    "contractions in the last hour": "この1時間の陣痛",
    "over three minutes — check this one": "3分超 — 確認してください",
    "under twenty seconds — likely a slip, check this one":
        "20秒未満 — 誤タップの可能性、確認してください",
    "Last contraction ended %@ ago": "最後の陣痛が終わって%@",
    "Last contraction ended %@ ago.": "最後の陣痛が終わって%@。",
    "Contractions, last one ended %@ ago": "陣痛、最後が終わって%@",
    "Contractions, %@, last one ended %@ ago": "陣痛、%@、最後が終わって%@",
    "Not enough in the last hour to average.": "この1時間では平均を出せる回数がありません。",
    "Timing this contraction — nothing else in the last hour.": "この陣痛を計測中 — この1時間に他はありません。",
    "Last contraction %@ ago. Not enough in the last hour to average.":
        "最後の陣痛から%@。この1時間では平均を出せる回数がありません。",
    "Last contraction %@ ago — not enough in the last hour to average.":
        "最後の陣痛から%@ — この1時間では平均を出せる回数がありません。",
    "Averaging %@ apart, %@ — was %@.": "平均%@間隔、%@ — 以前は%@。",
    "Averaging every %@, lasting %@, for %@.": "平均%@間隔、長さ%@、%@継続。",
    "Recorded %@ — likely a slip.": "%@を記録 — 誤タップの可能性。",
    "Recorded %@ — likely a slip. It is already out of the averages.":
        "%@を記録 — 誤タップの可能性。すでに平均からは外れています。",
    "Over three minutes. That usually means a missed end tap. Ending it now sets it aside from the averages.":
        "3分を超えています。多くは終了のタップが抜けた場合です。ここで終了すると平均からは外れます。",
    "Not at %@ yet — length and the hour are there; spacing runs %@, and the guideline asks for %@ or closer.%@":
        "まだ%@ではありません — 長さと時間は満たしています。間隔は%@で、目安は%@以下です。%@",
    "Not at %@ yet. Spacing runs %@ to %@; the guideline asks for %@ or closer. Length and the hour are there.%@":
        "まだ%@ではありません。間隔は%@から%@。目安は%@以下です。長さと時間は満たしています。%@",
    "Not at %@ yet. This stretch has been unbroken for %@; the guideline asks for an hour. Spacing and length are there.%@":
        "まだ%@ではありません。この一連は%@途切れていません。目安は1時間です。間隔と長さは満たしています。%@",
    "Not at %@ yet — spacing and length are there; this stretch has been unbroken for %@, and the guideline asks for an hour.%@":
        "まだ%@ではありません — 間隔と長さは満たしています。この一連は%@途切れておらず、目安は1時間です。%@",
    "Not at %@ yet. Contractions are averaging %@; the guideline asks for about a minute. Spacing and the hour are there.%@":
        "まだ%@ではありません。陣痛の長さは平均%@。目安は約1分です。間隔と時間は満たしています。%@",
    "Not at %@ yet — spacing and the hour are there; contractions are averaging %@, and the guideline asks for about a minute.%@":
        "まだ%@ではありません — 間隔と時間は満たしています。陣痛の長さは平均%@で、目安は約1分です。%@",
    "That meets the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "多くの医療者が使う%@の目安を満たしています。今、助産師さんや医師に連絡するのは妥当です — その指示が最優先です。",
    "That met the %@ guideline many providers use. Calling your provider now is reasonable — their instructions come first.":
        "多くの医療者が使う%@の目安を満たしていました。今、助産師さんや医師に連絡するのは妥当です — その指示が最優先です。",
    "That met the %@ guideline many providers use — timing one now. Calling your provider now is reasonable — their instructions come first.":
        "多くの医療者が使う%@の目安を満たしていました — 現在1回を計測中です。今、助産師さんや医師に連絡するのは妥当です — その指示が最優先です。",
    "That met the %@ guideline many providers use — last contraction %@ ago. Calling your provider now is reasonable — their instructions come first.":
        "多くの医療者が使う%@の目安を満たしていました — 最後の陣痛から%@。今、助産師さんや医師に連絡するのは妥当です — その指示が最優先です。",
    "That is closer together than the %@ guideline asks, before the hour it also asks for. Calling your provider now is reasonable — their instructions come first.":
        "%@の目安が求めるより間隔が短く、目安が求める1時間より前の段階です。今、助産師さんや医師に連絡するのは妥当です — その指示が最優先です。",
    "Your water breaks — note the time and the color of the fluid.":
        "破水したとき — 時刻と羊水の色を控えてください。",
    "Bleeding, more than spotting.": "出血が、少量のにじみを超えるとき。",
    "The baby is moving less than usual.": "赤ちゃんの動きがいつもより少ないとき。",
    "Regular contractions before 37 weeks.": "37週より前の規則的な張り。",
    "Anything that feels wrong to you.": "いつもと違うと感じること全般。",
    "None of these wait for a timer. Call your provider or labor and delivery directly.":
        "どれも計測を待つ必要はありません。助産師さん・医師・産院に直接連絡してください。",
    "Providers instruct differently — second babies, distance to the hospital, and your history all move this. If yours gave you a rule, set it here and follow theirs.":
        "医療者によって指示は違います — 二人目かどうか、産院までの距離、これまでの経過で変わります。あなたが受けた指示があれば、ここに設定してそちらに従ってください。",
    "Stays on this phone. Once it is set, a Call button appears beside the verdict on the timer and under the list below — so the call this app keeps recommending is one tap, not a search through Contacts at 3am.":
        "この端末に保存されます。設定すると、計測画面の判断の横と下の一覧に電話ボタンが表示されます — このアプリが勧める連絡が、午前3時に連絡先を探すことなく1タップになります。",
    "A soft pulse every 15 seconds while a contraction is timed":
        "陣痛の計測中、15秒ごとの静かな振動",
    "So the phone can sit face-down or in a pocket and still be trusted. Off unless you want it; quiet in Low Power Mode.":
        "端末を伏せたりポケットに入れたままでも頼れるように。必要なときだけオン、低電力モードでは動きません。",
    "Counted breaths under the timer — in for 4, out for 6":
        "計測の下に数える呼吸 — 4つ吸って、6つ吐く",
    "A slow cadence to breathe with while a contraction is timed. The glow keeps the same rhythm.":
        "陣痛の計測中に合わせて呼吸するゆっくりしたリズム。光も同じリズムで動きます。",
    "Every 5 minutes, lasting about a minute, for an hour — the widely used rule. Providers differ; the chip on the timer sets yours. When your pattern truly meets it, the app says so and suggests the call.":
        "5分ごと、1回およそ1分、1時間続く — 広く使われる目安です。医療者によって違います。計測画面のタグであなたの目安を設定します。本当に満たしたとき、アプリがそう伝え、連絡を勧めます。",
    "No account, no ads, no network. Everything stays on this phone, and Clear All History removes it whenever you choose.":
        "アカウントなし、広告なし、通信なし。すべてこの端末に残り、「履歴をすべて消去」でいつでも消せます。",
    "Drafts an email you can read and edit before sending. Your contraction times are never included.":
        "送信前に読んで編集できるメールを下書きします。陣痛の時刻が含まれることはありません。",
    "Free forever. No account. Works in airplane mode.": "ずっと無料。アカウント不要。機内モードでも動きます。",
    "Free forever · no account · works in airplane mode": "ずっと無料 · アカウント不要 · 機内モードでも動作",
    "Tap the bar when a contraction begins, tap it again when it ends. That's the whole job. Mis-taps get fixed in History — swipe to delete, and Undo takes back the last touch.":
        "陣痛が始まったらバーをタップ、終わったらもう一度タップ。それだけです。押し間違いは履歴で直せます — スワイプで削除、取り消しで直前の操作が戻ります。",
    "Tap the button when one starts — everything above builds from that one tap. The chip up top holds the guideline your provider gave you.":
        "始まったらボタンをタップ — 上の表示はすべてその1タップから組み立てられます。上のタグには、受け取った目安が入ります。",
    "Timing starts at the tap, and a tap comes a few seconds after the contraction does — so recorded lengths run a little behind the felt minute. The duration check allows for that; the figures on the timer stay exactly what was recorded.":
        "計測はタップから始まり、タップは陣痛の数秒あとになります — 記録される長さは体感より少し短めになります。長さの判定はそれを見込んでいます。画面の数字は記録されたそのままです。",
    "Newest at the top, the gap between each pair printed right where it happened. Figures stay dashes until there's enough to mean something — a dash is honest, a guess isn't.":
        "新しいものが上、間隔は起きた場所にそのまま表示されます。意味を持つだけの回数が集まるまで数字はダッシュのままです — ダッシュは正直で、推測はそうではありません。",
    "Timing runs on the clock, not the screen. Once a pattern is going, the button lives on the lock screen too — start and end without unlocking.":
        "計測は画面ではなく時計で進みます。一連が始まればロック画面にもボタンが出ます — ロックを解除せずに開始と終了ができます。",
    "Every contraction you time appears here with its duration and the interval since the one before.":
        "計測した陣痛は、長さと前回からの間隔とともにここに並びます。",
    "History has every contraction. The next tap starts a new stretch.":
        "履歴にはすべての陣痛が残ります。次のタップから新しい一連が始まります。",
    "A stopwatch with arithmetic. It measures contractions and reports the pattern against the guideline you chose. It does not diagnose labor, and it is not medical advice — your provider's instructions always come first. When unsure, call.":
        "計算のついたストップウォッチです。陣痛を計測し、選んだ目安に照らして間隔をお伝えします。陣痛の診断はせず、医療上の助言でもありません — 助産師さんや医師の指示が常に優先します。迷ったら連絡してください。",
    "Everything stays on this phone. No account, no analytics, nothing sent anywhere.":
        "すべてこの端末に残ります。アカウントなし、解析なし、どこにも送信しません。",
    "every %@ on average": "平均%@ごと",
    "every %@ on average (ranging %@–%@)": "平均%@ごと（%@〜%@）",
    "lasting about %@": "長さおよそ%@",
    "Hushlight problem report": "Hushlight 問題の報告",
    "Describe what happened above this line.": "この行より上に、起きたことをお書きください。",
    "— About this app and phone (you can delete any line) —":
        "— このアプリと端末について（どの行も削除できます） —",
    "App: Hushlight %@": "アプリ：Hushlight %@", "System: %@ · %@": "システム：%@ · %@",
    "Guideline: %@": "目安：%@", "Recorded: %@ across %@": "記録：%@／%@",
    "Live Activity on screen: %@": "ライブアクティビティ表示：%@",
    "yes": "あり", "no": "なし",
    "Your contraction times are not in this email. If a fix needs them, we will ask, and sending them stays your call.":
        "陣痛の時刻はこのメールに含まれていません。修正に必要な場合はこちらからお尋ねします。送るかどうかはあなたが決めます。",
    "Spacing that varies before it settles is how early stretches often look. A stretch timed now and then shows the same pattern — this doesn't need watching continuously.":
        "落ち着く前に間隔がばらつくのは、初期の一連によくある見え方です。ときどき計測しても同じ傾向は見えます — ずっと見張っている必要はありません。",
}

PLURALS = {
    "%lld contraction": {"other": "%lld回"},
    "%lld episode": {"other": "%lld件"},
    "%lld contraction in this stretch": {"other": "この一連で%lld回"},
    "%lld minutes": {"other": "%lld分"},
    "%lld seconds": {"other": "%lld秒"},
    "Still timing — over %lld minute usually means a missed end tap. Ending it now sets it aside from the averages.": {
        "other": "まだ計測中 — %lld分を超えるのは多くの場合、終了のタップが抜けています。ここで終了すると平均からは外れます。",
    },
}

SUBSTITUTIONS = {
    "%lld hours %lld minutes": {
        "value": "%1$#@hoursArg@%2$#@minutesArg@",
        "args": {"hoursArg": {"other": "%1$lld時間"}, "minutesArg": {"other": "%2$lld分"}},
    },
    "%lld minutes %lld seconds": {
        "value": "%1$#@minutesArg@%2$#@secondsArg@",
        "args": {"minutesArg": {"other": "%1$lld分"}, "secondsArg": {"other": "%2$lld秒"}},
    },
    "%@: contractions every %lld minute or closer, each lasting about a minute, sustained for an hour without a long break in it. The timer reads all three from your taps and says so when the pattern is there.": {
        "value": "%1$@：陣痛が%2$#@minutesArg@以下の間隔で、1回およそ1分、長い切れ目なく1時間続くこと。計測はあなたのタップから3つすべてを読み取り、そろったときにお伝えします。",
        "args": {"minutesArg": {"other": "%2$lld分"}},
    },
}

NEVER_SAYS = [
    "陣痛が始まりました",
    "お産が始まりました",
    "赤ちゃんが生まれます",
    "行く必要はありません",
    "行かなくて大丈夫",
    "しなければなりません",
    "病院へ行ってください",
    "産院へ行ってください",
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
        '（以前は%@）。',
    ' — %@ apart against %@ on %@.':
        ' — %@間隔（前回は%@、%@）。',
    '"Every 5 minutes" measures the gap between the beginnings of contractions — the way providers measure. Duration is how long each lasts; Pattern is how long this stretch has been going. Timing starts at the tap, so recorded lengths run a little behind the felt contraction.':
        '「5分ごと」は陣痛の始まりから次の始まりまでの間隔を指します — 医療者が測るのと同じ測り方です。長さは1回ごとに続く時間、継続はこの一連が続いている時間です。計測はタップした時点から始まるため、記録される長さは実際に感じた陣痛より少し短めになります。',
    '%@ before the next one':
        '次まで%@',
    '%@%@%@':
        '%@%@%@',
    '%@, %@.':
        '%@、%@。',
    '%@, met':
        '%@、達成',
    '%@, not yet':
        '%@、まだ',
    'A contraction is still being timed. This deletes it along with every other contraction on this phone. There is no undo.':
        '計測中の陣痛があります。この操作でその記録も、この端末にあるほかのすべての陣痛も削除されます。取り消しはできません。',
    'Averaging %@ apart — ':
        '平均%@間隔 — ',
    'Averaging every %@ over %lld timed contractions, for %@.':
        '計測した%2$lld回の陣痛で平均%1$@間隔、%3$@継続。',
    'Contraction %lld, lasted %@, at %@':
        '陣痛%lld、%@継続、%@',
    'Contraction %lld, running, %@':
        '陣痛%lld、計測中、%@',
    'Contractions %@ — %lld so far.':
        '陣痛 %@ — これまで%lld回。',
    'Crash reports kept on this phone: %lld · Hangs: %lld':
        '端末に残るクラッシュレポート：%lld · ハング：%lld',
    'Delete %lld Flagged':
        'マーク付き%lld件を削除',
    'Delete %lld Flagged…':
        'マーク付き%lld件を削除…',
    'Delete flagged records?':
        'マークの付いた記録を削除しますか？',
    'Guideline':
        '目安',
    'Last stretch, %@, %@':
        '直近の一連、%@、%@',
    'Last stretch, %@, %@ over %@':
        '直近の一連、%@、%@を%@で',
    'Last stretch, %@: %@':
        '直近の一連、%@：%@',
    'Last stretch, %@: %@ over %@':
        '直近の一連、%@：%@を%@で',
    'Not at %@ yet — averaging %@ apart and %@ long over %lld timed contractions.%@':
        'まだ%1$@ではありません — 計測した%4$lld回で平均%2$@間隔、長さ%3$@。%5$@',
    'Not at %@ yet — averaging %@ apart over %lld timed contractions; not enough finished ones yet to average their length.':
        'まだ%1$@ではありません — 計測した%3$lld回で平均%2$@間隔。長さの平均を出すには終了した回数がまだ足りません。',
    'Not at %@ yet. Averaging %@ apart and %@ long over %lld timed contractions.%@':
        'まだ%1$@ではありません。計測した%4$lld回で平均%2$@間隔、長さ%3$@。%5$@',
    'Not at %@ yet. Averaging %@ apart over %lld timed contractions. Not enough finished ones yet to average their length.':
        'まだ%1$@ではありません。計測した%3$lld回で平均%2$@間隔。長さの平均を出すには終了した回数がまだ足りません。',
    'Optional':
        '任意',
    'Start or stop a contraction':
        '陣痛の計測を開始または停止します',
    "The guideline's three legs, over the last hour":
        '目安の3つの条件、この1時間分',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        'CHECK が付いている記録です — 終了のタップが3分以上遅れたもの、または20秒未満のタップです。計測できた陣痛はそのまま残り、「取り消す」ですべて戻せます。',
    "These averages cover the whole stretch. The timer's own figures cover the last hour, so they can differ while contractions are getting closer together.":
        'これらの平均は一連の全体を対象としています。タイマー画面の数字はこの1時間を対象とするため、間隔が短くなっている間は数字が食い違うことがあります。',
    'Thirty seconds — and it waits under the question mark up top whenever you want it back.':
        '30秒で読めます — 見たくなったら上のはてなマークからいつでも開けます。',
    'This deletes every contraction on this phone. There is no undo.':
        'この端末にあるすべての陣痛の記録を削除します。取り消しはできません。',
    'This stretch is ':
        'この一連は',
    'This stretch is %@, %@ apart against %@ on %@.':
        'この一連は%@、%@間隔（前回は%@、%@）。',
    'This stretch: %@.':
        'この一連：%@。',
    'Timing this contraction — %lld in the last hour.':
        'この陣痛を計測中 — この1時間に%lld回。',
    'about the same as your last stretch':
        'ほぼ前回の一連と同じ',
    'closer together than your last stretch':
        '前回の一連より間隔が短い',
    'farther apart than your last stretch':
        '前回の一連より間隔が長い',
    'now':
        '現在',
    'one hour ago':
        '1時間前',
    'over %@':
        '%@で',
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
        '長さ%@',
    '%@ · FROM %@ · %lld':
        '%@ · %@から · %lld',
    '%lld H':
        '%lld時間',
    '%lld H %lld M':
        '%lld時間%lld分',
    '%lld M':
        '%lld分',
    'CHECK · OVER %lld MIN':
        '要確認 · %lld分超',
    'CHECK · UNDER %lld S':
        '要確認 · %lld秒未満',
    'OVER %@':
        '%@で',
    'THIS STRETCH · AVG %@ APART':
        'この一連 · 平均%@間隔',
    'These are the records already marked CHECK — a stop-tap missed by more than three minutes, or a tap under twenty seconds. Timed contractions are not touched, and Undo puts them all back.':
        '「要確認」が付いている記録です — 終了のタップが3分以上遅れたもの、または20秒未満のタップです。計測できた陣痛はそのまま残り、「取り消す」ですべて戻せます。',
})


# ---- HL-065 · Control Center, the Action button and Siri -------------------
# The control's label and gallery copy, and the intent's one reply for the case it
# refuses (it ran outside the app and so cannot record). "Recorded %@" and "Timing"
# were already here for Magic Tap; the intent now speaks the same words.
TRANSLATIONS.update({
    "Contraction": '陣痛',
    "Start or stop a contraction": '陣痛の計測を開始・終了',
    "One tap starts the timing; the next ends it.": '1回のタップで計測を開始し、次のタップで終了します。',
    "Open Hushlight to time this one.": 'この陣痛を計測するには Hushlight を開いてください。',
})
