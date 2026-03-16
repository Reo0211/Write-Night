import Foundation
import CoreGraphics
import Combine

final class MemoViewModel: ObservableObject {
    @Published private(set) var memos: [Memo] = []

    private var hasLoaded = false
    private let store = MemoStore.shared

    func loadMemosIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        let loaded = store.loadMemos()
        DispatchQueue.main.async {
            self.memos = loaded
        }
    }

    @discardableResult
    func createMemo(title: String, body: String, emotionHue: Double = 0.5) -> Memo {
        let existingPositions = memos.map { $0.starPosition }
        let position = GalaxyStarPlacer.generatePosition(existing: existingPositions)
        return createMemo(title: title, body: body, emotionHue: emotionHue, at: position)
    }

    /// 座標を指定してメモを生成（着地点と一致させるために使用）のつもりだけんどなんかが間違ってる多分。時間があったら修正。
    @discardableResult
    func createMemo(title: String, body: String, emotionHue: Double = 0.5, at position: CGPoint) -> Memo {
        let brightness = GalaxyStarPlacer.brightness(forTitle: title, body: body)
        let memo = Memo(title: title.isEmpty ? "題名なし" : title,
                        body: body,
                        starPosition: position,
                        brightness: brightness,
                        emotionHue: emotionHue)
        memos.append(memo)
        store.saveMemos(memos)
        return memo
    }

    func updateMemo(_ memo: Memo) {
        if let idx = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[idx] = memo
            store.saveMemos(memos)
        }
    }

    func deleteMemo(_ memo: Memo) {
        memos.removeAll { $0.id == memo.id }
        store.saveMemos(memos)
    }
}
