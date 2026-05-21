import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var hasOnboarded: Bool

    @State private var step = 0
    @State private var requesting = false
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if step == 0 {
                    introScreen
                } else {
                    permissionScreen
                }
            }
            .transition(.opacity)

            VStack {
                Spacer()
                HStack(spacing: 5) {
                    stepDot(active: step == 0)
                    stepDot(active: step == 1)
                }
                .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    private func stepDot(active: Bool) -> some View {
        Capsule()
            .fill(active ? Color.green : Color.white.opacity(0.18))
            .frame(width: active ? 14 : 5, height: 4)
    }

    // MARK: - Intro

    private var introScreen: some View {
        VStack(spacing: 8) {
            Spacer()

            Text("CRUX")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)
                )
                .tracking(5)

            Spacer()

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Continue")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }

    // MARK: - Permission primer

    private var permissionScreen: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 38))
                .foregroundColor(.red)
                .shadow(color: .red.opacity(0.4), radius: 12)
                .scaleEffect(heartScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        heartScale = 1.12
                    }
                }

            Text("Heart rate access")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundColor(.white)

            Text("Crux reads your heart rate to sense when you've recovered between climbs. It never leaves your watch.")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                requesting = true
                workoutManager.requestAuthorization {
                    withAnimation { hasOnboarded = true }
                }
            } label: {
                Text(requesting ? "Requesting…" : "Enable Heart Rate")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(requesting)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(hasOnboarded: .constant(false))
        .environmentObject(WorkoutManager())
}
