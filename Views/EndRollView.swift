import SwiftUI

struct EndRollView: View {
    let memoCount:    Int
    let firstMemoDate: Date?
    let onComplete:   () -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var opacity:      Double  = 0
    @State private var skipOpacity:  Double  = 0

    private let scrollDuration: Double = 60.0

    // ── 詩的テキスト構成
    private var sections: [[String]] {
        let first = firstMemoDate.map { d -> String in
            let f = DateFormatter()
            f.calendar = Calendar(identifier: .gregorian)
            f.locale   = Locale(identifier: "ja_JP")
            f.dateFormat = "yyyy年M月d日"
            return f.string(from: d)
        } ?? ""

        return [
            // 冒頭の詩
            [""],
            [""],
            ["あなたはついに、"],
            ["\(memoCount)個の星を", "夜空に灯しました。"],
            [""],
            ["本当にどの星も美しいものばかりですね。"],
            ["いつも私はあなたの星を眺めていました。"],
            [""],
            [""],
            // ファースト記憶
            first.isEmpty ? [] : ["最初の星が生まれた夜", first],
            first.isEmpty ? [] : [""],
            [""],
            // 感謝の詩
            ["思考は消えない。"],
            ["言葉は残る。"],
            [""],
            ["あなたがここに書いたすべては、"],
            ["宇宙のどこかで"],
            ["静かに輝き続けています。"],
            [""],
            [""],
            ["ここまで来てくれて、"],
            ["ありがとうございます。感極まる思いです。"],
            [""],
            [""],
            [""],
            // クレジット
            ["Write Night"],
            [""],
            ["Developed by"],
            ["A.R.t."],
            [""],
            [""],
            ["夜空はいつまでも続く。"],
            [""],
            [""],
            [""],
        ].filter { !($0.count == 1 && $0[0] == "" && false) }  // 空行は残す
    }

    var body: some View {
        ZStack {
            // 背景：夜空はそのまま透けて見える
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            // スキップボタン
            VStack {
                HStack {
                    Spacer()
                    Button {
                        finish()
                    } label: {
                        Text("スキップ")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(.white.opacity(0.35))
                            .tracking(2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                    }
                    .padding(.top, 52)
                    .padding(.trailing, 24)
                }
                Spacer()
            }
            .opacity(skipOpacity)

            // スクロールテキスト
            GeometryReader { geo in
                let totalHeight = CGFloat(sections.count) * 52 + geo.size.height
                VStack(spacing: 0) {
                    // 下から上へスクロールするためのオフセット
                    Spacer().frame(height: geo.size.height)

                    VStack(spacing: 0) {
                        ForEach(Array(sections.enumerated()), id: \.offset) { _, lines in
                            if lines.isEmpty || (lines.count == 1 && lines[0].isEmpty) {
                                Spacer().frame(height: 52)
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                                        Text(line)
                                            .font(creditFont(for: line))
                                            .foregroundColor(creditColor(for: line))
                                            .tracking(creditTracking(for: line))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.bottom, 52)
                            }
                        }
                    }

                    Spacer().frame(height: geo.size.height * 0.5)
                }
                .frame(maxWidth: .infinity)
                .offset(y: scrollOffset)
            }
            .opacity(opacity)
        }
        .onAppear { start() }
        .ignoresSafeArea()
    }

    // MARK: - Fonts

    private func creditFont(for line: String) -> Font {
        switch line {
        case "Write Night":
            return .custom("HiraMinProN-W6", size: 22)
        case "A.R.t.":
            return .custom("HiraMinProN-W3", size: 16)
        case "Developed by", "夜空はいつまでも続く。":
            return .custom("HiraMinProN-W3", size: 12)
        case let s where s.contains("個の星"):
            return .custom("HiraMinProN-W3", size: 24)
        case "ありがとう。":
            return .custom("HiraMinProN-W6", size: 20)
        default:
            return .custom("HiraMinProN-W3", size: 15)
        }
    }

    private func creditColor(for line: String) -> Color {
        switch line {
        case "Write Night":
            return .white.opacity(0.90)
        case "A.R.t.":
            return Color(red: 0.6, green: 0.82, blue: 1.0).opacity(0.85)
        case "Developed by":
            return .white.opacity(0.30)
        case "ありがとう。":
            return .white.opacity(0.88)
        case let s where s.contains("個の星"):
            return Color(red: 0.75, green: 0.88, blue: 1.0).opacity(0.90)
        case "夜空はいつまでも続く。":
            return .white.opacity(0.40)
        default:
            return .white.opacity(0.60)
        }
    }

    private func creditTracking(for line: String) -> CGFloat {
        switch line {
        case "Developed by": return 3
        case "Write Night":   return 4
        case "夜空はいつまでも続く。": return 2
        default: return 1
        }
    }

    // MARK: - Animation

    private func start() {
        // BGMは既存のものを継続（フェードして再生）
        AudioManager.shared.setVolume(0.25)

        withAnimation(.easeIn(duration: 1.5)) { opacity = 1 }
        withAnimation(.easeIn(duration: 2.0).delay(1.0)) { skipOpacity = 1 }

        let totalScroll = CGFloat(sections.count) * 52 + 200
        withAnimation(.linear(duration: scrollDuration).delay(1.0)) {
            scrollOffset = -totalScroll
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + scrollDuration + 1.0) {
            finish()
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 1.5)) { opacity = 0 }
        AudioManager.shared.setVolume(0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onComplete() }
    }
}
