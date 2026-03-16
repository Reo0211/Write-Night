import Foundation
import CoreGraphics

final class MemoStore {
    static let shared = MemoStore()
    
    private let fileURL: URL
    
    private init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ThoughtSky", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        self.fileURL = dir.appendingPathComponent("memos.json")
    }
    
    func loadMemos() -> [Memo] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Memo].self, from: data)
        } catch {
            print("Failed to decode memos: \(error)")
            return []
        }
    }
    
    func saveMemos(_ memos: [Memo]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(memos)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save memos: \(error)")
        }
    }
}