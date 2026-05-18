import Foundation

struct ClimbEntry: Identifiable {
    let id = UUID()
    let grade: Int
    let timestamp: Date

    var gradeLabel: String {
        "V\(grade)"
    }
}

class RouteLog: ObservableObject {
    @Published var entries: [ClimbEntry] = []

    var totalClimbs: Int {
        entries.count
    }

    func log(grade: Int) {
        let entry = ClimbEntry(grade: grade, timestamp: Date())
        entries.append(entry)
    }

    func count(for grade: Int) -> Int {
        entries.filter { $0.grade == grade }.count
    }

    func maxCount(in range: [Int]) -> Int {
        range.map { count(for: $0) }.max() ?? 1
    }

    func reset() {
        entries.removeAll()
    }
}
