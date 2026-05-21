import Foundation
import Combine

struct ClimbSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let peakHeartRate: Double
    let averageRecoveryTime: TimeInterval
    let totalRecoveries: Int
    let activeTime: TimeInterval
    let restTime: TimeInterval
    let climbs: [GradeEntry]

    var totalClimbs: Int { climbs.count }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let m = Int(duration) / 60
        if m >= 60 {
            return "\(m / 60)h \(m % 60)m"
        }
        return "\(m)m"
    }
}

struct GradeEntry: Codable {
    let grade: Int
    let timestamp: Date
}

class SessionHistory: ObservableObject {
    private let key = "sessionHistory"

    @Published var sessions: [ClimbSession] = []

    init() {
        load()
    }

    func save(session: ClimbSession) {
        sessions.insert(session, at: 0)
        persist()
    }

    func clear() {
        sessions.removeAll()
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ClimbSession].self, from: data) else {
            return
        }
        sessions = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
