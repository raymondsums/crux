import Foundation
import WatchKit

struct HapticManager {
    static func recovered() {
        WKInterfaceDevice.current().play(.success)
    }

    static func routeLogged() {
        WKInterfaceDevice.current().play(.click)
    }

    static func workoutStarted() {
        doubleTap()
    }

    static func workoutEnded() {
        doubleTap()
    }

    /// Two quick taps — no audible tone, unlike .start / .stop.
    private static func doubleTap() {
        let device = WKInterfaceDevice.current()
        device.play(.click)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            device.play(.click)
        }
    }
}
