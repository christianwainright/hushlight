import Foundation

/// The optional provider or labor-and-delivery number, and the one place that
/// decides what counts as dialable.
///
/// The app's central sentence is "Calling your provider now is reasonable", and
/// until SP-200 it ended in a Contacts search — in pain, one-handed, in the dark.
/// One field answers it. Everything here is deliberately small: the number is a
/// string this device keeps beside its rule, never a contact record, never a
/// lookup, never anything that leaves (decision 0018's promise is the whole
/// product). Nothing nags: unset means no button anywhere, and no prompt to set one.
public enum ProviderContact {
    /// Named once, for the same reason `GuidelineRule.defaultsKey` is: two surfaces
    /// read this — the Guidance field that writes it and the model that offers the
    /// button — and a second copy of the string is how they stop agreeing.
    public static let defaultsKey = "providerNumber"

    /// What this device has stored, or empty.
    public static func persisted(in defaults: UserDefaults = .standard) -> String {
        defaults.string(forKey: defaultsKey) ?? ""
    }

    /// Characters a dial string may carry: digits, `+` for an international prefix,
    /// `*` and `#` for menu keys, and `,` for the pause an extension needs. Everything
    /// else in a number as people write it — spaces, parentheses, dashes, dots,
    /// "ext." — is presentation, and is dropped.
    private static let dialable = Set("0123456789+*#,")

    /// The `tel:` URL for entered text, or nil when there is nothing worth dialing.
    ///
    /// The floor is three digits: a field holding "(" or "+" alone is someone
    /// mid-typing, and a Call button that appears then would dial nothing while
    /// claiming otherwise. `+` survives only in the leading position, where it
    /// means something.
    public static func telURL(for entry: String) -> URL? {
        var digits = 0
        var dial = ""
        for character in entry where dialable.contains(character) {
            if character == "+" && !dial.isEmpty { continue }
            if character.isNumber { digits += 1 }
            dial.append(character)
        }
        guard digits >= minimumDigits else { return nil }

        // `#` is a fragment delimiter to `URL`, so a hospital menu key would
        // silently truncate the number it is part of.
        return URL(string: "tel:" + dial.replacingOccurrences(of: "#", with: "%23"))
    }

    /// Short enough to admit a four-digit internal extension line, long enough that
    /// a half-typed field stays quiet.
    static let minimumDigits = 3
}
