import CryptoKit
import Foundation
import LaborKit
import Testing
@testable import LaborSim

/// The corpus is committed as seeds, not as manifests (decision 0021 §5). That
/// trade buys a reviewable diff and costs a guarantee — nothing in a pull request
/// visibly shows that the set of scenarios changed. This suite is that guarantee:
/// one pinned hash over the whole ordered corpus, so adding, removing, or
/// reordering a scenario turns a test red and forces the manifest's semver to move
/// with it.
@Suite("Corpus stability")
struct CorpusStabilityTests {

    /// SHA-256 over the canonical encoding of every seed ref, in corpus order.
    static func digest(_ refs: [ScenarioSeedRef]) throws -> String {
        let data = try ScenarioCorpus.digestInput(refs)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// **The pin.** Re-derived only when the corpus is deliberately changed, and
    /// that change belongs in the same commit as a `docs/qa/corpus/manifest.json`
    /// version bump: adding scenarios is a minor, altering an existing one is a
    /// major, because reports are only row-comparable within a version.
    static let pinnedDigest = "543484e58534fff367c8580dfdfa0ed500cb7f737bbf6a611ff872515f41fa39"

    @Test func theCorpusMatchesItsPinnedDigest() throws {
        // The message prints the computed value on failure so a deliberate corpus
        // bump can read its new pin from the test output instead of instrumenting
        // this file to find it — which is exactly how 3.1.0's was derived.
        let computed = try Self.digest(ScenarioCorpus.standard)
        #expect(computed == Self.pinnedDigest, "computed digest: \(computed)")
    }

    /// A digest over an empty or truncated corpus would still be stable, and still
    /// be worthless.
    ///
    /// Corpus 2.0.0 (F-0024, F-0011's corpus half): five new boundary-battery
    /// cases — 31 probes + 10 adversarial = 41 — took the battery from 36 to 41
    /// and the standard corpus from 408 to 413.
    /// Corpus 3.1.0 (SP-207 / F-0037): `fastFromTheFirstContraction` — the
    /// tight-from-onset shape decision 0040 was written for, which the sampled
    /// precipitous archetype never produces — takes the battery to 42 and the
    /// corpus to 414. The literal totals are pinned here as well as via
    /// `BoundaryBattery.all.count`, so a silent battery-size drift fails a
    /// readable assertion and not only the opaque content digest below.
    @Test func theCorpusIsTheSizeTheMatrixSaysItIs() {
        #expect(ScenarioCorpus.base.count == 288)      // 12 archetypes x 3 variants x 8 runs
        #expect(ScenarioCorpus.variants.count == 24)   // 3 flagged x 6 profiles, + 6 gap sweep
        #expect(ScenarioCorpus.ruleCoverage.count == 60)  // 30 scenarios x 2 stricter rules
        #expect(BoundaryBattery.all.count == 42)       // 32 boundary probes + 10 adversarial
        #expect(ScenarioCorpus.battery.count == BoundaryBattery.all.count)
        #expect(ScenarioCorpus.standard.count
            == 288 + 24 + 60 + BoundaryBattery.all.count)
        #expect(ScenarioCorpus.standard.count == 414)
        #expect(ScenarioCorpus.standard.count >= 400)
    }

    /// Every sampled archetype is measured equally. An archetype quietly dropping to
    /// half the runs would still hash stably and still leave a labor shape thin.
    @Test func everySampledArchetypeGetsTheFullNoiseMatrix() {
        for archetype in ArchetypeID.sampled {
            let count = ScenarioCorpus.base.filter { $0.archetype == archetype }.count
            #expect(count == 24, "\(archetype.rawValue) has \(count) base scenarios")
        }
        #expect(!ScenarioCorpus.base.contains { $0.archetype == .boundaryBattery })
    }

    @Test func everyNoiseProfileIsExercisedAcrossTheBase() {
        for profile in NoiseProfileID.allCases {
            let count = ScenarioCorpus.base.filter { $0.noiseProfile == profile }.count
            #expect(count > 0, "\(profile.rawValue) never appears")
        }
        // The two realistic thumbs are sampled twice; a single draw of a
        // probabilistic model is an anecdote.
        #expect(ScenarioCorpus.base.filter { $0.noiseProfile == .typicalSolo }.count == 72)
        #expect(ScenarioCorpus.base.filter { $0.noiseProfile == .exhaustedSolo }.count == 72)
        #expect(ScenarioCorpus.base.filter { $0.noiseProfile == .clean }.count == 36)
    }

    /// All three rule settings get exercised; a threshold only ever probed at 300 s
    /// leaves its other two settings untested.
    @Test func allThreeRulesAppearInTheCorpus() {
        let rules = Set(ScenarioCorpus.standard.map(\.rule))
        #expect(rules.isSuperset(of: ["fiveOneOne", "fourOneOne", "threeOneOne"]))
        #expect(ScenarioCorpus.ruleCoverage.filter { $0.rule == "fourOneOne" }.count == 30)
        #expect(ScenarioCorpus.ruleCoverage.filter { $0.rule == "threeOneOne" }.count == 30)
    }

    /// Ids name result files and golden fixtures. A collision would have one
    /// scenario silently overwrite another's results.
    @Test func everyScenarioIdIsUnique() {
        let ids = ScenarioCorpus.standard.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyScenarioLabelIsUnique() {
        let labels = ScenarioCorpus.standard.map(\.label)
        #expect(Set(labels).count == labels.count)
    }

    /// The gap sweep must actually straddle the two-hour episode boundary — the
    /// whole reason `multiDayLatent` carries six extra variants.
    @Test func theGapSweepCoversBothSidesOfTheEpisodeBoundary() {
        let sweep = ScenarioCorpus.variants.filter { $0.archetype == .multiDayLatent }
        #expect(sweep.count == 6)
        #expect(Set(sweep.map(\.paramVariant)) == Set(3...8))
    }

    /// Generation is a pure function of its ref. If it were not, every other
    /// guarantee in this package — golden fixtures, regression pins, row-comparable
    /// reports — would be built on sand.
    @Test func generationIsReproducible() throws {
        let stride = max(1, ScenarioCorpus.standard.count / 25)
        for index in Swift.stride(from: 0, to: ScenarioCorpus.standard.count, by: stride) {
            let ref = ScenarioCorpus.standard[index]
            let first = ScenarioCorpus.generate(ref)
            let second = ScenarioCorpus.generate(ref)
            #expect(first == second, "\(ref.label) is not reproducible")
        }
    }

    /// The independence guarantee, end to end: the same body under a different
    /// thumb. If a noise-profile change perturbed the physiology stream, the six
    /// profiles would stop being measurements of one labor and every cross-profile
    /// comparison in the report would be meaningless.
    @Test func changingTheNoiseProfileLeavesTheTrueStreamIdentical() {
        for archetype in ArchetypeID.sampled {
            let quiet = ScenarioCorpus.generate(ScenarioSeedRef(
                archetype: archetype, paramVariant: 0, noiseProfile: .clean, rule: "fiveOneOne"
            ))
            for profile in NoiseProfileID.allCases where profile != .clean {
                let loud = ScenarioCorpus.generate(ScenarioSeedRef(
                    archetype: archetype, paramVariant: 0, noiseProfile: profile, rule: "fiveOneOne"
                ))
                #expect(quiet.trueContractions == loud.trueContractions,
                        "\(archetype.rawValue) body moved under \(profile.rawValue)")
            }
        }
    }

    /// Likewise the rule: it changes what is *asked* of the record, never what the
    /// body did.
    @Test func changingTheRuleLeavesTheTrueStreamIdentical() {
        for archetype in ArchetypeID.sampled.prefix(6) {
            let base = ScenarioCorpus.generate(ScenarioSeedRef(
                archetype: archetype, paramVariant: 1, noiseProfile: .typicalSolo, rule: "fiveOneOne"
            ))
            let strict = ScenarioCorpus.generate(ScenarioSeedRef(
                archetype: archetype, paramVariant: 1, noiseProfile: .typicalSolo, rule: "threeOneOne"
            ))
            #expect(base.trueContractions == strict.trueContractions)
            #expect(base.actions == strict.actions)
        }
    }

    /// True physiology must never manufacture a suspect record. Every suspect in
    /// the corpus is provably the noise model's work or the battery's — which is
    /// what lets a suspect finding be attributed to a cause.
    @Test func noSampledBodyEverProducesASuspectContraction() {
        for ref in ScenarioCorpus.base {
            let manifest = ScenarioCorpus.generate(ref)
            for contraction in manifest.trueContractions {
                #expect(contraction.durationSeconds <= 180,
                        "\(ref.label) produced a \(contraction.durationSeconds)s true contraction")
            }
        }
    }

    /// Whole seconds throughout, and never a contraction that ends before it starts.
    @Test func everyGeneratedTimeIsAWholeSecondAndOrdered() {
        let stride = max(1, ScenarioCorpus.standard.count / 40)
        for index in Swift.stride(from: 0, to: ScenarioCorpus.standard.count, by: stride) {
            let manifest = ScenarioCorpus.generate(ScenarioCorpus.standard[index])
            for contraction in manifest.trueContractions {
                #expect(contraction.end > contraction.start)
            }
            let starts = manifest.trueContractions.map(\.start)
            #expect(starts == starts.sorted(), "\(manifest.id) emitted out of order")
            #expect(manifest.t0 == laborSimEpoch)
        }
    }

    /// A corpus of empty scenarios would hash stably and prove nothing.
    @Test func scenariosActuallyContainLabor() {
        for ref in ScenarioCorpus.base.prefix(40) {
            let manifest = ScenarioCorpus.generate(ref)
            #expect(manifest.trueContractions.count >= 5, "\(ref.label) is nearly empty")
            #expect(!manifest.actions.isEmpty)
        }
    }

    /// **The starvation guard**, and the reason it exists.
    ///
    /// The first run of this corpus produced 39 base scenarios in which the noise
    /// model recorded *nothing at all* — a sleep pause sampled at 1–4 h laid over a
    /// 1–2 h precipitous labor covered the entire stream. Every short archetype
    /// under `exhaustedSolo` and `chaotic` had silently become an empty test, and
    /// nothing in the suite noticed, because an empty scenario passes every
    /// assertion ever written about it.
    ///
    /// A pause is now capped as a fraction of the span it interrupts. This test is
    /// what keeps it that way: coverage that is only checked once is coverage that
    /// erodes.
    @Test func noScenarioIsStarvedOfTaps() {
        var starved: [String] = []
        for ref in ScenarioCorpus.base {
            let manifest = ScenarioCorpus.generate(ref)
            let starts = manifest.actions.count { if case .tapStart = $0 { true } else { false } }
            let recorded = Double(starts) / Double(max(1, manifest.trueContractions.count))
            if recorded < 0.3 {
                starved.append("\(ref.label) recorded \(starts)/\(manifest.trueContractions.count)")
            }
        }
        #expect(starved.isEmpty, "starved scenarios: \(starved.prefix(10).joined(separator: "; "))")
    }

    /// Even the worst thumb has to leave the engine something to be wrong about.
    @Test func everyProfileRecordsMostOfALongLabor() {
        for profile in NoiseProfileID.allCases {
            let ref = ScenarioSeedRef(
                archetype: .classicNullipara, paramVariant: 0,
                noiseProfile: profile, run: 0, rule: "fiveOneOne"
            )
            let manifest = ScenarioCorpus.generate(ref)
            let starts = manifest.actions.count { if case .tapStart = $0 { true } else { false } }
            #expect(starts >= 20, "\(profile.rawValue) recorded only \(starts) starts")
        }
    }

    /// **F-0025.** The ramp's own floor never bit — its tail sits at a 180 s mean,
    /// comfortably above a 95-110 s floor even at 2.5-sigma — so the tachysystole
    /// variant produced only 8 true contractions, and the promoted "densest
    /// timeline" gallery shot showed two rows against a caption promising four and
    /// two-digit ordinals. The fix appends a second segment that holds floor
    /// spacing for the better part of an hour; this is the corpus-side count that
    /// proves it actually sustains a dense run.
    @Test func theTachysystoleVariantSustainsADenseRun() {
        let ref = ScenarioSeedRef(
            archetype: .inductionRamp, paramVariant: 3,
            noiseProfile: .clean, rule: "fiveOneOne"
        )
        let manifest = ScenarioCorpus.generate(ref)
        #expect(manifest.trueContractions.count >= 30,
                "tachysystole variant produced only \(manifest.trueContractions.count) true contractions")
    }

    /// **F-0011's corpus half, proven directly.** Nothing in the coupled-probe
    /// sweep (`ReplayEngine.probeTimes` feeding both the fold cutoff and `now`) can
    /// ask for a `now` earlier than every record it has folded in — `episodeStart
    /// <= probe` holds by construction there, on any scenario. So this decouples
    /// the two by hand: fold `timezoneCorrectionBeforeEpisodeStart` in full (the
    /// clockSet adds no record, per `advClockBackMidContraction`'s own contract),
    /// then ask for the pattern at the `now` a live `Date()` read would have shown
    /// right after the clock jump — two hours before `episodeStart`, exactly the
    /// shape F-0011's clamp exists for.
    @Test func theClockBacksetScenarioClampsRatherThanGoesNegative() throws {
        let manifest = try #require(BoundaryBattery.manifests().first {
            $0.id == "boundaryBattery-timezoneCorrectionBeforeEpisodeStart"
        })
        let records = ReplayEngine.sorted(ReplayEngine.fold(manifest.actions))
        #expect(records.map(\.start).min() == 0, "setup: episodeStart should be untouched by the clockSet")

        let contractions = HarnessBridge.contractions(records, t0: manifest.t0)
        let now = HarnessBridge.date(manifest.t0, 3600 - 10_800)   // the instant right after the clockSet
        let pattern = PatternAnalysis.pattern(
            for: contractions, rule: HarnessBridge.rule(manifest.rule), now: now
        )
        let length = try #require(pattern.patternLength,
                                   "setup: the episode should still be live, not stale or empty, at this now")
        #expect(length == .zero,
                "F-0011: patternLength should clamp to zero when now precedes episodeStart, read \(length)")
    }
}
