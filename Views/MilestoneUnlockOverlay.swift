import SwiftUI

// MARK: - MilestoneUnlockOverlay

struct MilestoneUnlockOverlay: View {
    let kind:       MilestoneKind
    let onComplete: () -> Void

    @State private var phase:       Int    = 0   // 0:暗転 1:テキスト 2:デモ 3:フェードアウト
    @State private var bgOpacity:   Double = 0
    @State private var textOpacity: Double = 0
    @State private var demoOpacity: Double = 0
    @State private var selfOpacity: Double = 1

    var body: some View {
        ZStack {
            Color.black
                .opacity(bgOpacity)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // ── ヘッドライン
                VStack(spacing: 16) {
                    Text(kind.unlockHeadline)
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(4)

                    Text(kind.unlockTitle)
                        .font(.custom("HiraMinProN-W3", size: 22))
                        .foregroundColor(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .lineSpacing(9)
                        .tracking(1)
                        .padding(.horizontal, 36)

                    if let body = kind.unlockBody {
                        Text(body)
                            .font(.custom("HiraMinProN-W3", size: 13))
                            .foregroundColor(.white.opacity(0.40))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 44)
                    }
                }
                .opacity(textOpacity)

                Spacer().frame(height: 12)

                // ── 種別固有デモ
                Group {
                    switch kind {
                    case .emotionColor:
                        EmotionColorDemo()
                    case .shootingStar:
                        ShootingStarDemo()
                    case .reminderMoon:
                        MoonDemo()
                    case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune:
                        if let planet = MemoryPlanetType.allCases.first(where: { $0.milestonekind == kind }) {
                            MemoryPlanetDemo(planet: planet)
                        }
                    case .comet:
                        CometDemo()
                    default:
                        EmptyView()
                    }
                }
                .opacity(demoOpacity)

                Spacer()

                // ── ボタン
                Button { finish() } label: {
                    Text("はじめる")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .tracking(4)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                }
                .opacity(textOpacity)
                .padding(.bottom, 64)
            }
        }
        .opacity(selfOpacity)
        .onAppear { runSequence() }
    }

    // MARK: - Sequence

    private func runSequence() {
        // 暗転
        withAnimation(.easeIn(duration: 0.4)) { bgOpacity = 0.92 }
        // テキスト
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 1.0)) { textOpacity = 1 }
        }
        // デモ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.8)) { demoOpacity = 1 }
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.6)) {
            textOpacity = 0
            demoOpacity = 0
            bgOpacity   = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onComplete() }
    }
}

// MARK: - EmotionColorDemo（感情色のデモUI）

private struct EmotionColorDemo: View {
    @State private var hue: Double = 0.5
    @State private var autoMove = true

    private let gradientColors: [Color] = [
        Color(red: 0.08, green: 0.12, blue: 0.55),
        Color(red: 0.16, green: 0.38, blue: 0.72),
        Color(red: 0.52, green: 0.55, blue: 0.65),
        Color(red: 0.62, green: 0.50, blue: 0.20),
        Color(red: 0.62, green: 0.24, blue: 0.16),
    ]

    private var starColor: Color {
        let c = Memo.emotionColor(for: hue)
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    private var emotionLabel: String {
        switch hue {
        case 0.0..<0.15: return "悲しみ"
        case 0.15..<0.35: return "穏やか"
        case 0.35..<0.65: return "平静"
        case 0.65..<0.85: return "喜び"
        default:           return "興奮"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // 星プレビュー
            ZStack {
                Circle()
                    .fill(starColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .blur(radius: 12)
                Circle()
                    .fill(starColor.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .shadow(color: starColor.opacity(0.9), radius: 6)
            }
            .animation(.easeInOut(duration: 0.4), value: hue)

            Text(emotionLabel)
                .font(.custom("HiraMinProN-W3", size: 13))
                .foregroundColor(.white.opacity(0.55))
                .animation(.easeInOut(duration: 0.3), value: emotionLabel)

            // カラーバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 36)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    let x = hue * geo.size.width
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.35), radius: 4)
                        Circle()
                            .fill(starColor.opacity(0.7))
                            .frame(width: 14, height: 14)
                    }
                    .position(x: max(14, min(geo.size.width - 14, x)),
                              y: 18)
                    .animation(.easeInOut(duration: 0.3), value: hue)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            autoMove = false
                            hue = max(0, min(1, Double(v.location.x / geo.size.width)))
                        }
                )
            }
            .frame(height: 36)
        }
        .padding(.horizontal, 44)
        .onAppear { startAutoMove() }
    }

    private func startAutoMove() {
        guard autoMove else { return }
        withAnimation(.easeInOut(duration: 2.5)) { hue = 0.9 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard autoMove else { return }
            withAnimation(.easeInOut(duration: 2.5)) { hue = 0.1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                guard autoMove else { return }
                startAutoMove()
            }
        }
    }
}

// MARK: - ShootingStarDemo

private struct ShootingStarDemo: View {
    @State private var progress: CGFloat = 0
    @State private var opacity:  Double  = 0
    @State private var trail:    [CGPoint] = []
    @State private var promptVisible: Bool = false
    @State private var loopCount: Int = 0

    private let canvasW: CGFloat = 280
    private let canvasH: CGFloat = 120
    private let startPt = CGPoint(x: 260, y: 10)
    private let endPt   = CGPoint(x: 30,  y: 100)
    private let trailLen = 18

    private var current: CGPoint {
        let t = progress * progress   // ease-in
        return CGPoint(
            x: startPt.x + (endPt.x - startPt.x) * t,
            y: startPt.y + (endPt.y - startPt.y) * t
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // 軌跡
                if trail.count >= 2 {
                    Path { p in
                        p.move(to: trail.first!)
                        trail.dropFirst().forEach { p.addLine(to: $0) }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0), .white.opacity(0.18), .white.opacity(0.6)],
                            startPoint: .init(x: trail.first!.x / canvasW, y: trail.first!.y / canvasH),
                            endPoint:   .init(x: trail.last!.x  / canvasW, y: trail.last!.y  / canvasH)
                        ),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                    )
                    .blur(radius: 1)
                }

                // 光球
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [.white.opacity(0.9),
                                     Color(red: 0.7, green: 0.88, blue: 1.0).opacity(0.35),
                                     .clear],
                            center: .center, startRadius: 0, endRadius: 18
                        ))
                        .frame(width: 32, height: 32)
                        .blur(radius: 2)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .shadow(color: .white, radius: 3)
                }
                .position(current)
                .opacity(opacity)
            }
            .frame(width: canvasW, height: canvasH)
            .clipped()

            // タップヒント
            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.30))
                Text("流れ星をタップして捕まえよう")
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .opacity(promptVisible ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: promptVisible)
        }
        .onAppear { runLoop() }
    }

    private func runLoop() {
        trail = []
        progress = 0
        opacity  = 0
        promptVisible = false

        withAnimation(.easeIn(duration: 0.15)) { opacity = 1 }

        let steps = Int(1.4 * 60)
        for i in 0...steps {
            let delay = Double(i) / 60.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                progress = CGFloat(i) / CGFloat(steps)
                let pt = current
                trail.append(pt)
                if trail.count > trailLen { trail.removeFirst() }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            withAnimation(.easeOut(duration: 0.4)) { opacity = 0 }
            promptVisible = true
        }

        // ループ（2回まで自動、以降は静止）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            loopCount += 1
            if loopCount < 2 { runLoop() }
        }
    }
}

// MARK: - CometDemo

private struct CometDemo: View {
    @State private var progress:  CGFloat = 0
    @State private var opacity:   Double  = 0
    @State private var trail:     [CGPoint] = []
    @State private var glowPulse: CGFloat = 1.0
    @State private var loopCount: Int = 0

    private let canvasW: CGFloat = 280
    private let canvasH: CGFloat = 130
    private let startPt  = CGPoint(x: 265, y: 10)
    private let endPt    = CGPoint(x: 30,  y: 115)
    private let trailLen = 40
    private let duration: Double = 2.8

    private var current: CGPoint {
        let t = progress < 0.5 ? 2 * progress * progress : -1 + (4 - 2 * progress) * progress
        return CGPoint(
            x: startPt.x + (endPt.x - startPt.x) * t,
            y: startPt.y + (endPt.y - startPt.y) * t
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // 尾
                if trail.count >= 2 {
                    Path { p in
                        p.move(to: trail.first!)
                        trail.dropFirst().forEach { p.addLine(to: $0) }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(red: 0.6, green: 0.85, blue: 1.0).opacity(0.15),
                                Color.white.opacity(0.55),
                            ],
                            startPoint: .init(x: trail.first!.x / canvasW, y: trail.first!.y / canvasH),
                            endPoint:   .init(x: trail.last!.x  / canvasW, y: trail.last!.y  / canvasH)
                        ),
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
                    )
                    .blur(radius: 1.2)
                }

                // 核
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(red: 0.6, green: 0.88, blue: 1.0).opacity(0.35), Color.clear],
                            center: .center, startRadius: 0, endRadius: 22
                        ))
                        .frame(width: 44, height: 44)
                        .scaleEffect(glowPulse)
                        .blur(radius: 3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .shadow(color: Color(red: 0.7, green: 0.9, blue: 1.0), radius: 5)
                }
                .position(current)
                .opacity(opacity)
            }
            .frame(width: canvasW, height: canvasH)
            .clipped()

            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.30))
                Text("彗星をタップして過去の記憶を呼び覚ます")
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                glowPulse = 1.3
            }
            runLoop()
        }
    }

    private func runLoop() {
        trail = []
        progress = 0
        opacity  = 0

        withAnimation(.easeIn(duration: 0.4)) { opacity = 1 }

        let steps = Int(duration * 60)
        for i in 0...steps {
            let delay = Double(i) / 60.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                progress = CGFloat(i) / CGFloat(steps)
                let pt = current
                trail.append(pt)
                if trail.count > trailLen { trail.removeFirst() }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            withAnimation(.easeOut(duration: 0.5)) { opacity = 0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.8) {
            loopCount += 1
            if loopCount < 3 { runLoop() }
        }
    }
}

// MARK: - MoonDemo

private struct MoonDemo: View {
    @State private var phase:   Double = 1.0
    @State private var reverse: Bool   = false

    var body: some View {
        VStack(spacing: 20) {
            // 月の満ち欠けプレビュー
            ZStack {
                // グロー
                Circle()
                    .fill(Color(red: 1.0, green: 0.95, blue: 0.75).opacity(0.15 * phase))
                    .frame(width: 72, height: 72)
                    .blur(radius: 12)

                MoonPhaseShape(phase: phase)
                    .frame(width: 44, height: 44)
            }
            .animation(.easeInOut(duration: 0.4), value: phase)

            // フェーズラベル
            Text(phaseLabel)
                .font(.custom("HiraMinProN-W3", size: 12))
                .foregroundColor(phaseColor.opacity(0.70))
                .tracking(0.5)
                .animation(.easeInOut(duration: 0.3), value: phaseLabel)

            // 説明
            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.28))
                Text("月をタップしてリマインダーを設定")
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.32))
            }
        }
        .onAppear { animatePhase() }
    }

    private var phaseLabel: String {
        switch phase {
        case 0.85...1.0: return "満月　作成直後"
        case 0.6..<0.85: return "上弦の月　まだ余裕あり"
        case 0.35..<0.6: return "半月　中間地点"
        case 0.15..<0.35: return "三日月　期限が近い"
        default:          return "新月　もうすぐ期限"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case 0.0..<0.2: return Color(red: 1.0, green: 0.5, blue: 0.3)
        case 0.2..<0.5: return Color(red: 0.9, green: 0.8, blue: 0.5)
        default:        return Color(red: 0.7, green: 0.85, blue: 1.0)
        }
    }

    private func animatePhase() {
        let target: Double = reverse ? 1.0 : 0.05
        withAnimation(.easeInOut(duration: 2.8)) { phase = target }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            reverse.toggle()
            animatePhase()
        }
    }
}

// MARK: - MemoryPlanetDemo

private struct MemoryPlanetDemo: View {
    let planet: MemoryPlanetType

    @State private var orbitAngle: Double = 0
    @State private var glowScale:  CGFloat = 1.0
    @State private var starOpacity: [Double] = Array(repeating: 0, count: 5)

    private var baseColor: Color {
        let c = planet.metalColor
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }

    // ダミースター（感情色）
    private let starHues: [Double] = [0.1, 0.35, 0.5, 0.72, 0.9]

    var body: some View {
        VStack(spacing: 28) {

            // ── 軌道 + 惑星 + 周回する星たち
            ZStack {
                // 軌道楕円
                Ellipse()
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    .frame(width: 200, height: 70)

                // 周回する小さな星（5個）
                ForEach(0..<5, id: \.self) { i in
                    let angle = orbitAngle + Double(i) * (360.0 / 5.0)
                    let rad   = angle * .pi / 180
                    let rx: Double = 100
                    let ry: Double = 35
                    let x = cos(rad) * rx
                    let y = sin(rad) * ry
                    let hue   = starHues[i]
                    let col   = Memo.emotionColor(for: hue)
                    let color = Color(red: col.r, green: col.g, blue: col.b)

                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .shadow(color: color.opacity(0.9), radius: 3)
                        .offset(x: x, y: y)
                        .opacity(starOpacity[i])
                }

                // 惑星本体
                ZStack {
                    // 外周グロー
                    Circle()
                        .fill(baseColor.opacity(0.18))
                        .frame(width: 54, height: 54)
                        .blur(radius: 10)
                        .scaleEffect(glowScale)

                    // 球体（グラデーションで立体感）
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    baseColor.opacity(0.95),
                                    baseColor.opacity(0.55),
                                    baseColor.opacity(0.25)
                                ],
                                center: UnitPoint(x: 0.38, y: 0.35),
                                startRadius: 2,
                                endRadius: 18
                            )
                        )
                        .frame(width: 34, height: 34)
                        .shadow(color: baseColor.opacity(0.5), radius: 6)

                    // 土星リング
                    if planet == .saturn {
                        Ellipse()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        baseColor.opacity(0.6),
                                        baseColor.opacity(0.2),
                                        baseColor.opacity(0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 5
                            )
                            .frame(width: 58, height: 18)
                            .opacity(0.7)
                    }
                }
            }
            .frame(width: 240, height: 100)

            // ── 格納メモ数のヒント
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.25))
                Text("\(planet.memoIndexRange.lowerBound)〜\(planet.memoIndexRange.upperBound)番目の星が宿っています")
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundColor(.white.opacity(0.32))
            }
        }
        .onAppear {
            // 軌道回転
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                orbitAngle = 360
            }
            // グロー呼吸
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowScale = 1.25
            }
            // 星を順番にフェードイン
            for i in 0..<5 {
                withAnimation(.easeIn(duration: 0.4).delay(Double(i) * 0.15)) {
                    starOpacity[i] = 1.0
                }
            }
        }
    }
}

// MARK: - MilestoneKind extensions

extension MilestoneKind {
    var unlockHeadline: String {
        switch self {
        case .emotionColor:  return "新しい機能が解放されました"
        case .shootingStar:  return "新しい現象が解放されました"
        case .reminderMoon:  return "新しい天体が解放されました"
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune:
                             return "記憶の惑星が解放されました"
        case .comet:         return "新しい現象が解放されました"
        case .endroll:       return "新しい現象が解放されました"
        }
    }

    var unlockTitle: String {
        switch self {
        case .emotionColor:  return "星に、色が宿った。"
        case .shootingStar:  return "夜空を、流れ星が横切る。"
        case .reminderMoon:  return "想起の月が、昇り始めた。"
        case .mercury:       return "水星が、夜空に灯った。"
        case .venus:         return "金星が、現れた。"
        case .mars:          return "火星が、静かに燃えている。"
        case .jupiter:       return "木星が、大きく輝く。"
        case .saturn:        return "土星が、環をまとって現れた。"
        case .uranus:        return "天王星が、遠くに光る。"
        case .neptune:       return "海王星が、深く蒼く輝く。"
        case .comet:         return "懐古の彗星が、飛び込んできた。"
        case .endroll:       return ""
        }
    }

    var unlockBody: String? { nil }
}
