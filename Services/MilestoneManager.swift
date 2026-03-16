import Foundation
import Combine

/// マイルストーン種別（rawValue = 解放に必要なメモ数）
enum MilestoneKind: Int, CaseIterable {
    case emotionColor  = 10
    case shootingStar  = 35
    case reminderMoon  = 50
    case mercury       = 100
    case venus         = 200
    case mars          = 300
    case jupiter       = 400
    case saturn        = 500
    case uranus        = 600
    case neptune       = 700
    case comet         = 800
    case endroll       = 900
}

final class MilestoneManager: ObservableObject {
    static let shared = MilestoneManager()

    private let udKey = "unlockedMilestoneThresholds"

    @Published private(set) var unlockedThresholds: Set<Int> = []

    private init() {
        let saved = UserDefaults.standard.array(forKey: udKey) as? [Int] ?? []
        unlockedThresholds = Set(saved)
    }

    /// メモ数をチェックし、新たに解放されたマイルストーンを返す
    @discardableResult
    func checkAndUnlock(memoCount: Int) -> [MilestoneKind] {
        var newly: [MilestoneKind] = []
        for kind in MilestoneKind.allCases {
            if memoCount >= kind.rawValue && !unlockedThresholds.contains(kind.rawValue) {
                unlockedThresholds.insert(kind.rawValue)
                newly.append(kind)
            }
        }
        if !newly.isEmpty {
            UserDefaults.standard.set(Array(unlockedThresholds), forKey: udKey)
        }
        return newly
    }

    func isUnlocked(_ kind: MilestoneKind) -> Bool {
        unlockedThresholds.contains(kind.rawValue)
    }

    var unlockedCount: Int { unlockedThresholds.count }
    var totalCount:    Int { MilestoneKind.allCases.count }

    /// 次のマイルストーンまで何個か（達成済みの場合は nil）
    func stepsToNext(current: Int) -> Int? {
        for kind in MilestoneKind.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            if current < kind.rawValue { return kind.rawValue - current }
        }
        return nil
    }
}
