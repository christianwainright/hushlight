import Foundation
import Testing
@testable import LaborKit

/// The privacy and support links pointed at the English page in every language until
/// HL-052. These pin the mapping — and, more importantly, pin the *fallback*: the
/// site 404s an unregistered locale segment rather than serving English, so a language
/// this type does not recognise must produce the bare path and never a constructed
/// guess.
@Suite("Policy links")
struct PolicyLinksTests {

    @Test("every shipped language reaches its own page", arguments: [
        ("en", "US", "https://christianwainright.com/hushlight/privacy"),
        ("en", "GB", "https://christianwainright.com/hushlight/privacy"),
        ("de", "DE", "https://christianwainright.com/hushlight/de-DE/privacy"),
        ("it", "IT", "https://christianwainright.com/hushlight/it/privacy"),
        ("ja", "JP", "https://christianwainright.com/hushlight/ja/privacy"),
        ("ko", "KR", "https://christianwainright.com/hushlight/ko/privacy"),
        ("pt-BR", "BR", "https://christianwainright.com/hushlight/pt-BR/privacy"),
        ("zh-Hans", "CN", "https://christianwainright.com/hushlight/zh-Hans/privacy"),
    ])
    func privacyPerLanguage(language: String, region: String, expected: String) {
        #expect(PolicyLinks.privacy(language: language, regionCode: region).absoluteString == expected)
    }

    /// Apple splits these two by storefront where the app ships one language each, so
    /// the region is load-bearing rather than decoration.
    @Test("Spanish and French follow the storefront, not just the language", arguments: [
        ("es", "ES", "es-ES"), ("es", "MX", "es-MX"), ("es", "AR", "es-MX"), ("es", "US", "es-MX"),
        ("fr", "FR", "fr-FR"), ("fr", "CA", "fr-CA"), ("fr", "BE", "fr-FR"),
    ])
    func regionalSplit(language: String, region: String, segment: String) {
        #expect(PolicyLinks.support(language: language, regionCode: region).absoluteString
                == "https://christianwainright.com/hushlight/\(segment)/support")
    }

    /// The failure that matters. A segment this type has not verified would 404, which
    /// is strictly worse than an English page the reader can still act on — and worse
    /// again on the privacy page an App Store reviewer opens.
    @Test("an unknown or absent language falls back to English, never a guess",
          arguments: [nil, "nl", "ru", "zh-Hant", "ar", "xx-YY", ""] as [String?])
    func unknownLanguageFallsBack(language: String?) {
        for page in ["privacy", "support"] {
            let url = PolicyLinks.url(page: page, language: language, regionCode: "NL")
            #expect(url.absoluteString == "https://christianwainright.com/hushlight/\(page)")
        }
    }

    /// Region absent (Locale.current.region can be nil) must not crash or produce a
    /// half-built path.
    @Test func missingRegionStillResolves() {
        #expect(PolicyLinks.privacy(language: "es", regionCode: nil).absoluteString
                == "https://christianwainright.com/hushlight/es-MX/privacy")
        #expect(PolicyLinks.privacy(language: "fr", regionCode: nil).absoluteString
                == "https://christianwainright.com/hushlight/fr-FR/privacy")
    }
}
