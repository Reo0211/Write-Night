import SwiftUI

struct PlanetListView: View {
    let onClose:      () -> Void
    let onSelect:     (Planet) -> Void
    let onAddNew:     () -> Void

    @EnvironmentObject private var planetVM: PlanetViewModel

    private let moonTint = Color(red: 0.7, green: 0.85, blue: 1.0)

    var body: some View {
        ZStack(alignment: .center) {
            Color.clear.ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                // ── ヘッダー
                HStack {
                    Text("想起の月")
                        .font(.custom("HiraMinProN-W6", size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 10) {
                        Text("\(planetVM.activeReminders.count) 件")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(.white.opacity(0.45))
                        Button { onClose() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 22))
                        }
                    }
                }
                .padding(.bottom, 14)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 10)

                // ── リスト
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(planetVM.activeReminders) { planet in
                            PlanetRow(
                                planet: planet,
                                onTap: { onSelect(planet) },
                                onComplete: { planetVM.complete(planet) }
                            )
                        }
                    }
                }
                .frame(maxHeight: 360)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                // ── 新規追加ボタン
                Button { onAddNew() } label: {
                    Label("新しいリマインダー", systemImage: "plus")
                        .font(.custom("HiraMinProN-W3", size: 14))
                        .foregroundColor(moonTint.opacity(0.85))
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

// MARK: - PlanetRow

private struct PlanetRow: View {
    let planet:     Planet
    let onTap:      () -> Void
    let onComplete: () -> Void

    @State private var showCompleteConfirm = false

    private var phaseColor: Color {
        switch planet.moonPhase {
        case 0.0..<0.2: return Color(red: 1.0, green: 0.5, blue: 0.3)
        case 0.2..<0.5: return Color(red: 0.9, green: 0.8, blue: 0.5)
        default:        return Color(red: 0.7, green: 0.85, blue: 1.0)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 月の満ち欠けミニプレビュー（タップで詳細）
            MoonPhaseShape(phase: planet.moonPhase)
                .frame(width: 22, height: 22)
                .onTapGesture { onTap() }

            // タイトル（タップで詳細）
            Text(planet.title)
                .font(.custom("HiraMinProN-W6", size: 13))
                .foregroundColor(.white.opacity(0.88))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { onTap() }

            // 残り日数
            Group {
                if planet.daysRemaining > 0 {
                    Text("あと\(planet.daysRemaining)日")
                        .foregroundColor(phaseColor.opacity(0.8))
                } else if planet.isOverdue {
                    Text("期限超過")
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.8))
                } else {
                    Text("今日まで")
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.8))
                }
            }
            .font(.custom("HiraMinProN-W3", size: 11))

            // 完了ボタン
            Button {
                showCompleteConfirm = true
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(phaseColor.opacity(0.6))
            }
            .confirmationDialog("「\(planet.title)」を完了しますか？", isPresented: $showCompleteConfirm, titleVisibility: .visible) {
                Button("完了") { onComplete() }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.vertical, 1)
    }
}
