import Foundation
import SwiftData
import Testing
@testable import LaborKit

/// The one decision behind SP-200's Call button: what counts as a number worth
/// offering to dial. A false positive here puts a button on screen that dials
/// nothing at the moment it matters most; a false negative hides the button from
/// someone who typed a perfectly good number with parentheses in it.
@Suite("Provider contact")
struct ProviderContactTests {
    @Test("Formatting characters are presentation, not digits", arguments: [
        "(555) 123-4567",
        "555.123.4567",
        "555 123 4567",
        "555-123-4567",
    ])
    func punctuationIsStripped(_ entry: String) throws {
        let url = try #require(ProviderContact.telURL(for: entry))
        #expect(url.absoluteString == "tel:5551234567")
    }

    @Test func leadingPlusSurvives() throws {
        let url = try #require(ProviderContact.telURL(for: "+1 (555) 123-4567"))
        #expect(url.absoluteString == "tel:+15551234567")
    }

    /// A `+` in the middle is someone's note, not an international prefix, and
    /// `tel:` has no meaning for it.
    @Test func aPlusAnywhereElseIsDropped() throws {
        let url = try #require(ProviderContact.telURL(for: "555+1234"))
        #expect(url.absoluteString == "tel:5551234")
    }

    /// Extensions and menu keys are the reason a dial string is not just digits:
    /// L&D lines routinely sit behind a hospital switchboard.
    @Test func pausesAndMenuKeysSurvive() throws {
        let url = try #require(ProviderContact.telURL(for: "555-1234,,102"))
        #expect(url.absoluteString == "tel:5551234,,102")
    }

    /// `#` is `URL`'s fragment delimiter, so an unencoded one would silently throw
    /// away everything after it — the failure mode being a call placed to half a
    /// number.
    @Test func hashIsEncodedRatherThanTruncatingTheNumber() throws {
        let url = try #require(ProviderContact.telURL(for: "5551234#5"))
        #expect(url.absoluteString == "tel:5551234%235")
    }

    @Test("Nothing dialable means no URL, and so no button", arguments: [
        "",
        "   ",
        "+",
        "()-",
        "ext",
        "12",
    ])
    func belowTheFloorThereIsNoURL(_ entry: String) {
        #expect(ProviderContact.telURL(for: entry) == nil)
    }

    @Test func theFloorIsThreeDigits() throws {
        #expect(ProviderContact.minimumDigits == 3)
        #expect(ProviderContact.telURL(for: "12") == nil)
        let url = try #require(ProviderContact.telURL(for: "123"))
        #expect(url.absoluteString == "tel:123")
    }

    // MARK: Persistence

    @Test func anUnsetNumberReadsAsEmpty() throws {
        let suite = "net.wainright.laborkit.providerUnset"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(ProviderContact.persisted(in: defaults).isEmpty)
    }

    @Test @MainActor func theModelPersistsAndOffersTheNumber() throws {
        let suite = "net.wainright.laborkit.providerPersisted"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = LaborModel(
            context: ModelContext(try LaborStore.container(inMemory: true)),
            defaults: defaults
        )
        #expect(model.providerNumber.isEmpty)
        #expect(model.providerCallURL == nil, "no number set means no Call button anywhere")

        model.providerNumber = "(555) 123-4567"
        #expect(defaults.string(forKey: ProviderContact.defaultsKey) == "(555) 123-4567")
        #expect(model.providerCallURL?.absoluteString == "tel:5551234567")

        let reopened = LaborModel(
            context: ModelContext(try LaborStore.container(inMemory: true)),
            defaults: defaults
        )
        #expect(reopened.providerNumber == "(555) 123-4567", "the number survives a launch")
    }

    /// Half-typed is the common state of a field someone is filling one-handed:
    /// the button must not flicker into existence on the first character.
    @Test @MainActor func aHalfTypedFieldOffersNothing() throws {
        let suite = "net.wainright.laborkit.providerHalfTyped"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let model = LaborModel(
            context: ModelContext(try LaborStore.container(inMemory: true)),
            defaults: defaults
        )
        model.providerNumber = "("
        #expect(model.providerCallURL == nil)
        model.providerNumber = "(5"
        #expect(model.providerCallURL == nil)
        model.providerNumber = "(555"
        #expect(model.providerCallURL != nil)
    }
}
