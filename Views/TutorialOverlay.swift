import SwiftUI

// MARK: - Step

private struct TutorialStep {
    let title:    String        // 詩的な一行
    let body:     String?       // 補足説明
}

private let tutorialSteps: [TutorialStep] = [
    TutorialStep(
        title: "ここは、\nまだ大きな星がない宇宙。",
        body:  "あなたの日々の日記や考えを記録して、\n自分だけの夜空を作ってみましょう。"
    ),
    TutorialStep(
        title: "日記は、星になる。",
        body:  "右下の ✦ ボタンから「星を作成」を選んで\n記録を入力すると、星が作成されます。"
    ),
    TutorialStep(
        title: "星に触れると、\n記憶が戻ってくる。",
        body:  "空に輝く星をタップすると\n記録を読み返せます。"
    ),
    TutorialStep(
        title: "宇宙からの、プレゼント。",
        body:  "星を多く作ると、\n何かいいことがあるかもしれません。"
    ),
    TutorialStep(
        title: "あなただけの美しい夜空を\n創造しましょう。",
        body:  ""
    ),
]

// MARK: - TutorialOverlay

struct TutorialOverlay: View {
    let onComplete: () -> Void

    @State private var step:        Int    = 0
    @State private var textOpacity: Double = 0
    @State private var bgOpacity:   Double = 0
    @State private var isAnimating: Bool   = false

    var body: some View {
        ZStack {
            // 背景
            Color.black
                .opacity(bgOpacity)
                .ignoresSafeArea()

            // テキスト
            if step < tutorialSteps.count {
                let s = tutorialSteps[step]
                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 18) {
                        Text(s.title)
                            .font(.custom("HiraMinProN-W3", size: 20))
                            .foregroundColor(.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineSpacing(9)
                            .tracking(1)

                        if let body = s.body {
                            Text(body)
                                .font(.custom("HiraMinProN-W3", size: 13))
                                .foregroundColor(.white.opacity(0.38))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                        }
                    }
                    .padding(.horizontal, 44)

                    Spacer()

                    // 最終ステップのみ「はじめる」、それ以外は「タップして続ける」
                    if step == tutorialSteps.count - 1 {
                        Button { nextStep() } label: {
                            Text("はじめる")
                                .font(.custom("HiraMinProN-W3", size: 13))
                                .foregroundColor(.white.opacity(0.55))
                                .tracking(4)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                                )
                        }
                        .padding(.bottom, 64)
                    } else {
                        Text("タップして続ける")
                            .font(.custom("HiraMinProN-W3", size: 11))
                            .foregroundColor(.white.opacity(0.20))
                            .tracking(3)
                            .padding(.bottom, 64)
                    }
                }
                .opacity(textOpacity)
            }

            // スキップ
            VStack {
                HStack {
                    Spacer()
                    Button { finish() } label: {
                        Text("スキップ")
                            .font(.custom("HiraMinProN-W3", size: 13))
                            .foregroundColor(.white.opacity(0.28))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .padding(.top, 56)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            .opacity(bgOpacity)
        }
        .contentShape(Rectangle())
        .onTapGesture { nextStep() }
        .onAppear { fadeIn() }
    }

    // MARK: - Flow

    private func fadeIn() {
        withAnimation(.easeIn(duration: 0.5)) { bgOpacity = 1 }
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) { textOpacity = 1 }
    }

    private func nextStep() {
        guard !isAnimating else { return }
        isAnimating = true

        // テキストをフェードアウト
        withAnimation(.easeOut(duration: 0.5)) { textOpacity = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            if step < tutorialSteps.count - 1 {
                step += 1
                withAnimation(.easeIn(duration: 0.8)) { textOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    isAnimating = false
                }
            } else {
                finish()
            }
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.6)) {
            textOpacity = 0
            bgOpacity   = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onComplete()
        }
    }
}
