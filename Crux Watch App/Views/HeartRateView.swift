import SwiftUI

struct HeartRateView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var pulseScale: CGFloat = 1.0
    @State private var rippleScale: CGFloat = 0.8
    @State private var rippleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if workoutManager.isActive {
                activeWorkoutView
            } else {
                startView
            }

            // Edge glow on recovery
            if workoutManager.climbingState == .recovered {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.green.opacity(0.4), lineWidth: 6)
                    .blur(radius: 8)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // Action sheet overlay
            if workoutManager.showingActionSheet {
                actionSheetOverlay
            }
        }
    }

    // MARK: - Start Screen

    private var startView: some View {
        VStack(spacing: 12) {
            Spacer()

            Text("CRUX")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .gray],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .tracking(4)

            ZStack {
                // Ripple rings
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 60, height: 60)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)

                Image(systemName: "heart.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.4), radius: 16)
                    .scaleEffect(pulseScale)
            }
            .onAppear {
                startHeartbeatAnimation()
            }

            Spacer()

            Button {
                workoutManager.requestAuthorization()
                workoutManager.startWorkout()
            } label: {
                Label("Start Climb", systemImage: "play.fill")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    // MARK: - Active Workout

    private var activeWorkoutView: some View {
        VStack(spacing: 4) {
            // "Ready to Climb" label
            Text("READY TO CLIMB")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.green)
                .opacity(workoutManager.climbingState == .recovered ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: workoutManager.climbingState)
                .frame(height: 12)

            // State indicator bars
            HStack(spacing: 4) {
                StateBar(color: .red, isActive: workoutManager.climbingState == .elevated)
                StateBar(color: .yellow, isActive: workoutManager.climbingState == .recovering)
                StateBar(color: .green, isActive: workoutManager.climbingState == .recovered)
            }
            .frame(width: 80)

            Spacer()

            // Heart rate number
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(workoutManager.climbingState == .recovered ? .green : .gray)

                    Text("\(Int(workoutManager.currentHeartRate))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }

                Text("BPM")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.top, 24)

            Spacer()

            // Elapsed time
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(workoutManager.formattedElapsedTime)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                Text("ELAPSED")
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
        .onLongPressGesture(minimumDuration: 0.5) {
            workoutManager.showingActionSheet = true
        }
        .onChange(of: workoutManager.climbingState) { _, newState in
            withAnimation {
                if newState == .recovered {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulseScale = 1.3
                    }
                } else {
                    pulseScale = 1.0
                }
            }
        }
    }

    // MARK: - Action Sheet

    private var actionSheetOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Button {
                    workoutManager.pauseWorkout()
                } label: {
                    Text("Pause")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow.opacity(0.3))
                .foregroundColor(.yellow)

                Button {
                    workoutManager.endWorkout()
                } label: {
                    Text("End Workout")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.3))
                .foregroundColor(.red)

                Button {
                    workoutManager.showingActionSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(.caption, weight: .bold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            }
        }
    }

    // MARK: - Heartbeat Animation

    private func startHeartbeatAnimation() {
        // Resting heart rate ~68 bpm
        let duration = 60.0 / 68.0

        withAnimation(
            .easeInOut(duration: duration * 0.15)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.15
        }

        withAnimation(
            .easeOut(duration: duration)
            .repeatForever(autoreverses: false)
        ) {
            rippleScale = 2.2
            rippleOpacity = 0
        }
    }
}

// MARK: - State Bar

struct StateBar: View {
    let color: Color
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isActive ? color.opacity(color == .green ? 1.0 : 0.5) : Color.white.opacity(0.08))
            .frame(height: 4)
            .shadow(color: isActive ? color.opacity(0.3) : .clear, radius: isActive ? 4 : 0)
            .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var settings: CruxSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(.headline, design: .rounded))

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Custom Recovery HR", isOn: $settings.useCustomRecoveryHR)
                        .font(.system(.caption, design: .rounded))

                    if settings.useCustomRecoveryHR {
                        Stepper(
                            value: $settings.recoveryHeartRate,
                            in: 60...140,
                            step: 5
                        ) {
                            Text("\(settings.recoveryHeartRate) BPM")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Grade Range")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)

                    Stepper("Start: V\(settings.gradeRangeStart)", value: $settings.gradeRangeStart, in: 0...settings.gradeRangeEnd - 1)
                        .font(.system(.caption, design: .rounded))

                    Stepper("End: V\(settings.gradeRangeEnd)", value: $settings.gradeRangeEnd, in: settings.gradeRangeStart + 1...17)
                        .font(.system(.caption, design: .rounded))
                }

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

#Preview {
    HeartRateView()
        .environmentObject(WorkoutManager())
}
