import Foundation

/// HL-008's flag, built before any translation exists so no translation can ever
/// precede it: **a language with an unverified medical surface does not ship** —
/// and here, "does not ship" is a failing test, not a policy.
///
/// HD-4 (open, human) decides who verifies each language's medical copy. Until a
/// language's four load-bearing surfaces — the measured-not-diagnosed disclaimer,
/// the call-now-regardless card, the verdict banner, and the partial line — have
/// had that verified read, its code may not appear in `verified`, and
/// `LanguageGateTests` fails the build if any String Catalog carries a translation
/// for a load-bearing key in a language this list does not name. The gate is
/// deliberately on the *repository*, not the runtime: an unverified translation of
/// the disclaimer is not a dormant asset waiting for a flag flip, it is a defect
/// the moment it is committed, because nothing in a build pipeline distinguishes
/// "present but unblessed" from "shippable" as reliably as absence does.
///
/// The per-language `neverSays` lists live here too, beside the gate that makes
/// them meaningful: T0-14 greps *shipped* copy, so each language tests against the
/// phrases a frightened reader must never meet in that language's own idiom — a
/// translation judgement (HD-4's verifier makes it), never a find-and-replace from
/// the English list.
public enum VerifiedLanguages {
    /// Language codes whose medical surfaces have had the verified human read HD-4
    /// requires. English is the source language, verified by construction — every
    /// en sentence is test-pinned and voice-tested in this repo.
    ///
    /// **Adding a code here is HD-4's verifier signing their name.** The entry must
    /// arrive in the same commit as the language's translations and its own
    /// `neverSays` list below, and the backlog's HL-008 note records who verified.
    /// **`es` added 2026-09-05 on Christian's acceptance, and the record should say
    /// exactly what that means.** HD-4 asked who verifies each language's medical
    /// copy. The answer he gave is: the agent translates, and he accepts that
    /// translation as the verified read — no separate native reviewer. That is his
    /// call to make and decision 0061 records it, including the residual risk, so
    /// nobody later reads this set as "a native speaker signed for these".
    public static let verified: Set<String> = ["en", "es", "fr", "de", "it", "pt-BR", "ja", "ko", "zh-Hans"]

    /// The catalog keys of the four load-bearing medical surfaces — the ones whose
    /// mistranslation is the one bug in this app that can reach a person. Kept as
    /// key prefixes because HL-007's format strings carry positional markers.
    /// `LanguageGateTests` resolves these against every catalog.
    // lint-localizable:ignore-start — key fixtures for the language gate, not shipped copy
    public static let loadBearingKeyFragments = [
        "A stopwatch with arithmetic",
        "Everything stays on this phone",
        "That meets the %@ guideline many providers use",
        "That is closer together than the %@ guideline asks",
        "None of these wait for a timer",
    ]
    // lint-localizable:ignore-end

    /// Per-language banned phrases for T0-14. English's list is `Disclaimers
    /// .neverSays`, the original; each verified language adds its own list in the
    /// same commit that verifies it. A verified language with no list here is a
    /// gate failure — verification without the voice fixture is half a signature.
    public static let neverSaysByLanguage: [String: [String]] = [
        "en": Disclaimers.neverSays,

        // Spanish is cut for the idiom, not translated from the English list — which
        // is what the note above means by a translation judgement. Two of these have
        // no English counterpart because the risk is Spanish-shaped:
        //
        //   * `ya viene el bebé` — "the baby is coming" is the sentence a frightened
        //     reader most wants to hear and the one this app has no standing to say.
        //     English never phrases the temptation that way; Spanish does.
        //   * `estás en trabajo de parto` — the clinical register in much of Latin
        //     America, where `estás de parto` is the everyday one. Banning only the
        //     colloquial form would leave the phrase that sounds most like a diagnosis.
        //
        // The rest map the English intents: a diagnosis claim, a dismissal, an
        // obligation, and a directive to travel.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "es": [
            "estás de parto",
            "estás en trabajo de parto",
            "ya viene el bebé",
            "no necesitas ir",
            "no hace falta ir",
            "tienes que",
            "debes ir",
            "ve al hospital",
            "vete al hospital",
        ],
        // lint-localizable:ignore-end

        // French: a diagnosis claim, the baby-is-coming prediction, a dismissal, an obligation, and two directives to travel — the maternité and the hospital are separate destinations in French and both must be banned.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "fr": [
            "vous êtes en travail",
            "le travail a commencé",
            "le bébé arrive",
            "vous n’avez pas besoin d’aller",
            "inutile d’aller",
            "vous devez",
            "allez à la maternité",
            "allez à l’hôpital",
        ],
        // lint-localizable:ignore-end

        // German: the diagnosis claim in both its everyday and clinical shapes, the baby-is-coming prediction, a dismissal, an obligation, and two directives to travel.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "de": [
            "du bist in den wehen",
            "die geburt hat begonnen",
            "das baby kommt",
            "du musst nicht",
            "du musst",
            "fahr ins krankenhaus",
            "geh ins krankenhaus",
        ],
        // lint-localizable:ignore-end

        // Italian: the diagnosis claim in both shapes, the baby-is-coming prediction, two dismissals, an obligation, and a directive to travel.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "it": [
            "sei in travaglio",
            "il travaglio è iniziato",
            "il bambino sta arrivando",
            "non hai bisogno di andare",
            "non serve andare",
            "devi andare",
            "vai in ospedale",
        ],
        // lint-localizable:ignore-end

        // Brazilian Portuguese: the diagnosis claim in both shapes, the baby-is-coming prediction, two dismissals, an obligation, and two directives to travel — maternidade and hospital are separate destinations.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "pt-BR": [
            "você está em trabalho de parto",
            "o trabalho de parto começou",
            "o bebê está chegando",
            "não precisa ir",
            "não é necessário ir",
            "você tem que",
            "vá para a maternidade",
            "vá para o hospital",
        ],
        // lint-localizable:ignore-end

        // Japanese: the diagnosis claim in both its 陣痛/お産 shapes, the baby-is-coming prediction, two dismissals, an obligation, and two directives to travel.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "ja": [
            "陣痛が始まりました",
            "お産が始まりました",
            "赤ちゃんが生まれます",
            "行く必要はありません",
            "行かなくて大丈夫",
            "しなければなりません",
            "病院へ行ってください",
            "産院へ行ってください",
        ],
        // lint-localizable:ignore-end

        // Korean: the diagnosis claim in both 진통/분만 shapes, the baby-is-coming prediction, two dismissals, an obligation, and two directives to travel.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "ko": [
            "진통이 시작되었습니다",
            "분만이 시작되었습니다",
            "아기가 나옵니다",
            "갈 필요 없습니다",
            "가지 않아도 됩니다",
            "해야 합니다",
            "병원으로 가세요",
            "분만실로 가세요",
        ],
        // lint-localizable:ignore-end

        // Simplified Chinese: the diagnosis claim in its 临产/分娩 shapes, the colloquial 要生了 that a frightened reader most wants to hear, two dismissals, an obligation, and a directive to travel.
        // lint-localizable:ignore-start — voice-rule fixture (T0-14), not shipped copy
        "zh-Hans": [
            "你已经临产",
            "分娩开始了",
            "宝宝要出来了",
            "要生了",
            "不需要去",
            "不用去",
            "你必须",
            "去医院",
        ],
        // lint-localizable:ignore-end
    ]
}
