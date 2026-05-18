import SwiftUI

struct RouteLoggerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var routeLog: RouteLog
    @ObservedObject var settings: CruxSettings

    @State private var visibleStart: Int?
    @State private var totalBounce: Bool = false

    private var startGrade: Int {
        visibleStart ?? settings.gradeRangeStart
    }

    private var visibleGrades: [Int] {
        let end = min(startGrade + 3, settings.gradeRangeEnd)
        return Array(startGrade...end)
    }

    private var canGoLeft: Bool { startGrade > 0 }
    private var canGoRight: Bool { startGrade + 3 < 17 }

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Text("ROUTES")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(routeLog.totalClimbs)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(totalBounce ? 1.5 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: totalBounce)
                    .onChange(of: routeLog.totalClimbs) {
                        totalBounce = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            totalBounce = false
                        }
                    }
                Text("sends")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)

            // Vertical bar columns
            let grades = visibleGrades
            let maxCount = max(routeLog.maxCount(in: grades), 1)

            HStack(spacing: 6) {
                ForEach(grades, id: \.self) { grade in
                    GradeColumn(
                        grade: grade,
                        count: routeLog.count(for: grade),
                        maxCount: maxCount,
                        onTap: {
                            routeLog.log(grade: grade)
                            HapticManager.routeLogged()
                        }
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width < -20 && canGoRight {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                visibleStart = min(startGrade + 3, 13)
                            }
                        } else if value.translation.width > 20 && canGoLeft {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                visibleStart = max(startGrade - 3, 0)
                            }
                        }
                    }
            )

        }
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

struct GradeColumn: View {
    let grade: Int
    let count: Int
    let maxCount: Int
    let onTap: () -> Void

    @State private var countBounce: Bool = false

    private var brightness: Double {
        max(0.3, 1.0 - Double(grade) * 0.06)
    }

    private var gradeColor: Color {
        Color.white.opacity(brightness)
    }

    private var trackColor: Color {
        Color.white.opacity(brightness * 0.06)
    }

    private var fillColor: Color {
        Color.white.opacity(brightness * 0.3)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Grade label at top
            Text("V\(grade)")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(gradeColor)

            // Vertical bar
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(trackColor)

                    // Fill growing from bottom
                    if count > 0 {
                        VStack {
                            Text("\(count)")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(countBounce ? 1.5 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: countBounce)
                                .onChange(of: count) {
                                    countBounce = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        countBounce = false
                                    }
                                }
                                .padding(.top, 4)
                            Spacer()
                        }
                        .frame(
                            width: geo.size.width,
                            height: max(
                                CGFloat(count) / CGFloat(maxCount) * geo.size.height,
                                24
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(fillColor)
                        )
                        .animation(.spring(response: 0.3), value: count)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

#Preview {
    RouteLoggerView(
        routeLog: RouteLog(),
        settings: CruxSettings()
    )
    .environmentObject(WorkoutManager())
}
