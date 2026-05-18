import Foundation

class CruxSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var recoveryHeartRate: Int {
        didSet { defaults.set(recoveryHeartRate, forKey: "recoveryHeartRate") }
    }

    @Published var useCustomRecoveryHR: Bool {
        didSet { defaults.set(useCustomRecoveryHR, forKey: "useCustomRecoveryHR") }
    }

    @Published var gradeRangeStart: Int {
        didSet { defaults.set(gradeRangeStart, forKey: "gradeRangeStart") }
    }

    @Published var gradeRangeEnd: Int {
        didSet { defaults.set(gradeRangeEnd, forKey: "gradeRangeEnd") }
    }

    var gradeRange: [Int] {
        Array(gradeRangeStart...gradeRangeEnd)
    }

    var gradeLabels: [String] {
        gradeRange.map { "V\($0)" }
    }

    init() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: "recoveryHeartRate") == nil {
            defaults.set(100, forKey: "recoveryHeartRate")
        }
        if defaults.object(forKey: "useCustomRecoveryHR") == nil {
            defaults.set(false, forKey: "useCustomRecoveryHR")
        }
        if defaults.object(forKey: "gradeRangeStart") == nil {
            defaults.set(2, forKey: "gradeRangeStart")
        }
        if defaults.object(forKey: "gradeRangeEnd") == nil {
            defaults.set(6, forKey: "gradeRangeEnd")
        }

        self.recoveryHeartRate = defaults.integer(forKey: "recoveryHeartRate")
        self.useCustomRecoveryHR = defaults.bool(forKey: "useCustomRecoveryHR")
        self.gradeRangeStart = defaults.integer(forKey: "gradeRangeStart")
        self.gradeRangeEnd = defaults.integer(forKey: "gradeRangeEnd")
    }
}
