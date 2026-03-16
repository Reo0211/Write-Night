import SwiftUI
import simd
import Foundation
import Combine

extension Notification.Name {
    static let starBirthSparkle = Notification.Name("starBirthSparkle")
    static let starSupernova    = Notification.Name("starSupernova")
    static let startZoomIn      = Notification.Name("startZoomIn")
}

struct SkyView: View {
    @EnvironmentObject private var memoVM: MemoViewModel
    @EnvironmentObject private var skyVM: SkyViewModel

    @EnvironmentObject private var planetVM: PlanetViewModel
    @EnvironmentObject private var memoryPlanetVM: MemoryPlanetViewModel
    @Binding var selectedMemo: Memo?
    @AppStorage("preferredFPS") private var preferredFPS: Int = 24

    @State private var skySize: CGSize = .zero
    @State private var selectionState: SIMD3<Float> = SIMD3<Float>(0, 0, -1)
    @State private var zoomProgress: Float = 1.0
    @State private var animToken: UUID = UUID()
    @State private var moonShakeOffset: CGFloat = 0

    private let moonRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var moonNormPos: CGPoint {
        guard planetVM.isUnlocked else { return .zero }
        let screen = UIScreen.main.bounds
        let cx = screen.width  * 0.62
        let cy = screen.height * 0.38
        let rx = screen.width  * 0.18
        let ry = screen.height * 0.08
        let t      = Date().timeIntervalSinceReferenceDate
        let angle  = (t / (86400.0 * 3)) * .pi * 2
        let posX = cx + Foundation.cos(angle) * rx
        let posY = cy + Foundation.sin(angle) * ry
        return CGPoint(x: posX / screen.width, y: posY / screen.height)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let screen = UIScreen.main.bounds
                let shakedMoonPos = CGPoint(
                    x: moonNormPos.x,
                    y: moonNormPos.y + moonShakeOffset / screen.height
                )
                MetalStarFieldView(
                    memoStars: skyVM.memoStars,
                    backgroundStars: skyVM.backgroundStars,
                    selectionState: selectionState,
                    zoomProgress: zoomProgress,
                    preferredFPS: preferredFPS,
                    moonNormPos:  shakedMoonPos,
                    moonPhase:    planetVM.activeReminder?.moonPhase ?? 0.0,
                    moonVisible:  planetVM.isUnlocked,
                    memoryPlanets: memoryPlanetVM.unlockedPlanets,
                    planetPositions: memoryPlanetVM.positionCache
                )

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                skySize = geo.size
                                handleTap(at: value.location, in: geo.size)
                            }
                    )
            }
            .onAppear { skySize = geo.size }
            // カードが閉じたらシェーダーをリセット
            .onChange(of: selectedMemo == nil) { isNil in
                if isNil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectionState = SIMD3<Float>(0, 0, -1)
                    }
                }
            }
            // 星誕生スパイク
            .onReceive(NotificationCenter.default.publisher(for: .startZoomIn)) { _ in
                zoomProgress = 0.0
                let start = Date()
                let duration: Float = 2.5
                func tick() {
                    let t = Float(Date().timeIntervalSince(start))
                    zoomProgress = min(t / duration, 1.0)
                    if zoomProgress < 1.0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { tick() }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { tick() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .starBirthSparkle)) { notif in
                guard let sel = notif.object as? SIMD3<Float> else { return }
                selectionState = sel
                // Phase1のきらめきだけ走らせて止める
                let start = Date()
                let duration: Float = 0.6
                func animate() {
                    let elapsed = Float(Date().timeIntervalSince(start))
                    let progress = min(elapsed / duration, 1.0)
                    selectionState = SIMD3<Float>(sel.x, sel.y, progress)
                    if progress < 1.0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { animate() }
                    } else {
                        // きらめき後はリセット（カード表示なし）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectionState = SIMD3<Float>(0, 0, -1)
                        }
                    }
                }
                animate()
            }
            .onReceive(moonRefreshTimer) { _ in
                // moonPhase の変化を Metal に伝えるため再描画トリガー
                animToken = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: .moonShake)) { _ in
                shakeMoon()
            }
        }
    }

    private func shakeMoon() {
        let offsets: [CGFloat] = [0, -6, 5, -4, 3, -2, 1, 0]
        for (i, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.5)) {
                    moonShakeOffset = offset
                }
            }
        }
    }

    private func handleTap(at point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        guard selectionState.z <= 0 || selectionState.z >= 2.0 else { return }

        // 月タップ判定
        if planetVM.isUnlocked {
            let mp = moonNormPos
            let dx = point.x - mp.x * size.width
            let dy = point.y - mp.y * size.height
            if sqrt(dx*dx + dy*dy) < 30 {
                let center = CGPoint(x: mp.x * size.width, y: mp.y * size.height)
                NotificationCenter.default.post(name: .planetTap, object: center)
                let active = planetVM.activeReminders
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    if active.isEmpty {
                        NotificationCenter.default.post(name: .showAddPlanet, object: nil)
                    } else {
                        NotificationCenter.default.post(name: .showPlanetList, object: nil)
                    }
                }
                return
            }
        }

        // 記憶の惑星タップ判定
        let tapNorm = CGPoint(x: Double(point.x / size.width),
                              y: Double(point.y / size.height))
        for planet in memoryPlanetVM.unlockedPlanets {
            let pos = planet.normPosition()
            let dx  = tapNorm.x - pos.x
            let dy  = tapNorm.y - pos.y
            let hitR: Double = (planet == .saturn) ? 0.043 : 0.031
            if (dx * dx + dy * dy).squareRoot() < hitR {
                let center = CGPoint(x: pos.x * size.width, y: pos.y * size.height)
                NotificationCenter.default.post(name: .planetTap, object: center)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    NotificationCenter.default.post(name: .showMemoryPlanet, object: planet)
                }
                return
            }
        }

        let nx = Float(point.x / size.width)
        let ny = Float(1.0 - point.y / size.height)

        let normalized = CGPoint(x: Double(nx), y: Double(ny))
        guard let memo = skyVM.memoForTap(normalizedPoint: normalized,
                                          memos: memoVM.memos) else {
            // 何もない宇宙をタップ → さざ波エフェクト
            NotificationCenter.default.post(name: .spaceRipple, object: point)
            AudioManager.shared.playSpaceRipple()
            return
        }

        // 新トークン発行 → 古いアニメーションループを即時無効化
        let token = UUID()
        animToken = token

        AudioManager.shared.playStarTap()
        selectionState = SIMD3<Float>(nx, ny, 0)
        let sparkDuration = 0.45
        let startTime = Date()

        func animateSparkle() {
            guard animToken == token else { return }   // 古いループは終了
            let elapsed = Float(Date().timeIntervalSince(startTime))
            let progress = min(elapsed / Float(sparkDuration), 1.0)
            selectionState = SIMD3<Float>(nx, ny, progress)

            if progress < 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                    animateSparkle()
                }
            } else {
                let dimStart = Date()
                let dimDuration = 0.35
                func animateDim() {
                    guard animToken == token else { return }   // 古いループは終了
                    let e = Float(Date().timeIntervalSince(dimStart))
                    let p = min(e / Float(dimDuration), 1.0)
                    selectionState = SIMD3<Float>(nx, ny, 1.0 + p)
                    if p < 1.0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                            animateDim()
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedMemo = memo
                        }
                    }
                }
                animateDim()
            }
        }
        animateSparkle()
    }
}
