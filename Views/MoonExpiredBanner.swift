import SwiftUI

struct MoonExpiredBanner: View {
    let planet:    Planet
    let onDismiss: () -> Void

    @State private var dismissed = false

    private let moonTint = Color(red: 1.0, green: 0.55, blue: 0.3)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // 新月アイコン（期限切れ → 新月）
                MoonPhaseShape(phase: 0.0)
                    .frame(width: 26, height: 26)
                    .opacity(0.7)

                VStack(alignment: .leading, spacing: 3) {
                    Text("期限が来ました!")
                        .font(.custom("HiraMinProN-W3", size: 11))
                        .foregroundColor(moonTint.opacity(0.85))
                        .tracking(1.5)
                    Text(planet.title)
                        .font(.custom("HiraMinProN-W6", size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    guard !dismissed else { return }
                    dismissed = true
                    withAnimation(.easeIn(duration: 0.25)) { onDismiss() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.35))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(moonTint.opacity(0.10))
            )
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .opacity(0.90)
            .padding(.horizontal, 16)
            .padding(.top, 58)

            Spacer()
        }
        .onAppear {
            // 5秒後に自動消去
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                guard !dismissed else { return }
                dismissed = true
                withAnimation(.easeIn(duration: 0.25)) { onDismiss() }
            }
        }
    }
}
