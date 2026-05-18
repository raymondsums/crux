import WatchKit

struct HapticManager {
    static func recovered() {
        WKInterfaceDevice.current().play(.success)
    }

    static func routeLogged() {
        WKInterfaceDevice.current().play(.click)
    }

    static func workoutStarted() {
        WKInterfaceDevice.current().play(.start)
    }

    static func workoutEnded() {
        WKInterfaceDevice.current().play(.stop)
    }
}
