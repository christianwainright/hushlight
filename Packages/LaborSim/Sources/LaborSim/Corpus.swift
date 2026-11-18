import Foundation

/// The corpus: which labors the harness runs, and the one function that turns a
/// committed seed into a full scenario.
///
/// Decision 0021 §5 keeps ~400 manifest JSONs out of the tree. What is committed is
/// this list of seed refs, a digest pin over it, and six golden manifests. Anything
/// else is re-derived, which is why `generate` must stay a pure function of its
/// argument — no clock, no environment, no global state.
public enum ScenarioCorpus {

    // MARK: - Composition

    /// The eight noise runs every sampled archetype/variant is measured under.
    ///
    /// `typicalSolo` and `exhaustedSolo` appear twice with different run indices:
    /// they are the two profiles that most resemble a real 3am thumb, and a single
    /// draw of a probabilistic noise model is an anecdote. `clean` is the impossible
    /// ideal, and it earns its place by isolating engine bugs from thumb bugs — a
    /// failure under `clean` cannot be blamed on the user.
    public static let noiseRuns: [(profile: NoiseProfileID, run: Int)] = [
        (.clean, 0),
        (.partnerDiligent, 0),
        (.typicalSolo, 0),
        (.typicalSolo, 1),
        (.exhaustedSolo, 0),
        (.exhaustedSolo, 1),
        (.chaotic, 0),
        (.clockHostile, 0)
    ]

    /// The default rule. 5-1-1 is what a first-time parent is most often handed.
    public static let defaultRule = "fiveOneOne"

    /// 12 sampled archetypes x 3 parameter variants x 8 noise runs = 288.
    public static let base: [ScenarioSeedRef] = {
        var refs: [ScenarioSeedRef] = []
        for archetype in ArchetypeID.sampled {
            for variant in 0..<3 {
                for run in noiseRuns {
                    refs.append(ScenarioSeedRef(
                        archetype: archetype, paramVariant: variant,
                        noiseProfile: run.profile, run: run.run, rule: defaultRule
                    ))
                }
            }
        }
        return refs
    }()

    /// The named variants: the flags that turn an archetype into its harder sibling.
    ///
    /// The three flagged archetypes run under every profile, because the flag
    /// changes the *body* and the question is whether any thumb can still record it.
    /// The `multiDayLatent` gap sweep instead runs one profile per variant — its
    /// point is the inter-bout gap straddling the 2 h episode boundary, and six
    /// copies of that under six profiles would be 36 scenarios asking one question.
    public static let variants: [ScenarioSeedRef] = {
        var refs: [ScenarioSeedRef] = []
        for archetype in [ArchetypeID.prodromalNightly, .pretermEarly, .inductionRamp] {
            for profile in NoiseProfileID.allCases {
                refs.append(ScenarioSeedRef(
                    archetype: archetype, paramVariant: 3,
                    noiseProfile: profile, run: 0, rule: defaultRule
                ))
            }
        }
        // Variants 3...8 are the fixed gaps 110/115/118/120/125/135 minutes; the
        // profiles are cycled so the sweep is not also a single-thumb sample.
        let profiles = NoiseProfileID.allCases
        for (offset, variant) in (3...8).enumerated() {
            refs.append(ScenarioSeedRef(
                archetype: .multiDayLatent, paramVariant: variant,
                noiseProfile: profiles[offset % profiles.count], run: 0, rule: defaultRule
            ))
        }
        return refs
    }()

    /// The same bodies judged against the stricter rules. Providers instruct
    /// differently, and a threshold that is only ever exercised at 300 s is a
    /// threshold whose other two settings are untested.
    public static let ruleCoverage: [ScenarioSeedRef] = {
        let stride = max(1, base.count / 30)
        let picks = (0..<30).map { base[($0 * stride) % base.count] }
        return picks.flatMap { ref in
            ["fourOneOne", "threeOneOne"].map { rule in
                ScenarioSeedRef(
                    archetype: ref.archetype, paramVariant: ref.paramVariant,
                    noiseProfile: ref.noiseProfile, run: ref.run, rule: rule
                )
            }
        }
    }()

    /// The hand-authored exact-arithmetic probes and the store-abuse scenarios,
    /// addressed positionally into `BoundaryBattery.all`.
    public static let battery: [ScenarioSeedRef] = {
        BoundaryBattery.all.indices.map { index in
            ScenarioSeedRef(
                archetype: .boundaryBattery, paramVariant: index,
                noiseProfile: .clean, run: 0, rule: BoundaryBattery.all[index].rule,
                seed: 0
            )
        }
    }()

    /// **The corpus.** Order is fixed and meaningful: the digest hashes it.
    public static let standard: [ScenarioSeedRef] = base + variants + ruleCoverage + battery

    /// A wider sweep for the occasional deep run, gated by the caller rather than by
    /// a constant here. Cheap to define and expensive to run, which is exactly why
    /// it is not the default.
    /// Six more parameter draws per archetype under the full noise matrix — roughly
    /// three times the standard corpus. Every archetype accepts any `paramVariant`
    /// (values past its named variants simply seed a different bracket draw), so
    /// this widens the *sampling* without inventing new labor shapes.
    public static let deep: [ScenarioSeedRef] = {
        var refs = standard
        for archetype in ArchetypeID.sampled {
            for variant in 9..<15 {
                for run in noiseRuns {
                    refs.append(ScenarioSeedRef(
                        archetype: archetype, paramVariant: variant,
                        noiseProfile: run.profile, run: run.run, rule: defaultRule
                    ))
                }
            }
        }
        return refs
    }()

    // MARK: - Generation

    /// **The entry point.** A seed ref in, a complete scenario out, deterministically.
    public static func generate(_ ref: ScenarioSeedRef) -> ScenarioManifest {
        if ref.archetype == .boundaryBattery {
            // Authored, not sampled: the battery's whole value is that its numbers
            // are exact literals rather than draws that landed near a boundary.
            let battery = BoundaryBattery.all
            let index = min(max(0, ref.paramVariant), battery.count - 1)
            var manifest = battery[index]
            // The battery numbers its two halves independently (probes 0-25,
            // adversarial 0-9), so the authored variant collides once the halves are
            // concatenated. The corpus addresses positionally into `all`, and this
            // makes the manifest agree with the ref that produced it. The authored
            // `id` is left alone — it names the case, and golden fixtures and
            // regression pins are filed under it.
            manifest.paramVariant = ref.paramVariant
            return manifest
        }

        // Two independent sub-streams. Physiology is drawn first and never sees the
        // noise profile, which is what makes the same true labor replay identically
        // under all six thumbs.
        var physiology = SeedDerivation.physiologyStream(ref.seed)
        let plan = Archetypes.plan(
            for: ref.archetype, paramVariant: ref.paramVariant, rng: &physiology
        )
        let body = Physiology.generateDetailed(plan: plan, rng: &physiology)

        var noise = SeedDerivation.noiseStream(
            ref.seed, profile: ref.noiseProfile.rawValue, run: ref.run
        )
        let actions = Noise.actions(
            trueStream: body.stream,
            profile: NoiseProfile.profile(ref.noiseProfile),
            rng: &noise
        )

        var truth = TruthCompiler.compile(
            trueStream: body.stream, rules: [ref.rule], fizzleTimes: body.fizzleTimes
        )
        // Derived from the replayed fold rather than from the noise model, so the
        // two can never drift apart: what the app should flag as suspect is a fact
        // about the record that reached it, not about the taps that were intended.
        truth.expectedSuspects = ReplayEngine.expectedSuspects(actions)

        return ScenarioManifest(
            id: ref.id,
            seed: ref.seed,
            archetype: ref.archetype.rawValue,
            paramVariant: ref.paramVariant,
            noiseProfile: ref.noiseProfile.rawValue,
            rule: ref.rule,
            ruleChanges: nil,
            pretermContext: Archetypes.pretermContext(for: ref.archetype),
            trueContractions: body.stream,
            actions: actions,
            truth: truth,
            expectedDetection: expectedDetection(for: ref, truth: truth),
            simulatorCheckpoint: checkpoint(for: ref, actions: actions)
        )
    }

    /// What this scenario is *for* — read by the report generator so a finding can
    /// say which pre-registered weakness caught it.
    static func expectedDetection(for ref: ScenarioSeedRef, truth: TruthTimeline) -> [String]? {
        var tags: [String] = ["archetype:\(ref.archetype.rawValue)", "noise:\(ref.noiseProfile.rawValue)"]
        if truth.zones.contains(where: { $0.kind == .mustFire }) { tags.append("onsetExpected") }
        if truth.events.contains(where: { $0.type == .neverQualifies }) { tags.append("falsePositiveProbe") }
        if truth.events.contains(where: { $0.type == .fizzle }) { tags.append("fizzle") }
        if truth.episodesTrue.count > 1 { tags.append("multiEpisode") }
        if !truth.expectedSuspects.isEmpty { tags.append("suspectExpected") }
        if ref.noiseProfile == .clockHostile { tags.append("clockHostile") }
        return tags
    }

    /// Only a sampled few scenarios get promoted to the simulator pass, so only
    /// those carry a checkpoint. Seeding through the second-to-last action leaves a
    /// live tail for a real-time interaction script.
    static func checkpoint(for ref: ScenarioSeedRef, actions: [ScenarioAction]) -> SimCheckpoint? {
        guard actions.count > 4, ref.paramVariant == 0, ref.run == 0 else { return nil }
        guard ref.noiseProfile == .typicalSolo || ref.noiseProfile == .clean else { return nil }
        return SimCheckpoint(seedThroughAction: actions.count - 2, liveTailSeconds: 240)
    }

    // MARK: - Digest

    /// The corpus's content hash input: every ref, canonically encoded, in order.
    ///
    /// Hashing the *refs* rather than the generated manifests is deliberate. The
    /// golden fixtures pin what generation produces; this pins which scenarios are
    /// asked for. Conflating them would make adding a scenario and changing the
    /// physiology model look like the same event, and decision 0021 §5 needs them
    /// to be different ones — one bumps minor, the other bumps major.
    public static func digestInput(_ refs: [ScenarioSeedRef] = standard) throws -> Data {
        try CanonicalJSON.data(refs)
    }
}
