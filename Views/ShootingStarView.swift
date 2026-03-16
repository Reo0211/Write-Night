import SwiftUI

// MARK: - 問いリスト

private let thoughtPrompts: [String] = [
    // 寄り添い
    "急がないで、あなたのペースでいいんですよ。",
    "誰かに話せなかったこと、ここに置いていきましょう。",
    "今日のあなたは、昨日のあなたより少し遠くまで来ています。",
    "疲れているときは、無理しなくていいんですよ。",
    "小さなことでも、感じたことは大事なのです。",
    "今日も来てくれたこと、嬉しいです！",
    "完璧じゃなくていい。完璧な人なんていません。",
    "あなたの日常は、あなたにとって一番特別なんです。",
    "どんな気持ちも、感じていることに意味があるんです。",
    "ゆっくりでいい。星は消えずにずっとここにいますから。",
    "今のあなたを、未来のあなたが懐かしむ日が来ます。",
    "あなたしか書けない言葉がある。",
    "こうして宇宙を旅していると、たまに寂しくなるんです。",
    "多くの星を作った人にはいいことがあると聞きました。",
    "次にどんなことができるようになるか、楽しみです！",
    "この宇宙を造った人は、どんどん新しいことを追加していくみたいですよ！",
    "画面を横にすると、時計モードになるらしいですよ！",
    "前回あなたが創った星、私のお気に入りなんです。",
    "私は今日で3221歳になるんです。",
    "思いついた言葉や詩を記録するのもいいですよ！",
    // 提案
    "今日あった小さな出来事を、そのまま言葉にしてみましょう。",
    "あなたの文章、すごく好きです。",
    "誰かに言えなかったその気持ちを、ここに書いてみましょう。",
    "最近うれしかったこと、もう星にしましたか？",
    "今夜の空に、そっと言葉を預けてみてください。",
    "夜は、一日を終わらせる時間じゃなく自分に戻る時間。",
    "ところで、宇宙ってどこまで続いているんでしょうか。",
    "あなたの星は、美しいものばかりですね！",
    "捕まえてくれて嬉しいです！",
    "この宇宙を作った人はさぞ素晴らしんでしょうね。",
    "あなたが造った星たちは皆嬉しそうです。",
    "いつでもここで待ってますからね。",
    "ここはあなたが独り占めできる宇宙なのです。",
]

// MARK: - ShootingStarView

struct ShootingStarView: View {
    let onTapped:   (String) -> Void  // タップ時に「問い」を渡す
    let onMissed:   () -> Void        // 見逃した時

    // 軌道パラメータ（出現時に決定）
    @State private var startPoint: CGPoint = .zero
    @State private var endPoint:   CGPoint = .zero
    @State private var progress:   CGFloat = 0
    @State private var opacity:    Double  = 0
    @State private var trail:      [CGPoint] = []
    @State private var tapped:     Bool    = false
    @State private var screenSize: CGSize  = .zero

    private let duration: Double = 1.8
    private let trailLength = 22
    private let starSize: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if !trail.isEmpty && trail.count >= 2 {
                    // 軌跡
                    Path { path in
                        path.move(to: trail.first!)
                        for pt in trail.dropFirst() { path.addLine(to: pt) }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.55),
                            ],
                            startPoint: UnitPoint(
                                x: trail.first!.x / max(geo.size.width, 1),
                                y: trail.first!.y / max(geo.size.height, 1)
                            ),
                            endPoint: UnitPoint(
                                x: trail.last!.x / max(geo.size.width, 1),
                                y: trail.last!.y / max(geo.size.height, 1)
                            )
                        ),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                    )
                    .blur(radius: 1.0)
                }

                // 光球（タップ領域を広めに）
                let current = currentPosition
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color(red: 0.7, green: 0.88, blue: 1.0).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 18
                            )
                        )
                        .frame(width: 36, height: 36)
                        .blur(radius: 2)

                    Circle()
                        .fill(Color.white)
                        .frame(width: starSize, height: starSize)
                        .shadow(color: .white, radius: 4)
                }
                .position(current)
                .opacity(opacity)
                // タップ領域（見た目より広め）
                .contentShape(Circle().scale(1.5))
                .onTapGesture { handleTap() }
            }
            .onAppear {
                screenSize = geo.size
                setup(in: geo.size)
                animate(in: geo.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(!tapped)
    }

    // MARK: - Position

    private var currentPosition: CGPoint {
        guard startPoint != .zero else { return .zero }
        let t = easeIn(progress)
        return CGPoint(
            x: startPoint.x + (endPoint.x - startPoint.x) * t,
            y: startPoint.y + (endPoint.y - startPoint.y) * t
        )
    }

    private func easeIn(_ t: CGFloat) -> CGFloat { t * t }

    // MARK: - Setup

    private func setup(in size: CGSize) {
        let w = size.width
        let h = size.height

        if Double.random(in: 0...1) < 0.7 {
            // 70%: 画面の辺から辺へ対角線上に横断
            // 開始辺をランダムに選び、対辺の反対側へ向かう
            // t = 辺に沿った位置 (0〜1)
            let t = CGFloat.random(in: 0.1...0.9)
            let side = Int.random(in: 0...3)

            switch side {
            case 0:  // 上辺 → 下辺（右寄りスタート → 左寄りゴール）
                startPoint = CGPoint(x: w * (0.5 + t * 0.5), y: -10)
                endPoint   = CGPoint(x: w * (0.5 - t * 0.5), y: h + 10)
            case 1:  // 右辺 → 左辺
                startPoint = CGPoint(x: w + 10, y: h * t)
                endPoint   = CGPoint(x: -10,    y: h * (1 - t))
            case 2:  // 下辺 → 上辺
                startPoint = CGPoint(x: w * (0.5 + t * 0.5), y: h + 10)
                endPoint   = CGPoint(x: w * (0.5 - t * 0.5), y: -10)
            default: // 左辺 → 右辺
                startPoint = CGPoint(x: -10,    y: h * t)
                endPoint   = CGPoint(x: w + 10, y: h * (1 - t))
            }
        } else {
            // 30%: 従来通り右上→左下
            let startX = CGFloat.random(in: w * 0.3 ... w * 1.1)
            let startY = CGFloat.random(in: -20 ... h * 0.3)
            let length = CGFloat.random(in: w * 0.4 ... w * 0.7)
            let angle  = CGFloat.random(in: 195...225) * .pi / 180

            startPoint = CGPoint(x: startX, y: startY)
            endPoint   = CGPoint(
                x: startX + cos(angle) * length,
                y: startY + sin(angle) * length
            )
        }
    }

    // MARK: - Animation

    private func animate(in size: CGSize) {
        AudioManager.shared.playStarBirth()
        withAnimation(.easeIn(duration: 0.2)) { opacity = 1 }

        let steps = Int(duration * 60)
        for i in 0...steps {
            let delay = Double(i) / 60.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard !tapped else { return }
                progress = CGFloat(i) / CGFloat(steps)
                let pt = currentPosition
                trail.append(pt)
                if trail.count > trailLength { trail.removeFirst() }
            }
        }

        // 見逃し
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard !tapped else { return }
            withAnimation(.easeOut(duration: 0.4)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onMissed()
            }
        }
    }

    // MARK: - Tap

    private func handleTap() {
        guard !tapped else { return }
        tapped = true
        let prompt = thoughtPrompts.randomElement()!

        withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onTapped(prompt)
        }
    }
}

// MARK: - PromptCard（問いカード）

struct PromptCard: View {
    let prompt:     String
    let onClose:    () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 20) {
                // 流れ星アイコン
                Text("流れ星より")
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.30))
                    .tracking(3)

                Text(prompt)
                    .font(.custom("HiraMinProN-W3", size: 17))
                    .foregroundColor(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .tracking(0.5)

                Button { close() } label: {
                    Text("閉じる")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(3)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                    )
            )
            .environment(\.colorScheme, .dark)
            .opacity(opacity)
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { opacity = 1 }
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.25)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onClose() }
    }
}
