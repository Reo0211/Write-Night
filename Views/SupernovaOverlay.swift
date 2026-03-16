import SwiftUI

struct SupernovaOverlay: View {
    let center: CGPoint
    let onComplete: () -> Void

    // フラッシュ
    @State private var flashOpacity: Double = 0
    // 爆発リング（複数）
    @State private var rings: [RingState] = []
    // スパーク粒子
    @State private var sparks: [SparkState] = []

    var body: some View {
        ZStack {
            // ── 画面フラッシュ ────────────────────────────────────
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── 爆発リング ────────────────────────────────────────
            ForEach(rings) { ring in
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: ring.r, green: ring.g, blue: ring.b)
                                    .opacity(ring.opacity * 0.9),
                                Color(red: ring.r, green: ring.g, blue: ring.b)
                                    .opacity(ring.opacity * 0.3),
                                Color.white.opacity(ring.opacity * 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(0.5, ring.lineWidth * (1 - ring.progress))
                    )
                    .frame(
                        width:  ring.radiusX * ring.progress * 2,
                        height: ring.radiusY * ring.progress * 2
                    )
                    .rotationEffect(.degrees(ring.rotation))
                    .opacity(ring.opacity)
                    .position(center)
                    .blur(radius: ring.blur)
            }

            // ── スパーク粒子 ──────────────────────────────────────
            ForEach(sparks) { spark in
                Circle()
                    .fill(Color(red: spark.r, green: spark.g, blue: spark.b))
                    .frame(width: spark.size, height: spark.size)
                    .opacity(spark.opacity)
                    .position(spark.position)
                    .blur(radius: 2.5)
            }
        }
        .onAppear { runAnimation() }
    }

    // MARK: - Animation

    private func runAnimation() {
        // リング定義（サイズ・色・傾き・遅延）
        // リング2つ、小さめ、長く持続してゆっくり消える
        let ringDefs: [(rx: CGFloat, ry: CGFloat, r: Double, g: Double, b: Double, rot: Double, delay: Double, expandDur: Double, holdDur: Double, fadeDur: Double, blur: CGFloat, lw: CGFloat)] = [
            // メインリング（白）
            (rx: 95,  ry: 60,  r: 1.0, g: 1.0,  b: 1.0,  rot: -8,  delay: 0.05, expandDur: 0.25, holdDur: 0.8, fadeDur: 1.0, blur: 2.0, lw: 3.0),
            // 青白リング
            (rx: 130, ry: 80,  r: 0.7, g: 0.88, b: 1.0,  rot: 12,  delay: 0.0,  expandDur: 0.32, holdDur: 0.6, fadeDur: 1.2, blur: 2.5, lw: 2.0),
        ]

        for (i, def) in ringDefs.enumerated() {
            let ring = RingState(
                id: i,
                radiusX: def.rx, radiusY: def.ry,
                r: def.r, g: def.g, b: def.b,
                rotation: def.rot,
                blur: def.blur,
                lineWidth: def.lw,
                progress: 0, opacity: 0
            )
            rings.append(ring)

            DispatchQueue.main.asyncAfter(deadline: .now() + def.delay) {
                // 拡張
                withAnimation(.easeOut(duration: def.expandDur)) {
                    rings[i].progress = 1.0
                }
                // フェードイン
                withAnimation(.easeOut(duration: 0.12)) {
                    rings[i].opacity = 1.0
                }
                // hold後にゆっくりフェードアウト
                DispatchQueue.main.asyncAfter(deadline: .now() + def.expandDur + def.holdDur) {
                    withAnimation(.easeInOut(duration: def.fadeDur)) {
                        rings[i].opacity = 0
                    }
                }
            }
        }

        // フラッシュ
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.55 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeIn(duration: 0.25)) { flashOpacity = 0 }
        }

        // スパーク粒子
        let sparkCount = 16
        for i in 0..<sparkCount {
            let angle = Double(i) / Double(sparkCount) * .pi * 2
            let speed = Double.random(in: 60...140)
            let spark = SparkState(
                id: i,
                position: center,
                r: [1.0,  1.0,  0.85][i % 3],
                g: [0.95, 0.75, 0.95][i % 3],
                b: [0.7,  0.5,  1.0 ][i % 3],
                size: CGFloat.random(in: 3...7),
                opacity: 1.0
            )
            sparks.append(spark)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let dur = Double.random(in: 0.5...0.9)
                withAnimation(.easeOut(duration: dur)) {
                    sparks[i].position = CGPoint(
                        x: center.x + cos(angle) * speed,
                        y: center.y + sin(angle) * speed
                    )
                    sparks[i].size *= 0.4
                }
                withAnimation(.easeIn(duration: dur * 0.6).delay(dur * 0.4)) {
                    sparks[i].opacity = 0
                }
            }
        }

        // 完了コールバック
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            onComplete()
        }
    }
}

// MARK: - State Models

private struct RingState: Identifiable {
    let id:        Int
    let radiusX:   CGFloat
    let radiusY:   CGFloat
    let r, g, b:   Double
    let rotation:  Double
    let blur:      CGFloat
    let lineWidth: CGFloat
    var progress:  CGFloat
    var opacity:   Double
}

private struct SparkState: Identifiable {
    let id:    Int
    var position: CGPoint
    let r, g, b: Double
    var size:  CGFloat
    var opacity: Double
}
