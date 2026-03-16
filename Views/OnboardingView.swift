import SwiftUI

struct OnboardingView: View {
    let onComplete: (String) -> Void

    @State private var name:        String  = ""
    @State private var starOpacity: Double  = 0
    @State private var titleOpacity: Double = 0
    @State private var formOpacity:  Double = 0
    @State private var stars: [OnboardingStar] = []

    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── 星背景 ────────────────────────────────────────────
            ForEach(stars) { star in
                Circle()
                    .fill(Color.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.opacity)
                    .position(star.position)
                    .blur(radius: star.size > 2.5 ? 0.6 : 0.2)
            }

            VStack(spacing: 0) {
                Spacer()

                // ── タイトル ──────────────────────────────────────
                VStack(spacing: 12) {
                    Text("Write Night")
                        .font(.custom("HiraMinProN-W3", size: 22))
                        .foregroundColor(.white.opacity(0.75))
                        .tracking(8)

                    Text("あなたの名前を教えてください")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(2)
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 56)

                // ── 入力フォーム ──────────────────────────────────
                VStack(spacing: 20) {
                    TextField("", text: $name)
                        .font(.custom("HiraMinProN-W3", size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .placeholder(when: name.isEmpty) {
                            Text("ニックネーム")
                                .font(.custom("HiraMinProN-W3", size: 22))
                                .foregroundColor(.white.opacity(0.2))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                        .focused($fieldFocused)
                        .submitLabel(.done)
                        .onSubmit { tryComplete() }

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.25), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                        .padding(.horizontal, 40)

                    Button {
                        tryComplete()
                    } label: {
                        Text("はじめる")
                            .font(.custom("HiraMinProN-W3", size: 15))
                            .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? .white.opacity(0.2)
                                             : .white.opacity(0.75))
                            .tracking(4)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .animation(.easeInOut(duration: 0.2), value: name.isEmpty)
                }
                .padding(.horizontal, 48)
                .opacity(formOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear { runSequence() }
        .onTapGesture { fieldFocused = false }
    }

    // MARK: - Helpers

    private func tryComplete() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        fieldFocused = false

        withAnimation(.easeInOut(duration: 0.8)) {
            titleOpacity = 0
            formOpacity  = 0
            starOpacity  = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onComplete(trimmed)
        }
    }

    private func runSequence() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height

        // 星を生成
        for i in 0..<55 {
            let delay = Double.random(in: 0.1...1.2)
            let star = OnboardingStar(
                id: i,
                position: CGPoint(x: CGFloat.random(in: 0...screenW),
                                  y: CGFloat.random(in: 0...screenH)),
                size: CGFloat.random(in: 0.8...3.2),
                opacity: 0
            )
            stars.append(star)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: Double.random(in: 0.5...1.2))) {
                    stars[i].opacity = Double.random(in: 0.2...0.65)
                }
            }
        }

        // タイトル → フォームの順にフェードイン
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 1.0)) { titleOpacity = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) { formOpacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                fieldFocused = true
            }
        }
    }
}

// MARK: - Model

private struct OnboardingStar: Identifiable {
    let id: Int
    let position: CGPoint
    var size: CGFloat
    var opacity: Double
}

// MARK: - Placeholder helper

private extension View {
    func placeholder<P: View>(when condition: Bool, @ViewBuilder placeholder: () -> P) -> some View {
        ZStack(alignment: .center) {
            if condition { placeholder() }
            self
        }
    }
}
