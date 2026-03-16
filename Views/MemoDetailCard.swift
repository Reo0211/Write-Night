import SwiftUI
import UIKit

struct MemoDetailCard: View {
    let memo: Memo
    let onClose: () -> Void

    @EnvironmentObject private var memoVM: MemoViewModel

    @State private var showingEdit    = false
    @State private var showingDelete  = false

    private var dateText: String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "yyyy.MM.dd  HH:mm"
        return fmt.string(from: memo.createdAt)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .ignoresSafeArea()
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
                    Button(action: { onClose() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 22))
                    }
                }
                .padding(.bottom, 14)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.bottom, 14)

                // ── 本文
                ScrollView {
                    Text(memo.body.isEmpty ? "本文なし" : memo.body)
                        .font(.custom("HiraMinProN-W3", size: 16))
                        .foregroundColor(.white.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(5)
                }
                .frame(maxHeight: 380)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.top, 14)

                // ── 編集・削除
                HStack(spacing: 0) {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                            .font(.custom("HiraMinProN-W3", size: 14))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 0.5, height: 36)

                    Button {
                        showingDelete = true
                    } label: {
                        Label("削除", systemImage: "trash")
                            .font(.custom("HiraMinProN-W3", size: 14))
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.top, 6)
            }
            .padding(22)
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .opacity(0.82)
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showingEdit) {
            EditMemoView(memo: memo) { newTitle, newBody in
                var updated = memo
                updated.title = newTitle.isEmpty ? "題名なし" : newTitle
                updated.body  = newBody
                memoVM.updateMemo(updated)
                onClose()
            } onCancel: {
                showingEdit = false
            }
        }
        .confirmationDialog("この星を削除しますか？", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                AudioManager.shared.playStarDelete()
                // 削除前に星のスクリーン座標を計算して超新星を発火
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let bounds = scene?.screen.bounds ?? CGRect(x: 0, y: 0, width: 393, height: 852)
                let screenPos = CGPoint(
                    x: memo.starPosition.x * bounds.width,
                    y: (1.0 - memo.starPosition.y) * bounds.height
                )
                NotificationCenter.default.post(name: .starSupernova, object: screenPos)
                memoVM.deleteMemo(memo)
                onClose()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}

// MARK: - EditMemoView

private struct EditMemoView: View {
    @Environment(\.dismiss) private var dismiss

    let memo: Memo
    let onSave:   (String, String) -> Void
    let onCancel: () -> Void

    @State private var title:    String
    @State private var memoBody: String

    init(memo: Memo, onSave: @escaping (String, String) -> Void, onCancel: @escaping () -> Void) {
        self.memo     = memo
        self.onSave   = onSave
        self.onCancel = onCancel
        _title    = State(initialValue: memo.title)
        _memoBody = State(initialValue: memo.body)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.04, blue: 0.12), Color.black],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    TextField("タイトル", text: $title)
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
                        .frame(minHeight: 220)

                    HStack(spacing: 12) {
                        Button(role: .cancel) {
                            onCancel(); dismiss()
                        } label: {
                            Text("キャンセル")
                                .font(.custom("HiraMinProN-W3", size: 16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Button {
                            onSave(title, memoBody); dismiss()
                        } label: {
                            Text("保存")
                                .font(.custom("HiraMinProN-W6", size: 16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                  memoBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
