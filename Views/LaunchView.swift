import SwiftUI

struct LaunchView: View {
    let onFadeStart: () -> Void   // フェード開始を親に通知
    let onComplete:  () -> Void   // 完全に終わったら親に通知

    @State private var titleOpacity:  Double  = 0
    @State private var titleScale:    CGFloat = 0.96
    @State private var selfOpacity:   Double  = 1.0  // LaunchView全体のフェード
    @State private var stars: [LaunchStar] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── 星たち ────────────────────────────────────────────
            ForEach(stars) { star in
                Circle()
                    .fill(Color.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.opacity)
                    .position(star.position)
                    .blur(radius: star.size > 3 ? 0.8 : 0.3)
                    .shadow(color: .white.opacity(0.8), radius: star.size)
            }

            // ── タイトル ──────────────────────────────────────────
            Text("Write Night")
                .font(.custom("HiraMinProN-W3", size: 26))
                .foregroundColor(.white.opacity(0.88))
                .tracking(8)
                .opacity(titleOpacity)
                .scaleEffect(titleScale)


        }
        .opacity(selfOpacity)
        .onAppear { runSequence() }
    }

    // MARK: - Sequence

    private func runSequence() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height

        // 星を1つずつ瞬きながら出現（0.3〜1.8秒の間）
        let starCount = 60
        for i in 0..<starCount {
            let delay = Double.random(in: 0.2...1.8)
            let x = CGFloat.random(in: 0...screenW)
            let y = CGFloat.random(in: 0...screenH)
            let size = CGFloat.random(in: 1.0...3.8)
            let id = i

            var star = LaunchStar(
                id: id,
                position: CGPoint(x: x, y: y),
                size: size,
                opacity: 0
            )
            stars.append(star)

            // スパイク出現 → 落ち着く
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: Double.random(in: 0.4...1.0))) {
                    stars[id].opacity = Double.random(in: 0.3...0.75)
                }
            }
        }

        // タイトルフェードイン（0.8秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 1.0)) {
                titleOpacity = 1.0
                titleScale   = 1.0
            }
        }

        // タイトルフェードアウト（2.4秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 1.0)) {
                titleOpacity = 0
                titleScale   = 1.03
            }
        }

        // フェードアウト開始（3.6秒後）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            // 親にフェード開始を通知（メイン画面も同時にフェードイン）
            onFadeStart()
            // LaunchView 自身もゆっくりフェードアウト
            withAnimation(.easeInOut(duration: 2.2)) {
                selfOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onComplete()
            }
        }
    }
}

// MARK: - Model

private struct LaunchStar: Identifiable {
    let id:       Int
    let position: CGPoint
    var size:     CGFloat
    var opacity:  Double
}
