import SwiftUI

struct AddPlanetView: View {
    let onSave:   (String, String, Date) -> Void
    let onCancel: () -> Void

    @State private var title:    String = ""
    @State private var note:     String = ""
    @State private var deadline: Date   = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @FocusState private var focusTitle: Bool

    // 新規作成は満月カラー（青白）
    private let moonTint = Color(red: 0.7, green: 0.85, blue: 1.0)

    private let presets: [(label: String, days: Int)] = [
        ("明日",   1),
        ("3日後",  3),
        ("1週間後", 7),
        ("1ヶ月後", 30),
    ]

    var body: some View {
        ZStack(alignment: .center) {
            Color.clear.ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: 0) {
                // ── ヘッダー
                HStack {
                    Text("想起の月")
                        .font(.custom("HiraMinProN-W6", size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    Button { onCancel() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 22))
                    }
                }
                .padding(.bottom, 14)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 14)

                // ── タイトル
                TextField("タイトル", text: $title)
                    .font(.custom("HiraMinProN-W3", size: 17))
                    .foregroundColor(.white.opacity(0.88))
                    .focused($focusTitle)
                    .tint(.white)
                Divider().background(Color.white.opacity(0.15)).padding(.top, 6)

                // ── 本文
                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("メモ（省略可）")
                            .font(.custom("HiraMinProN-W3", size: 14))
                            .foregroundColor(.white.opacity(0.25))
                            .padding(.top, 14)
                    }
                    TextEditor(text: $note)
                        .font(.custom("HiraMinProN-W3", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .scrollContentBackground(.hidden)
                        .frame(height: 72)
                        .padding(.top, 8)
                        .tint(.white)
                }
                .padding(.top, 4)

                Divider().background(Color.white.opacity(0.15))

                // ── 期限
                VStack(alignment: .leading, spacing: 10) {
                    Text("期限")
                        .font(.custom("HiraMinProN-W3", size: 12))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(2)
                        .padding(.top, 16)

                    HStack(spacing: 8) {
                        ForEach(presets, id: \.days) { preset in
                            Button {
                                deadline = Calendar.current.date(
                                    byAdding: .day, value: preset.days, to: Date()
                                )!
                            } label: {
                                Text(preset.label)
                                    .font(.custom("HiraMinProN-W3", size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            }
                        }
                    }

                    DatePicker("", selection: $deadline, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(.white)
                }
                .padding(.bottom, 20)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 6)

                // ── 保存ボタン
                Button {
                    guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onSave(title.trimmingCharacters(in: .whitespaces), note, deadline)
                } label: {
                    Label("月に刻む", systemImage: "moon.stars")
                        .font(.custom("HiraMinProN-W6", size: 14))
                        .foregroundColor(title.isEmpty ? .white.opacity(0.25) : moonTint.opacity(0.9))
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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
            .environment(\.colorScheme, .dark)
            .padding(.horizontal, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focusTitle = true }
        }
    }
}
