import Foundation
import CoreGraphics

struct Planet: Identifiable, Codable, Equatable {
    let id:          UUID
    var title:       String
    var body:        String
    var createdAt:   Date
    var deadline:    Date
    var isCompleted: Bool
    /// 軌道の個性を
    var orbitSeed:   Double

    init(id: UUID = UUID(),
         title: String,
         body: String = "",
         createdAt: Date = Date(),
         deadline: Date,
         isCompleted: Bool = false,
         orbitSeed: Double = Double.random(in: 0...1)) {
        self.id          = id
        self.title       = title
        self.body        = body
        self.createdAt   = createdAt
        self.deadline    = deadline
        self.isCompleted = isCompleted
        self.orbitSeed   = orbitSeed
    }

    /// 満ち欠け1.0=満月（作成直後）→ 0.0=新月（期限当日）
    var moonPhase: Double {
        let total    = deadline.timeIntervalSince(createdAt)
        let elapsed  = Date().timeIntervalSince(createdAt)
        guard total > 0 else { return 0 }
        return max(0, min(1, 1.0 - elapsed / total))
    }

    /// 期限まで何日か
    var daysRemaining: Int {
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: deadline)
        return max(0, diff.day ?? 0)
    }

    var isOverdue: Bool { Date() > deadline && !isCompleted }
}
