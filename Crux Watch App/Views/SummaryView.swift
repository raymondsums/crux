import SwiftUI
import Charts

struct SummaryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var routeLog: RouteLog
    @ObservedObject var settings: CruxSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Session Complete")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.green)

                // HR Chart
                if !workoutManager.heartRateSamples.isEmpty {
                    heartRateChart
                }

                // Stats
                statsSection

                // Route Pyramid
                if routeLog.totalClimbs > 0 {
                    routePyramid
                }

                // Done button
                Button {
                    routeLog.reset()
                    workoutManager.dismissSummary()
                } label: {
                    Text("Done")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }

    // MARK: - Heart Rate Chart

    private var heartRateChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HEART RATE")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.gray)

            Chart(workoutManager.heartRateSamples) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("BPM", sample.bpm)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.red, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                RuleMark(y: .value("Recovery", workoutManager.recoveryThreshold))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                    AxisValueLabel()
                        .font(.system(.caption2, design: .rounded))
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 80)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: 8) {
            HStack {
                StatBox(label: "Duration", value: formatDuration(workoutManager.totalDuration))
                StatBox(label: "Peak HR", value: "\(Int(workoutManager.peakHeartRate))")
            }

            HStack {
                StatBox(label: "Active", value: formatDuration(workoutManager.totalActiveTime))
                StatBox(label: "Rest", value: formatDuration(workoutManager.totalRestTime))
            }

            HStack {
                StatBox(label: "Recoveries", value: "\(workoutManager.totalRecoveryCount)")
                StatBox(label: "Avg Recovery", value: formatDuration(workoutManager.averageRecoveryTime))
            }

            if routeLog.totalClimbs > 0 {
                HStack {
                    StatBox(label: "Climbs", value: "\(routeLog.totalClimbs)")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Route Pyramid (monochrome)

    private var routePyramid: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ROUTES SENT")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.gray)

            let grades = settings.gradeRange
            let maxCount = max(routeLog.maxCount(in: grades), 1)

            ForEach(grades, id: \.self) { grade in
                let count = routeLog.count(for: grade)
                if count > 0 {
                    let brightness = max(0.3, 1.0 - Double(grade) * 0.06)

                    HStack(spacing: 6) {
                        Text("V\(grade)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundColor(.white.opacity(brightness))
                            .frame(width: 28, alignment: .leading)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(brightness * 0.3))
                                .frame(
                                    width: CGFloat(count) / CGFloat(maxCount) * geo.size.width,
                                    height: 14
                                )
                        }
                        .frame(height: 14)

                        Text("\(count)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m \(seconds)s"
    }
}

struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SummaryView(
        routeLog: RouteLog(),
        settings: CruxSettings()
    )
    .environmentObject(WorkoutManager())
}
