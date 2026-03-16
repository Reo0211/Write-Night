import SwiftUI

// MARK: - PlanetFormationOverlay

struct PlanetFormationOverlay: View {
    let planet:     MemoryPlanetType
    let memos:      [Memo]          // 格納されるメモ（色情報に使う）
    let onComplete: () -> Void

    // アニメーションステージ
    // 0: 星が散らばっている
    // 1: 星が中心へ収束
    // 2: フラッシュ → 惑星出現
    // 3: フェードアウト
    @State private var stage:       Int     = 0
    @State private var particles:   [StarParticle] = []
    @State private var burstScale:  CGFloat = 0
    @State private var burstOpacity: Double = 0
    @State private var planetScale: CGFloat = 0
    @State private var planetOpacity: Double = 0
    @State private var bgOpacity:   Double  = 0
    @State private var selfOpacity: Double  = 1

    private var baseColor: Color {
        let c = planet.metalColor
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.46)

            ZStack {
                // 背景暗転
                Color.black
                    .opacity(bgOpacity)
                    .ignoresSafeArea()

                // ── 星粒子
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .shadow(color: p.color.opacity(0.8), radius: p.size)
                        .position(p.position)
                        .opacity(p.opacity)
                }

                // ── 収束フラッシュ
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                baseColor.opacity(0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(burstScale)
                    .opacity(burstOpacity)
                    .position(center)
                    .blur(radius: 6)

                // ── 惑星
                ZStack {
                    // グロー
                    Circle()
                        .fill(baseColor.opacity(0.22))
                        .frame(width: 80, height: 80)
                        .blur(radius: 14)

                    // 球体
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    baseColor.opacity(0.95),
                                    baseColor.opacity(0.55),
                                    baseColor.opacity(0.20)
                                ],
                                center: UnitPoint(x: 0.36, y: 0.34),
                                startRadius: 2,
                                endRadius: 24
                            )
                        )
                        .frame(width: 46, height: 46)
                        .shadow(color: baseColor.opacity(0.6), radius: 10)

                    // 土星リング
                    if planet == .saturn {
                        Ellipse()
                            .stroke(
                                LinearGradient(
                                    colors: [baseColor.opacity(0.7), baseColor.opacity(0.2), baseColor.opacity(0.6)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                lineWidth: 6
                            )
                            .frame(width: 76, height: 24)
                            .opacity(0.75)
                    }
                }
                .scaleEffect(planetScale)
                .opacity(planetOpacity)
                .position(center)

                // ── 惑星名ラベル
                Text(planet.displayName)
                    .font(.custom("HiraMinProN-W3", size: 14))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(3)
                    .opacity(planetOpacity)
                    .position(x: center.x, y: center.y + 52)
            }
            .opacity(selfOpacity)
            .onAppear {
                setupParticles(in: geo.size, center: center)
                runAnimation(center: center)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Setup

    private func setupParticles(in size: CGSize, center: CGPoint) {
        let count = min(max(memos.count, 8), 40)
        particles = (0..<count).map { i in
            // 散らばった初期位置（画面全体にランダム）
            let x = CGFloat.random(in: size.width * 0.1 ... size.width * 0.9)
            let y = CGFloat.random(in: size.height * 0.1 ... size.height * 0.8)

            // メモの感情色を使う（あれば）
            let hue  = i < memos.count ? memos[i].emotionHue : Double.random(in: 0...1)
            let ec   = Memo.emotionColor(for: hue)
            let color = Color(red: ec.r, green: ec.g, blue: ec.b)

            return StarParticle(
                id:       i,
                position: CGPoint(x: x, y: y),
                target:   center,
                color:    color,
                size:     CGFloat.random(in: 3...6),
                opacity:  0,
                delay:    Double.random(in: 0...0.4)
            )
        }
    }

    // MARK: - Animation sequence

    private func runAnimation(center: CGPoint) {
        // 0. 背景暗転
        withAnimation(.easeIn(duration: 0.5)) { bgOpacity = 0.85 }

        // 1. 星を出現させる
        for i in particles.indices {
            let delay = particles[i].delay
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                particles[i].opacity = Double.random(in: 0.6...1.0)
            }
        }

        // 2. 収束（0.8秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            for i in particles.indices {
                withAnimation(.easeIn(duration: 0.7).delay(Double(i) * 0.015)) {
                    particles[i].position = CGPoint(
                        x: center.x + CGFloat.random(in: -4...4),
                        y: center.y + CGFloat.random(in: -4...4)
                    )
                    particles[i].size    = 2
                    particles[i].opacity = 0.9
                }
            }
        }

        // 3. フラッシュ + 惑星出現（1.8秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            // 星を消す
            for i in particles.indices {
                withAnimation(.easeOut(duration: 0.15)) {
                    particles[i].opacity = 0
                }
            }
            // バースト
            withAnimation(.easeOut(duration: 0.2)) {
                burstScale   = 1.0
                burstOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.15)) {
                burstOpacity = 0
            }
            // 惑星ポップイン
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.1)) {
                planetScale   = 1.0
                planetOpacity = 1.0
            }
        }

        // 4. フェードアウト（3.2秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                selfOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete()
            }
        }
    }
}

// MARK: - StarParticle model

private struct StarParticle: Identifiable {
    let id:    Int
    var position: CGPoint
    let target:   CGPoint
    let color:    Color
    var size:     CGFloat
    var opacity:  Double
    let delay:    Double
}
