import Foundation
import CoreGraphics
import simd
import Combine

final class SkyViewModel: ObservableObject {
    @Published private(set) var memoStars:       [StarRenderData] = []
    @Published private(set) var backgroundStars: [StarRenderData] = []

    private var memoIndex: [UUID: StarRenderData] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var lastMemos: [Memo] = []

    init() {
        generateBackgroundStars()


        MilestoneManager.shared.$unlockedThresholds
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.syncFromMemos(self.lastMemos)
            }
            .store(in: &cancellables)
    }

    // MARK: - Memo star sync

    func syncFromMemos(_ memos: [Memo]) {
        lastMemos = memos
        let minRadius: CGFloat = 2.8
        let maxRadius: CGFloat = 5.5


        let sorted = memos.sorted { $0.createdAt < $1.createdAt }


        let archivedIDs: Set<UUID> = {
            var ids = Set<UUID>()
            for planet in MemoryPlanetType.allCases {
                guard MilestoneManager.shared.isUnlocked(planet.milestonekind) else { continue }
                let range = planet.memoIndexRange
                for (idx, memo) in sorted.enumerated() {
                    let oneIndexed = idx + 1
                    if range.contains(oneIndexed) { ids.insert(memo.id) }
                }
            }
            return ids
        }()

        // メイン画面には格納済み以外だけ表示
        let visible = sorted.filter { !archivedIDs.contains($0.id) }

        let mapped: [StarRenderData] = visible.map { memo in
            let radius = minRadius + (maxRadius - minRadius) * CGFloat(memo.brightness)
            let ec     = Memo.emotionColor(for: memo.emotionHue)
            let jitter = Float.random(in: -0.03 ... 0.03)
            let color  = SIMD3<Float>(
                Float(ec.r) + jitter,
                Float(ec.g) + jitter,
                Float(ec.b) + jitter
            )
            let hasSparkle = memo.brightness > 0.80

            return StarRenderData(
                id:         memo.id,
                position:   memo.starPosition,
                radius:     radius,
                brightness: CGFloat(memo.brightness),
                color:      color,
                type:       .memo,
                hasSparkle: hasSparkle
            )
        }

        memoStars = mapped
        memoIndex = Dictionary(uniqueKeysWithValues: mapped.map { ($0.id, $0) })
    }

    func registerMemo(_ memo: Memo) {
        // ContentView の onChange → syncFromMemos がすぐ上書きする
    }

    func setMemoStars(_ stars: [StarRenderData]) {
        memoStars = stars
        memoIndex = Dictionary(uniqueKeysWithValues: stars.map { ($0.id, $0) })
    }

    // MARK: - Hit testing

    func memoForTap(normalizedPoint: CGPoint,
                    hitRadius: CGFloat = 0.030,
                    memos: [Memo]) -> Memo? {
        func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = a.x - b.x; let dy = a.y - b.y
            return sqrt(dx*dx + dy*dy)
        }
        // メイン画面に表示中のIDのみタップ対象
        let visibleIDs = Set(memoStars.map { $0.id })
        return memos
            .filter { visibleIDs.contains($0.id) }
            .filter { dist($0.starPosition, normalizedPoint) < hitRadius }
            .min(by: { dist($0.starPosition, normalizedPoint) < dist($1.starPosition, normalizedPoint) })
    }

    // MARK: - Background stars

    private func generateBackgroundStars() {
        var stars: [StarRenderData] = []
        stars.reserveCapacity(3500)

        let bandSlope:  CGFloat = 0.70
        let bandOrigin: CGFloat = 0.17
        var attempts = 0

        while stars.count < 2500 && attempts < 18000 {
            attempts += 1
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)

            let bandDist = abs(y - (bandOrigin + bandSlope * x))
            let density  = 0.18 + 0.82 * exp(-pow(bandDist / 0.18, 2.0))
            guard Double.random(in: 0...1) < density else { continue }

            let roll = Double.random(in: 0...1)
            let color: SIMD3<Float>
            let brightness: CGFloat
            let radius: CGFloat

            switch roll {
            case 0..<0.002:
                color = SIMD3<Float>(Float.random(in:0.65...0.75), Float.random(in:0.78...0.88), 1.00)
                brightness = CGFloat.random(in: 0.22...0.40); radius = CGFloat.random(in: 1.4...2.2)
            case 0.002..<0.015:
                color = SIMD3<Float>(Float.random(in:0.74...0.84), Float.random(in:0.85...0.94), 1.00)
                brightness = CGFloat.random(in: 0.16...0.32); radius = CGFloat.random(in: 1.1...1.9)
            case 0.015..<0.055:
                color = SIMD3<Float>(Float.random(in:0.88...0.96), Float.random(in:0.92...0.98), 1.00)
                brightness = CGFloat.random(in: 0.12...0.26); radius = CGFloat.random(in: 0.9...1.7)
            case 0.055..<0.16:
                color = SIMD3<Float>(1.00, Float.random(in:0.93...0.99), Float.random(in:0.80...0.92))
                brightness = CGFloat.random(in: 0.10...0.22); radius = CGFloat.random(in: 0.8...1.5)
            case 0.16..<0.38:
                color = SIMD3<Float>(1.00, Float.random(in:0.88...0.96), Float.random(in:0.68...0.84))
                brightness = CGFloat.random(in: 0.09...0.20); radius = CGFloat.random(in: 0.7...1.35)
            case 0.38..<0.68:
                color = SIMD3<Float>(1.00, Float.random(in:0.74...0.88), Float.random(in:0.48...0.68))
                brightness = CGFloat.random(in: 0.08...0.18); radius = CGFloat.random(in: 0.65...1.25)
            default:
                color = SIMD3<Float>(Float.random(in:0.95...1.00), Float.random(in:0.55...0.72), Float.random(in:0.35...0.52))
                brightness = CGFloat.random(in: 0.06...0.14); radius = CGFloat.random(in: 0.6...1.1)
            }

            let tint = Float.random(in: -0.03...0.03)
            stars.append(StarRenderData(
                id:         UUID(),
                position:   CGPoint(x: x, y: y),
                radius:     radius,
                brightness: brightness,
                color:      SIMD3<Float>(
                    min(max(color.x + tint, 0), 1),
                    min(max(color.y,        0), 1),
                    min(max(color.z - tint, 0), 1)
                ),
                type:       .background,
                hasSparkle: false
            ))
        }
        backgroundStars = stars
    }
}
