import Foundation
import CoreGraphics
import Combine

final class MemoryPlanetViewModel: ObservableObject {
    @Published var unlockedPlanets: [MemoryPlanetType] = []

    /// 起動時に一度だけ計算した軌道位置キャッシュ（惑星解放時も更新）
    private(set) var positionCache: [MemoryPlanetType: CGPoint] = [:]

    func sync(memoCount: Int) {
        let unlocked = MemoryPlanetType.allCases.filter {
            memoCount >= $0.requiredCount
        }
        // 起動時に全解放済み惑星の位置を再計算
        for planet in unlocked {
            positionCache[planet] = planet.normPosition()
        }
        unlockedPlanets = unlocked
    }

    /// 正規化スクリーン座標でのタップ判定（キャッシュ位置を使用）
    func planet(atNorm pt: CGPoint) -> MemoryPlanetType? {
        for planet in unlockedPlanets {
            guard let pos = positionCache[planet] else { continue }
            let dx = pt.x - pos.x
            let dy = pt.y - pos.y
            if (dx * dx + dy * dy).squareRoot() < 0.05 { return planet }
        }
        return nil
    }

    /// 惑星に格納されるメモ（作成日時昇順で 1-indexed の memoIndexRange 番目）
    func memos(for planet: MemoryPlanetType, allMemos: [Memo]) -> [Memo] {
        let sorted   = allMemos.sorted { $0.createdAt < $1.createdAt }
        let range    = planet.memoIndexRange
        let startIdx = range.lowerBound - 1
        let endIdx   = min(range.upperBound - 1, sorted.count - 1)
        guard startIdx >= 0, startIdx <= endIdx else { return [] }
        return Array(sorted[startIdx...endIdx])
    }

    /// Metal へ渡すレンダーバッファ（キャッシュ位置を使用）
    func renderVertices(scale: Float) -> [PlanetRenderVertex] {
        unlockedPlanets.compactMap { planet in
            guard let pos = positionCache[planet] else { return nil }
            return PlanetRenderVertex(
                position:   SIMD2<Float>(Float(pos.x), Float(pos.y)),
                pointSize:  planet.pointSizePixels(scale: scale),
                planetType: UInt32(planet.rawValue)
            )
        }
    }
}
