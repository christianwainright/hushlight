import Observation

/// **A keyboard on the tray table** (HL-058b). The app's menu commands — Space to
/// start and end, ⌘Z, ⌘J History, ⌘G Guidance — live at the `App` level so iPadOS
/// lists them in its own ⌘-hold HUD; the screen that owns the action is `TimerScreen`.
/// This is the wire between the two: a command bumps a counter, the screen observes
/// it and performs exactly what the tap would have — the slab's own action with its
/// slip note, the undo with its correction haptic, the push the toolbar link makes —
/// so a key and a finger can never do two different things.
@Observable
@MainActor
final class KeyboardIntents {
    var tapSlab = 0
    var undo = 0
    var openHistory = 0
    var openGuidance = 0

    /// What is in front of the timer, kept by the views that put it there. A
    /// hardware keyboard reaches the commands wherever the eye is: Space with
    /// Guidance pushed, or a sheet up, would start or end a contraction with the slab
    /// off screen — a wrong record nobody saw made. So Space is offered only while
    /// the timer itself is frontmost, and ⌘J/⌘G only while no sheet covers the stack
    /// (a path changed under a sheet lands the reader somewhere they never went).
    var pushedScreen = false
    var presentedSheets = 0

    var timerIsFrontmost: Bool { !pushedScreen && presentedSheets == 0 }
    var canNavigate: Bool { presentedSheets == 0 }

    func sheet(_ presented: Bool) {
        presentedSheets = max(0, presentedSheets + (presented ? 1 : -1))
    }
}
