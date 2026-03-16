import SwiftUI

struct MemoListView: View {
    @EnvironmentObject private var memoVM: MemoViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(2.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── ヘッダー ──────────────────────────────────────────
                HStack(alignment: .lastTextBaseline) {
                    Text("星一覧")
                        .font(.custom("HiraMinProN-W6", size: 20))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text("\(memoVM.memos.count) 個")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.3))
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 22))
                    }
                    .padding(.leading, 12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if memoVM.memos.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.15))
                        Text("まだ星がありません")
                            .font(.custom("HiraMinProN-W3", size: 15))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(sortedMemos) { memo in
                                StarListRow(memo: memo)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }

    private var sortedMemos: [Memo] {
        memoVM.memos.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Row

private struct StarListRow: View {
    let memo: Memo
    @State private var expanded = false

    private var timeText: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "MM/dd HH:mm"
        return f.string(from: memo.createdAt)
    }

    private var bodyFirstLine: String {
        memo.body.components(separatedBy: "\n").first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── 1行目（常時表示）────────────────────────────────────
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3 + memo.brightness * 0.5))
                    .frame(width: 16)

                Text(memo.title.isEmpty ? "題名なし" : memo.title)
                    .font(.custom("HiraMinProN-W6", size: 14))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)

                Text(bodyFirstLine)
                    .font(.custom("HiraMinProN-W3", size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(timeText)
                    .font(.custom("HiraMinProN-W3", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.white.opacity(0.2))
                    .rotationEffect(.degrees(expanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: expanded)
            }

            // ── 展開時の全文 ─────────────────────────────────────────
            if expanded {
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.top, 12)
                    .padding(.horizontal, 4)

                if !memo.body.isEmpty {
                    Text(memo.body)
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)
                        .padding(.horizontal, 4)
                } else {
                    Text("本文なし")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.top, 10)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color.white.opacity(expanded ? 0.06 : 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.22)) {
                expanded.toggle()
            }
        }
    }
}
