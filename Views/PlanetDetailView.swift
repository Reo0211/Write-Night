import SwiftUI

struct PlanetDetailView: View {
    let planet:     Planet
    let onComplete: () -> Void
    let onDelete:   () -> Void

    @State private var showDeleteConfirm = false

    private var moonTint: Color {
        switch planet.moonPhase {
        case 0.0..<0.2: return Color(red: 1.0, green: 0.5, blue: 0.3)   // 新月: 赤橙
        case 0.2..<0.5: return Color(red: 0.9, green: 0.8, blue: 0.5)   // 三日月: 琥珀
        default:        return Color(red: 0.7, green: 0.85, blue: 1.0)  // 満月: 青白
        }
    }

    private var phaseLabel: String {
        switch planet.moonPhase {
        case 0.85...1.0:  return "満月　作成直後"
        case 0.6..<0.85:  return "上弦の月　まだ余裕あり"
        case 0.35..<0.6:  return "半月　中間地点"
        case 0.15..<0.35: return "三日月　期限が近づいている"
        default:           return "新月　もうすぐ期限"
        }
    }

    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f
    }

    var body: some View {
        ZStack(alignment: .center) {
            Color.clear.ignoresSafeArea()
                .onTapGesture { onComplete() }

            VStack(spacing: 0) {
                // ── ヘッダー（月プレビュー + タイトル + 削除）
                HStack(spacing: 16) {
                    MoonPhaseShape(phase: planet.moonPhase)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(planet.title)
                            .font(.custom("HiraMinProN-W6", size: 17))
                            .foregroundColor(.white)
                        Text(phaseLabel)
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(moonTint.opacity(0.85))
                            .tracking(0.5)
                    }

                    Spacer()

                    Button { showDeleteConfirm = true } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 22))
                    }
                    .confirmationDialog("削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                        Button("削除", role: .destructive) { onDelete() }
                        Button("キャンセル", role: .cancel) {}
                    }
                }
                .padding(.bottom, 14)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 14)

                // ── 本文
                if !planet.body.isEmpty {
                    Text(planet.body)
                        .font(.custom("HiraMinProN-W3", size: 16))
                        .foregroundColor(.white.opacity(0.88))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                }

                // ── 期限
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                    Text(formatter.string(from: planet.deadline))
                        .font(.custom("HiraMinProN-W3", size: 12))
                        .foregroundColor(.white.opacity(0.35))
                    Spacer()
                    if planet.daysRemaining > 0 {
                        Text("あと\(planet.daysRemaining)日")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(moonTint.opacity(0.8))
                    } else if planet.isOverdue {
                        Text("期限超過")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.8))
                    } else {
                        Text("今日まで")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.8))
                    }
                }
                .padding(.bottom, 20)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 6)

                // ── 完了ボタン
                Button {
                    onComplete()
                } label: {
                    Label("完了", systemImage: "checkmark")
                        .font(.custom("HiraMinProN-W6", size: 14))
                        .foregroundColor(moonTint.opacity(0.9))
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(moonTint.opacity(0.08))
            )
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .opacity(2.0)
            .padding(.horizontal, 16)
        }
    }
}
