import DesignKit
import SwiftUI
import UIKit

/// What a hand-off button shows when the OS refused the hand-off (HL-057).
///
/// `Report a problem` offers a mail draft and `Call` offers a phone call; both are
/// `openURL` and both can be refused — a device with the Mail app removed, an iPad
/// with nothing to dial through. Before this, the tap did nothing at all, and a
/// silent button reads as a broken one. The fallback is the thing the button was
/// going to hand over — the address, the number — written out with a Copy beside
/// it, so she can still do by hand what the app could not do for her.
struct HandoffFallback: View {
    /// One calm sentence: what this device cannot do, then a colon.
    let explanation: LocalizedStringResource
    /// The address or the number, exactly as it will be copied.
    let value: String
    let copyTitle: LocalizedStringResource
    let copyHint: LocalizedStringResource

    @State private var didCopy = false

    /// The same lifetime `ForTheCallScreen`'s Copy uses, for the same reason.
    private static let copyConfirmationLifetime = 2.0

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.space2) {
            Text(explanation)
                .font(.prose)
                .foregroundStyle(Palette.secondaryText)
            Text(value)
                .font(.prose)
                .foregroundStyle(Palette.primaryText)
                .textSelection(.enabled)
            Button {
                UIPasteboard.general.string = value
                didCopy = true
                Task {
                    try? await Task.sleep(for: .seconds(Self.copyConfirmationLifetime))
                    didCopy = false
                }
            } label: {
                Label {
                    didCopy ? Text("Copied") : Text(copyTitle)
                } icon: {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                }
            }
            .buttonStyle(.capsuleTinted)
            .accessibilityLabel(didCopy
                ? String(localized: "Copied", comment: "VoiceOver label for the Copy button on the For the call card, after the tap that copied the sentence")
                : String(localized: copyTitle))
            .accessibilityHint(String(localized: copyHint))
            .sensoryFeedback(trigger: didCopy) { _, copied in copied ? .success : nil }
        }
        .padding(.top, Metrics.space1)
        .accessibilityElement(children: .contain)
    }
}
