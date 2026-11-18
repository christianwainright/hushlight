import Foundation

/// The privacy and support URLs the Guidance screen links to, in the language the app
/// is actually being read in.
///
/// These were hard-coded to the bare English paths, which was correct while English
/// was the only page that existed. It stopped being correct the moment the site grew a
/// locale segment per storefront: a reader who has the whole app in Japanese taps
/// "Privacy policy" and lands on English — and it is the *privacy* page, the one place
/// a reader is most entitled to understand every word, and the one an App Store
/// reviewer for a Japanese storefront opens.
///
/// **The fallback is the English page, never a guess.** An unregistered locale segment
/// 404s on that site rather than falling through to English, so a mapping this type is
/// unsure of must produce the bare path. Every segment named below is one that was
/// verified to resolve; nothing is constructed by pasting a language code into a URL
/// and hoping.
public enum PolicyLinks {
    private static let base = "https://christianwainright.com/hushlight"

    /// The site's locale segment for a given app language, or `nil` for the bare
    /// English path.
    ///
    /// The input is the language the **app resolved to**, not the device's preferred
    /// language: if someone's phone is in Dutch, the app is showing them English, and
    /// the English page is the honest destination.
    ///
    /// Two languages need the region as well, because the site follows App Store
    /// Connect's locale codes and Apple splits them by storefront where the app does
    /// not. Spanish outside Spain goes to `es-MX`, which is Apple's Latin American
    /// Spanish — the larger storefront for this category, and the one whose vocabulary
    /// a reader in Mexico or Argentina expects. French outside Canada goes to `fr-FR`.
    static func segment(language: String?, regionCode: String?) -> String? {
        guard let language else { return nil }
        // The app ships one `pt-BR` and one `zh-Hans`, so a reader in Portugal or
        // Taiwan is already reading Brazilian Portuguese or Simplified Chinese in the
        // app; sending them to a page in the variant they are *not* reading would be a
        // worse mismatch than the one this type exists to fix.
        switch language {
        case let english where english.hasPrefix("en"): return nil
        case "es": return regionCode == "ES" ? "es-ES" : "es-MX"
        case "fr": return regionCode == "CA" ? "fr-CA" : "fr-FR"
        case "de": return "de-DE"
        case "it": return "it"
        case "pt-BR": return "pt-BR"
        case "ja": return "ja"
        case "ko": return "ko"
        case "zh-Hans": return "zh-Hans"
        default: return nil
        }
    }

    static func url(page: String, language: String?, regionCode: String?) -> URL {
        let path = segment(language: language, regionCode: regionCode)
            .map { "\(base)/\($0)/\(page)" } ?? "\(base)/\(page)"
        // The bare English path is a compile-time-known good URL, so the fallback
        // cannot itself fail — `URL(string:)` is only optional here because `page` and
        // the segment are assembled at runtime.
        return URL(string: path) ?? URL(string: "\(base)/\(page)")!
    }

    /// Defaults read `Bundle.main.preferredLocalizations`, which is the language the
    /// app resolved to after its own fallback chain — not `Locale.preferredLanguages`,
    /// which is what the *phone* wants and may name a language this app does not ship.
    public static func privacy(
        language: String? = Bundle.main.preferredLocalizations.first,
        regionCode: String? = Locale.current.region?.identifier
    ) -> URL {
        url(page: "privacy", language: language, regionCode: regionCode)
    }

    public static func support(
        language: String? = Bundle.main.preferredLocalizations.first,
        regionCode: String? = Locale.current.region?.identifier
    ) -> URL {
        url(page: "support", language: language, regionCode: regionCode)
    }
}
