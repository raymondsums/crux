import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject private var routeLog = RouteLog()
    @StateObject private var history = SessionHistory()

    var body: some View {
        if workoutManager.showingSummary {
            SummaryView(
                routeLog: routeLog,
                settings: workoutManager.settings
            )
            .environmentObject(workoutManager)
            .onAppear {
                saveSession()
            }
        } else if workoutManager.isActive {
            TabView {
                HeartRateView()

                RouteLoggerView(
                    routeLog: routeLog,
                    settings: workoutManager.settings
                )
            }
            .tabViewStyle(.verticalPage)
        } else {
            TabView {
                HeartRateView()

                HistoryView(history: history)
            }
            .tabViewStyle(.verticalPage)
        }
    }

    private func saveSession() {
        let session = ClimbSession(
            id: UUID(),
            date: workoutManager.workoutStartTime ?? Date(),
            duration: workoutManager.totalDuration,
            peakHeartRate: workoutManager.peakHeartRate,
            averageRecoveryTime: workoutManager.averageRecoveryTime,
            totalRecoveries: workoutManager.totalRecoveryCount,
            activeTime: workoutManager.totalActiveTime,
            restTime: workoutManager.totalRestTime,
            climbs: routeLog.entries.map { GradeEntry(grade: $0.grade, timestamp: $0.timestamp) }
        )
        history.save(session: session)
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
}
