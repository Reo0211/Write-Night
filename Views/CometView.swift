import SwiftUI

// MARK: - CometView

struct CometView: View {
    let memos:     [Memo]
    let onTapped:  (Memo) -> Void
    let onMissed:  () -> Void

    @State private var startPoint:  CGPoint  = .zero
    @State private var endPoint:    CGPoint  = .zero
    @State private var startTime:   Date?    = nil
    @State private var opacity:     Double   = 0
    @State private var trail:       [CGPoint] = []
    @State private var tapped:      Bool     = false
    @State private var glowPulse:   CGFloat  = 1.0
    @State private var screenSize:  CGSize   = .zero

    private let duration:    Double  = 15
    private let trailLength: Int     = 100
    private let cometSize:   CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                ZStack {
                    let current = position(at: timeline.date, in: geo.size)

                    // ── 尾
                    if trail.count >= 2 {
                        Path { p in
                            p.move(to: trail.first!)
                            trail.dropFirst().forEach { p.addLine(to: $0) }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color(red: 0.6, green: 0, blue: 1.0).opacity(0.08),
                                    Color(red: 0.7, green: 0, blue: 1.0).opacity(0.30),
                                    Color.white.opacity(0.65),
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
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                        )
                        .blur(radius: 1.5)
                    }

                    // ── 核
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0, blue: 1.0).opacity(0.35),
                                        Color.clear
                                    ],
                                    center: .center, startRadius: 0, endRadius: 28
                                )
                            )
                            .frame(width: 56, height: 56)
                            .scaleEffect(glowPulse)
                            .blur(radius: 3)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.9), Color.clear],
                                    center: .center, startRadius: 0, endRadius: 14
                                )
                            )
                            .frame(width: 28, height: 28)
                            .blur(radius: 2)

                        Circle()
                            .fill(Color.white)
                            .frame(width: cometSize, height: cometSize)
                            .shadow(color: Color(red: 0.7, green: 0.9, blue: 1.0), radius: 6)
                    }
                    .position(current)
                    .opacity(opacity)
                    .contentShape(Circle().scale(3.0))
                    .onTapGesture { handleTap(at: current) }
                }
                .onChange(of: timeline.date) { date in
                    guard !tapped, startTime != nil else { return }
                    let pt = position(at: date, in: geo.size)
                    trail.append(pt)
                    if trail.count > trailLength { trail.removeFirst() }

                    let elapsed = date.timeIntervalSince(startTime!)
                    if elapsed >= duration {
                        withAnimation(.easeOut(duration: 0.8)) { opacity = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onMissed() }
                    }
                }
            }
            .onAppear {
                screenSize = geo.size
                setup(in: geo.size)
                startTime = Date()
                AudioManager.shared.playStarBirth()
                withAnimation(.easeIn(duration: 0.5)) { opacity = 1 }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowPulse = 1.35
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(!tapped)
    }

    // MARK: - Position（毎フレームDate基準で計算）

    private func position(at date: Date, in size: CGSize) -> CGPoint {
        guard let start = startTime, startPoint != .zero else { return .zero }
        let elapsed  = CGFloat(date.timeIntervalSince(start))
        let t        = min(elapsed / CGFloat(duration), 1.0)
        let eased    = easeInOut(t)
        return CGPoint(
            x: startPoint.x + (endPoint.x - startPoint.x) * eased,
            y: startPoint.y + (endPoint.y - startPoint.y) * eased
        )
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }

    // MARK: - Setup

    private func setup(in size: CGSize) {
        let w = size.width, h = size.height
        let t = CGFloat.random(in: 0.2...0.6)
        startPoint = CGPoint(x: w * (0.5 + t * 0.6), y: -20)
        endPoint   = CGPoint(x: w * (0.1 - t * 0.1), y: h * (0.6 + t * 0.4))
    }

    // MARK: - Tap

    private func handleTap(at point: CGPoint) {
        guard !tapped, let memo = memos.randomElement() else { return }
        tapped = true
        withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onTapped(memo) }
    }
}

// MARK: - CometMemoryCard（懐古カード）

struct CometMemoryCard: View {
    let memo:    Memo
    let onClose: () -> Void

    @State private var opacity: Double = 0

    private var dateStr: String {
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.locale     = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f.string(from: memo.createdAt)
    }

    private var emotionColor: Color {
        let c = Memo.emotionColor(for: memo.emotionHue)
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear.ignoresSafeArea().onTapGesture { close() }

            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 6) {
                    Text("懐古の彗星より")
                        .font(.custom("HiraMinProN-W3", size: 11))
                        .foregroundColor(.white.opacity(0.28))
                        .tracking(3)

                    Text(dateStr)
                        .font(.custom("HiraMinProN-W3", size: 12))
                        .foregroundColor(emotionColor.opacity(0.65))
                        .tracking(1)
                }

                // 区切り
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)

                // メモ本文
                VStack(alignment: .leading, spacing: 8) {
                    if !memo.title.isEmpty {
                        Text(memo.title)
                            .font(.custom("HiraMinProN-W6", size: 16))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                    if !memo.body.isEmpty {
                        Text(memo.body)
                            .font(.custom("HiraMinProN-W3", size: 14))
                            .foregroundColor(.white.opacity(0.60))
                            .lineSpacing(5)
                            .lineLimit(6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 星のグロー装飾
                HStack {
                    Circle()
                        .fill(emotionColor.opacity(0.6))
                        .frame(width: 5, height: 5)
                        .shadow(color: emotionColor.opacity(0.9), radius: 4)
                    Spacer()
                    Button { close() } label: {
                        Text("閉じる")
                            .font(.custom("HiraMinProN-W3", size: 13))
                            .foregroundColor(.white.opacity(0.32))
                            .tracking(3)
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(emotionColor.opacity(0.06))
            )
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .opacity(0.90)
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { opacity = 1 }
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.25)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onClose() }
    }
}
