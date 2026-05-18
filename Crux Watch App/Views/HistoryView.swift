import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: SessionHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HISTORY")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)

            if history.sessions.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Text("No sessions yet")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray.opacity(0.5))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(history.sessions) { session in
                            SessionCard(session: session)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SessionCard: View {
    let session: ClimbSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.formattedDate)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(session.formattedDuration)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 12) {
                StatPill(icon: "heart.fill", value: "\(Int(session.peakHeartRate))", color: .red)

                if session.totalClimbs > 0 {
                    StatPill(icon: "figure.climbing", value: "\(session.totalClimbs)", color: .blue)
                }

                StatPill(icon: "arrow.counterclockwise", value: "\(session.totalRecoveries)", color: .green)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    let history = SessionHistory()
    HistoryView(history: history)
}
