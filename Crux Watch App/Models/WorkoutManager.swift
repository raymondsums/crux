import Foundation
import HealthKit
import Combine

enum ClimbingState {
    case idle
    case elevated
    case recovering
    case recovered
}

struct HeartRateSample: Identifiable {
    let id = UUID()
    let bpm: Double
    let timestamp: Date
}

struct RecoveryEvent {
    let startTime: Date
    let endTime: Date
    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()

    // Workout session
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    // State
    @Published var isActive = false
    @Published var isPaused = false
    @Published var showingSummary = false
    @Published var showingActionSheet = false
    @Published var currentHeartRate: Double = 0
    @Published var climbingState: ClimbingState = .idle

    // HR history for summary chart
    @Published var heartRateSamples: [HeartRateSample] = []

    // Stats
    @Published var peakHeartRate: Double = 0
    @Published var workoutStartTime: Date?
    @Published var workoutEndTime: Date?

    // Elapsed time
    @Published var elapsedTime: TimeInterval = 0
    private var elapsedTimer: Timer?

    // Recovery tracking
    private var lastElevatedTime: Date?
    private var recoveryEvents: [RecoveryEvent] = []
    @Published var totalRecoveryCount: Int = 0

    // Settings
    var settings = CruxSettings()

    // Computed stats
    var totalDuration: TimeInterval {
        guard let start = workoutStartTime else { return 0 }
        let end = workoutEndTime ?? Date()
        return end.timeIntervalSince(start)
    }

    var totalRestTime: TimeInterval {
        recoveryEvents.reduce(0) { $0 + $1.duration }
    }

    var totalActiveTime: TimeInterval {
        totalDuration - totalRestTime
    }

    var averageRecoveryTime: TimeInterval {
        guard !recoveryEvents.isEmpty else { return 0 }
        return totalRestTime / Double(recoveryEvents.count)
    }

    var recoveryThreshold: Double {
        if settings.useCustomRecoveryHR {
            return Double(settings.recoveryHeartRate)
        }
        return 100
    }

    var formattedElapsedTime: String {
        let m = Int(elapsedTime) / 60
        let s = Int(elapsedTime) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    // MARK: - Authorization

    func requestAuthorization() {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, toRead: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Workout Session

    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .climbing
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()

            session?.delegate = self
            builder?.delegate = self

            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            let startDate = Date()
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { success, error in
                if let error = error {
                    print("Failed to begin collection: \(error.localizedDescription)")
                }
            }

            DispatchQueue.main.async {
                self.isActive = true
                self.isPaused = false
                self.workoutStartTime = startDate
                self.climbingState = .idle
                self.heartRateSamples = []
                self.recoveryEvents = []
                self.totalRecoveryCount = 0
                self.peakHeartRate = 0
                self.elapsedTime = 0
                HapticManager.workoutStarted()
                self.startElapsedTimer()
            }

            startHeartRateQuery()

        } catch {
            print("Failed to start workout: \(error.localizedDescription)")
        }
    }

    func pauseWorkout() {
        session?.pause()
        DispatchQueue.main.async {
            self.isPaused = true
            self.showingActionSheet = false
            self.stopElapsedTimer()
        }
    }

    func resumeWorkout() {
        session?.resume()
        DispatchQueue.main.async {
            self.isPaused = false
            self.startElapsedTimer()
        }
    }

    func endWorkout() {
        session?.end()
        stopElapsedTimer()

        DispatchQueue.main.async {
            self.isActive = false
            self.isPaused = false
            self.workoutEndTime = Date()
            self.climbingState = .idle
            self.showingActionSheet = false
            HapticManager.workoutEnded()
            self.showingSummary = true
        }
    }

    // MARK: - Elapsed Timer

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.elapsedTime += 1
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    // MARK: - Heart Rate Streaming

    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(
            withStart: workoutStartTime ?? Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        healthStore.execute(query)
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }

        let unit = HKUnit.count().unitDivided(by: .minute())

        for sample in samples {
            let bpm = sample.quantity.doubleValue(for: unit)

            DispatchQueue.main.async {
                self.currentHeartRate = bpm
                self.heartRateSamples.append(
                    HeartRateSample(bpm: bpm, timestamp: sample.startDate)
                )

                if bpm > self.peakHeartRate {
                    self.peakHeartRate = bpm
                }

                self.updateClimbingState(bpm: bpm)
            }
        }
    }

    // MARK: - State Machine

    private func updateClimbingState(bpm: Double) {
        let threshold = recoveryThreshold

        if bpm > threshold + 15 {
            if climbingState != .elevated {
                lastElevatedTime = Date()
            }
            climbingState = .elevated
        } else if bpm > threshold {
            if climbingState == .elevated {
                climbingState = .recovering
            }
        } else {
            if climbingState == .elevated || climbingState == .recovering {
                climbingState = .recovered

                if let elevatedTime = lastElevatedTime {
                    let event = RecoveryEvent(startTime: elevatedTime, endTime: Date())
                    recoveryEvents.append(event)
                    totalRecoveryCount += 1
                }

                HapticManager.recovered()
            }
        }
    }

    func dismissSummary() {
        showingSummary = false
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        if toState == .ended {
            builder?.endCollection(withEnd: date) { [weak self] success, error in
                self?.builder?.finishWorkout { workout, error in
                    if let error = error {
                        print("Failed to finish workout: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {}
}
