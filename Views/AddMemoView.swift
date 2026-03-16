import SwiftUI

struct AddMemoView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title:      String = ""
    @State private var memoBody:   String = ""
    @State private var emotionHue: Double = 0.5

    let onSave:   (String, String, Double) -> Void
    let onCancel: () -> Void

    private var emotionUnlocked: Bool {
        MilestoneManager.shared.isUnlocked(.emotionColor)
    }

    // グラデーションのキーカラー（彩度・明度を抑えて夜空に馴染む色味に）
    private let gradientColors: [Color] = [
        Color(red: 0.08, green: 0.12, blue: 0.55),  // 深青
        Color(red: 0.16, green: 0.38, blue: 0.72),  // 水色
        Color(red: 0.52, green: 0.55, blue: 0.65),  // 白銀
        Color(red: 0.62, green: 0.50, blue: 0.20),  // 金黄
        Color(red: 0.62, green: 0.24, blue: 0.16),  // 赤橙
    ]

    private var currentColor: Color {
        let c = Memo.emotionColor(for: emotionHue)
        return Color(red: c.r * 0.60, green: c.g * 0.60, blue: c.b * 0.60)
    }

    private var emotionLabel: String {
        switch emotionHue {
        case 0.0..<0.15: return "悲しみ"
        case 0.15..<0.35: return "穏やか"
        case 0.35..<0.65: return "平静"
        case 0.65..<0.85: return "喜び"
        default:           return "興奮"
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                TextField("題名", text: $title)
                    .font(.custom("HiraMinProN-W3", size: 17))
                    .foregroundColor(.white)
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                TextEditor(text: $memoBody)
                    .font(.custom("HiraMinProN-W3", size: 16))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 180)

                // ── 感情カラーバー（解放後のみ表示）────────────────
                if emotionUnlocked {
                    VStack(spacing: 10) {
                        HStack {
                            Text("気持ち")
                                .font(.custom("HiraMinProN-W3", size: 12))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(currentColor)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: currentColor.opacity(0.9), radius: 5)
                                Text(emotionLabel)
                                    .font(.custom("HiraMinProN-W3", size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }

                        EmotionColorBar(hue: $emotionHue, colors: gradientColors)
                            .frame(height: 36)
                    }
                    .padding(.horizontal, 2)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                Button {
                    onSave(title, memoBody, emotionUnlocked ? emotionHue : 0.5)
                    dismiss()
                } label: {
                    Text("作成")
                        .font(.custom("HiraMinProN-W6", size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                          memoBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.04, blue: 0.12),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("新しい星")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - EmotionColorBar

private struct EmotionColorBar: View {
    @Binding var hue: Double
    let colors: [Color]

    private var thumbColor: Color {
        let c = Memo.emotionColor(for: hue)
        // 彩度・明度を抑えてバーと馴染ませる
        return Color(red: c.r * 0.60, green: c.g * 0.60, blue: c.b * 0.60)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // グラデーションバー
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(
                        colors: colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)

                // つまみ
                let x = hue * geo.size.width
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.4), radius: 5)
                    Circle()
                        .fill(thumbColor)
                        .frame(width: 14, height: 14)
                }
                .position(x: max(14, min(geo.size.width - 14, x)),
                          y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        hue = max(0, min(1, Double(v.location.x / geo.size.width)))
                    }
            )
        }
    }
}
