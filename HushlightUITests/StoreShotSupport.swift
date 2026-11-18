import XCTest

/// What the two store-shot drivers share (HL-037's `StoreShots`, HL-058c's
/// `StoreShotsPad`): the launch language, the identifier lookup, and the capture.
enum StoreShotSupport {
    /// `-AppleLanguages` and a matching locale, so a Japanese shot carries a Japanese
    /// date — or nothing for English (HL-048). An unknown language is English too;
    /// the shell scripts refuse one before they get here.
    static func languageArguments(_ language: String) -> [String] {
        let locales = ["es": "es_ES", "fr": "fr_FR", "de": "de_DE", "it": "it_IT",
                       "pt-BR": "pt_BR", "ja": "ja_JP", "ko": "ko_KR", "zh-Hans": "zh_CN"]
        guard !language.isEmpty, let locale = locales[language] else { return [] }
        return ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
    }
}

extension XCTestCase {
    /// An accessibility identifier propagates to a view's children, so a bare
    /// `matching(identifier:)` reports "multiple matching elements" — the outermost
    /// match is the one that takes the tap (HL-048).
    func storeElement(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The screen, kept always, named for the raw file it becomes.
    func captureScreen(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
