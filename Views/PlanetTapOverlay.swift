import SwiftUI

/// 惑星・月タップ時の十字閃光 + 拡散リングエフェクト
struct PlanetTapOverlay: View {
    let position: CGPoint
    let onComplete: () -> Void

    @State private var ringScale:    CGFloat = 0.1
    @State private var ringOpacity:  Double  = 0.9
    @State private var ring2Scale:   CGFloat = 0.1
    @State private var ring2Opacity: Double  = 0.6
    @State private var crossScale:   CGFloat = 0.3
    @State private var crossOpacity: Double  = 0.0
    @State private var glowOpacity:  Double  = 0.0

    var body: some View {
        // フルスクリーン展開し、内部を一か所で position 指定
        ZStack(alignment: .topLeading) {
            // エフェクトをまとめた単一ZStack → position 1回だけ
            ZStack {
                // ── 外リング
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(ring2Scale)
                    .opacity(ring2Opacity)
                    .blur(radius: 0.5)

                // ── 内リング
                Circle()
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .blur(radius: 0.8)

                // ── 中心グロー
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.9), Color.clear],
                            center: .center, startRadius: 0, endRadius: 18
                        )
                    )
                    .frame(width: 36, height: 36)
                    .opacity(glowOpacity)
                    .blur(radius: 2)

                // ── 十字閃光
                CrossFlash()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 100, height: 100)
                    .scaleEffect(crossScale)
                    .opacity(crossOpacity)
                    .blur(radius: 0.8)
            }
            .position(position)  // ← 1か所だけ
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { run() }
    }

    private func run() {
        AudioManager.shared.playPlanetTap()

        // 中心グロー
        withAnimation(.easeOut(duration: 0.12)) { glowOpacity = 1.0 }
        withAnimation(.easeIn(duration: 0.25).delay(0.12)) { glowOpacity = 0.0 }

        // 十字閃光：素早く展開してフェード
        withAnimation(.easeOut(duration: 0.15)) {
            crossOpacity = 1.0
            crossScale   = 1.0
        }
        withAnimation(.easeIn(duration: 0.35).delay(0.15)) {
            crossOpacity = 0.0
            crossScale   = 1.4
        }

        // 内リング
        withAnimation(.easeOut(duration: 0.55)) {
            ringScale   = 1.0
            ringOpacity = 0.0
        }

        // 外リング（少し遅らせる）
        withAnimation(.easeOut(duration: 0.6).delay(0.08)) {
            ring2Scale   = 1.0
            ring2Opacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onComplete() }
    }
}

// MARK: - CrossFlash Shape

private struct CrossFlash: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx   = rect.midX
        let cy   = rect.midY
        let len  = rect.width / 2      // スパイクの長さ
        let half = rect.width * 0.028  // スパイクの根元の幅（半分）
        let gap  = rect.width * 0.10   // 中心からの隙間

        // 上
        p.addLines([
            CGPoint(x: cx - half, y: cy - gap),
            CGPoint(x: cx,        y: cy - len),
            CGPoint(x: cx + half, y: cy - gap),
        ])
        p.closeSubpath()

        // 下
        p.addLines([
            CGPoint(x: cx - half, y: cy + gap),
            CGPoint(x: cx,        y: cy + len),
            CGPoint(x: cx + half, y: cy + gap),
        ])
        p.closeSubpath()

        // 左
        p.addLines([
            CGPoint(x: cx - gap, y: cy - half),
            CGPoint(x: cx - len, y: cy),
            CGPoint(x: cx - gap, y: cy + half),
        ])
        p.closeSubpath()

        // 右
        p.addLines([
            CGPoint(x: cx + gap, y: cy - half),
            CGPoint(x: cx + len, y: cy),
            CGPoint(x: cx + gap, y: cy + half),
        ])
        p.closeSubpath()

        return p
    }
}
