import DesignKit
import LaborKit
import SwiftUI

/// The call the verdict has been recommending all along (SP-200).
///
/// Renders nothing at all unless a number is stored — the field is optional and
/// stays optional, so an empty one is a silence, never a prompt. The `tel:` URL
/// hands the decision back to the OS, which shows its own confirmation before it
/// dials: this app never places a call, it offers one.
struct CallProviderButton: View {
    @Environment(LaborModel.self) private var model
    @Environment(\.openURL) private var openURL

    /// What the button says. The verdict banner needs the number-free form —
    /// the sentence above it already named the provider — while Guidance, read
    /// cold, benefits from seeing which number is about to be dialed.
    var showsNumber = false

    /// The OS said no — nothing on this device can dial (HL-057). An iPad falls to
    /// FaceTime when it can; when it cannot, the number is written out instead of
    /// the button doing nothing.
    ///
    /// A caller that builds this button in more than one layout branch — Guidance's
    /// `ViewThatFits` pair — owns the flag and passes it in, because the fallback
    /// changes the measured width, the branch can switch, and a fresh instance would
    /// start at `false` and take the fallback away the moment it appeared. Callers
    /// with one instance leave it nil and the button keeps its own.
    var refused: Binding<Bool>?
    @State private var ownRefused = false
    private var callRefused: Binding<Bool> { refused ?? $ownRefused }

    var body: some View {
        if let url = model.providerCallURL {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    openURL(url) { accepted in callRefused.wrappedValue = !accepted }
                } label: {
                    Label(title, systemImage: "phone.fill")
                }
                .buttonStyle(.capsuleFilled)
                .accessibilityLabel(spokenLabel)

                if callRefused.wrappedValue {
                    HandoffFallback(
                        explanation: LocalizedStringResource("This device cannot place calls. The number:", comment: "shown under the Call button when the OS could not place the call; the stored provider number follows"),
                        value: model.providerNumber,
                        copyTitle: LocalizedStringResource("Copy number", comment: "button label: copies the stored provider phone number to the clipboard"),
                        copyHint: LocalizedStringResource("Copies the number", comment: "VoiceOver hint for the Copy number button")
                    )
                }
            }
        }
    }

    private var title: String {
        showsNumber
            ? String(localized: "Call \(model.providerNumber)", comment: "capsule button label: call, followed by the stored provider phone number")
            : String(localized: "Call", comment: "capsule button label: call the stored provider, number not shown (the sentence above it already named the provider)")
    }

    /// Digits read as a single long number are unusable spoken; VoiceOver says the
    /// destination in words instead, and the number itself is one field away.
    private var spokenLabel: String {
        String(localized: "Call your provider", comment: "VoiceOver label for the call-provider button — spoken form, since digits read as one long number are unusable spoken")
    }
}
