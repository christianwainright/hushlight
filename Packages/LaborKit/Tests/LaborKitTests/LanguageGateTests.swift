import Foundation
import Testing
@testable import LaborKit

/// HL-008's flag, enforced (see `VerifiedLanguages`): no String Catalog in this
/// repository may carry a translation of a load-bearing medical surface in a
/// language HD-4's verifier has not signed for. The gate reads the catalogs as
/// files — the same JSON the build compiles — so an unverified translation fails
/// here the commit it appears, not the release someone notices.
@Suite("The language gate")
struct LanguageGateTests {
    /// Every catalog in the repo, located from this file's own position so the test
    /// needs no bundle plumbing and cannot silently miss one.
    private static var catalogPaths: [URL] {
        // …/Packages/LaborKit/Tests/LaborKitTests/LanguageGateTests.swift, four
        // components up → …/Packages — the app targets sit beside it.
        let packages = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        return [
            packages.appendingPathComponent("../Hushlight/Localizable.xcstrings"),
            packages.appendingPathComponent("../HushlightWidgets/Localizable.xcstrings"),
            packages.appendingPathComponent("LaborKit/Sources/LaborKit/Resources/Localizable.xcstrings"),
        ].map { $0.standardizedFileURL }
    }

    @Test func everyCatalogIsFoundWhereThisTestExpectsIt() throws {
        for url in Self.catalogPaths {
            #expect(FileManager.default.fileExists(atPath: url.path),
                    "catalog missing at \(url.path) — the gate below is only as good as this list")
        }
    }

    /// The gate itself. A load-bearing key with a localization entry for any
    /// language outside `VerifiedLanguages.verified` is a build-breaking defect:
    /// "behind the flag" means *absent*, because absence is the only state a
    /// pipeline cannot accidentally ship.
    @Test func noLoadBearingSurfaceIsTranslatedBeyondTheVerifiedList() throws {
        for url in Self.catalogPaths where FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let strings = json?["strings"] as? [String: Any] ?? [:]
            for (key, entry) in strings {
                guard VerifiedLanguages.loadBearingKeyFragments.contains(where: key.contains),
                      let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
                else { continue }
                for language in localizations.keys {
                    #expect(
                        VerifiedLanguages.verified.contains(language),
                        """
                        \(url.lastPathComponent) carries '\(language)' for a \
                        load-bearing surface ('\(key.prefix(40))…') that HD-4's \
                        verifier has not signed for. Add the language to \
                        VerifiedLanguages.verified — with its neverSays list, in \
                        the verifier's own commit — or remove the translation.
                        """
                    )
                }
            }
        }
    }

    /// The gate's own tether: every load-bearing fragment must match at least one
    /// key in some catalog, or the gate has silently come loose from the surface
    /// it guards — a reworded sentence would otherwise pass this suite green
    /// forever while protecting nothing, the exact failure absence-as-flag was
    /// chosen to prevent. A rewording that trips this test moves the fragment in
    /// the same edit, deliberately.
    @Test func everyLoadBearingFragmentGuardsAtLeastOneKey() throws {
        var allKeys: [String] = []
        for url in Self.catalogPaths where FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            allKeys.append(contentsOf: (json?["strings"] as? [String: Any] ?? [:]).keys)
        }
        for fragment in VerifiedLanguages.loadBearingKeyFragments {
            #expect(allKeys.contains(where: { $0.contains(fragment) }),
                    "fragment '\(fragment.prefix(40))…' matches no catalog key — the gate is guarding nothing for this surface")
        }
    }

    /// Half a signature fails: every verified language carries its own voice
    /// fixture, because T0-14 tests shipped copy and a language without banned
    /// phrases is a language whose copy nothing is testing.
    @Test func everyVerifiedLanguageCarriesItsOwnNeverSaysList() {
        for language in VerifiedLanguages.verified {
            let list = VerifiedLanguages.neverSaysByLanguage[language]
            #expect(list?.isEmpty == false,
                    "'\(language)' is verified but has no neverSays list — verification without the voice fixture is half a signature")
        }
    }

    /// The gate's own floor: English stays verified (it is the test-pinned source
    /// language), and its fixture stays the original.
    @Test func englishIsTheVerifiedFloor() {
        #expect(VerifiedLanguages.verified.contains("en"))
        #expect(VerifiedLanguages.neverSaysByLanguage["en"] == Disclaimers.neverSays)
    }
}
