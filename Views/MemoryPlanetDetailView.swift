import SwiftUI

struct MemoryPlanetDetailView: View {
    let planet:  MemoryPlanetType
    let memos:   [Memo]
    let onClose: () -> Void

    @State private var selectedMemo: Memo? = nil

    private var planetTint: Color {
        let c = planet.metalColor
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }

    private var dateRange: String {
        guard let first = memos.first, let last = memos.last else { return "" }
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy.MM.dd"
        if first.id == last.id { return f.string(from: first.createdAt) }
        return "\(f.string(from: first.createdAt))  –  \(f.string(from: last.createdAt))"
    }

    var body: some View {
        ZStack(alignment: .center) {
            Color.clear.ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                // ── ヘッダー
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planet.displayName)
                            .font(.custom("HiraMinProN-W6", size: 17))
                            .foregroundColor(.white)
                        if !memos.isEmpty {
                            Text(dateRange)
                                .font(.custom("HiraMinProN-W3", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Text("\(memos.count) 個の星")
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
                    .padding(.bottom, 14)

                // ── メモリスト
                if memos.isEmpty {
                    Text("まだ星がありません")
                        .font(.custom("HiraMinProN-W3", size: 14))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.vertical, 28)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(memos.enumerated()), id: \.element.id) { idx, memo in
                                ArchivedMemoRow(
                                    index: planet.memoIndexRange.lowerBound + idx,
                                    memo: memo
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        selectedMemo = memo
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 360)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(planetTint.opacity(0.18))
            )
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .opacity(0.82)
            .padding(.horizontal, 16)

            // ── メモ詳細オーバーレイ
            if let memo = selectedMemo {
                ArchivedMemoDetailView(memo: memo, planetTint: planetTint) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedMemo = nil
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedMemo?.id)
    }
}

// MARK: - ArchivedMemoRow

private struct ArchivedMemoRow: View {
    let index: Int
    let memo:  Memo

    private var timeText: String {
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.dateFormat = "MM/dd"
        return f.string(from: memo.createdAt)
    }

    private var starColor: Color {
        let c = Memo.emotionColor(for: memo.emotionHue)
        return Color(red: c.r * 0.75, green: c.g * 0.75, blue: c.b * 0.75)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(String(format: "%3d", index))
                .font(.custom("HiraMinProN-W3", size: 10))
                .foregroundColor(.white.opacity(0.18))
                .frame(width: 28, alignment: .trailing)
                .monospacedDigit()

            Circle()
                .fill(starColor)
                .frame(width: 5, height: 5)
                .shadow(color: starColor.opacity(0.9), radius: 2)

            Text(memo.title.isEmpty ? "題名なし" : memo.title)
                .font(.custom("HiraMinProN-W6", size: 13))
                .foregroundColor(.white.opacity(0.88))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(timeText)
                .font(.custom("HiraMinProN-W3", size: 11))
                .foregroundColor(.white.opacity(0.22))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.vertical, 1)
    }
}

// MARK: - ArchivedMemoDetailView

private struct ArchivedMemoDetailView: View {
    let memo:       Memo
    let planetTint: Color
    let onClose:    () -> Void

    private var dateText: String {
        let f = DateFormatter()
        f.calendar   = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy.MM.dd  HH:mm"
        return f.string(from: memo.createdAt)
    }

    var body: some View {
        ZStack(alignment: .center) {
            Color.clear.ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.title.isEmpty ? "Thought" : memo.title)
                            .font(.custom("HiraMinProN-W6", size: 17))
                            .foregroundColor(.white)
                        Text(dateText)
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Button { onClose() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 22))
                    }
                }
                .padding(.bottom, 14)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 14)

                ScrollView {
                    Text(memo.body.isEmpty ? "本文なし" : memo.body)
                        .font(.custom("HiraMinProN-W3", size: 16))
                        .foregroundColor(.white.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(5)
                }
                .frame(maxHeight: 380)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(planetTint.opacity(0.18))
            )
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .opacity(0.82)
            .padding(.horizontal, 16)
        }
    }
}
