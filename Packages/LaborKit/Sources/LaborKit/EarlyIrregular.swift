import Foundation

/// SP-209, decision 0041: naming the irregular early stretch, and licensing rest.
///
/// The irregular state used to print its spread and stop, and the silence read as
/// something going wrong — the long-haul failure being a woman who takes variance
/// for trouble, times every contraction for eight hours, and arrives exhausted.
/// This type owns both halves of the fix: the predicate deciding when the line may
/// appear, and the line itself — here in LaborKit rather than the screen, for the
/// same reason `Disclaimers` lives here (SP-080): copy this close to the
/// medical-claims boundary is pinned by a package test, so a future rewrite is a
/// deliberate act and not a drive-by.
public enum EarlyIrregular {
    /// Both bounds are 1.5×, both relational (decision 0041 §Rationale): the
    /// motivating spread — 7:00–12:00 against 5-1-1 — must fire (ratio 1.71,
    /// average well past 7:30), and a barely-uneven pattern hovering *near* the
    /// threshold must not, because there variance is the story tightening and a
    /// rest note would be the opposite error. Integer 3/2 arithmetic, no Doubles,
    /// the same discipline as the share constants these sit beside in spirit.
    public static let wideSpreadNumerator = 3
    public static let wideSpreadDenominator = 2
    public static let wellAboveNumerator = 3
    public static let wellAboveDenominator = 2

    /// The sentence, appended to the partial line. Every word is about *timing
    /// data*, not her body: "how early stretches often look" observes stretches of
    /// timing, and the rest licence is a fact about measurement — an intermittent
    /// sample of a slow, irregular pattern shows the same slow, irregular pattern.
    /// The three ways this sentence goes wrong (0041 §2): prognosis, instruction,
    /// outcome reassurance. It contains none.
    public static var line: String {
        // A single string literal, not `+`-concatenated pieces: `String.LocalizationValue`
        // is `ExpressibleByStringLiteral`/`ExpressibleByStringInterpolation`, not
        // summable, so the sentence has to be one literal for `String(localized:)` to
        // accept it. Backslash line-continuation keeps it wrapped without an embedded
        // newline, matching the source text `EarlyIrregularTests` pins verbatim.
        String(
            localized: """
                Spacing that varies before it settles is how early stretches often look. \
                A stretch timed now and then shows the same pattern — this doesn't need \
                watching continuously.
                """,
            bundle: .module,
            comment: "sentence appended to the partial-pattern line when the stretch is wide and slow (decision 0041) — every word is about timing data, not her body; must never read as prognosis, instruction, or outcome reassurance"
        )
    }

    /// Fires only in the partial state — the caller owns that gate (never over a
    /// met, held, or fast-met banner) — when the evidence floor is met and the
    /// pattern is both wide and slow against the chosen rule.
    public static func applies(
        intervalRange: ClosedRange<Duration>?,
        averageInterval: Duration?,
        rule: GuidelineRule
    ) -> Bool {
        guard let range = intervalRange, let average = averageInterval else {
            return false
        }
        let lower = range.lowerBound.components.seconds
        let upper = range.upperBound.components.seconds
        let mean = average.components.seconds
        let threshold = rule.intervalThreshold.components.seconds
        // Wide: upper ≥ 1.5 × lower. A degenerate lower bound of zero (a clock
        // artifact the engine clamps upstream) would make any spread "wide";
        // requiring a positive lower keeps the ratio meaningful.
        guard lower > 0, upper * Int64(wideSpreadDenominator) >= lower * Int64(wideSpreadNumerator) else {
            return false
        }
        // Well above: average ≥ 1.5 × the rule's threshold.
        return mean * Int64(wellAboveDenominator) >= threshold * Int64(wellAboveNumerator)
    }
}
