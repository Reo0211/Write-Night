import Foundation
import CoreGraphics

struct Memo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date

    var starPosition: CGPoint

    var brightness: Double
    /// 感情カラー
    var emotionHue: Double

    init(id: UUID = UUID(),
         title: String,
         body: String,
         createdAt: Date = Date(),
         starPosition: CGPoint,
         brightness: Double,
         emotionHue: Double = 0.5) {
        self.id           = id
        self.title        = title
        self.body         = body
        self.createdAt    = createdAt
        self.starPosition = starPosition
        self.brightness   = brightness
        self.emotionHue   = emotionHue
    }
}

// MARK: - Emotion color mapping

extension Memo {
    /// 感情の (0〜1) をRGB (各 0〜1)へ変換
    static func emotionColor(for hue: Double) -> (r: Double, g: Double, b: Double) {
        let t = max(0, min(1, hue))
        let stops: [(t: Double, r: Double, g: Double, b: Double)] = [
            //　独断と偏見の感情色
            (0.00, 0.72, 0.78, 1.00),  // 青白 (悲しみ)
            (0.30, 0.78, 0.88, 1.00),  // 淡水色 (穏やか)
            (0.50, 0.92, 0.94, 1.00),  // 白銀 (平静)
            (0.72, 1.00, 0.96, 0.82),  // 淡金 (喜び)
            (1.00, 1.00, 0.82, 0.72),  // 淡橙 (興奮)
        ]
        for i in 0..<stops.count - 1 {
            let a = stops[i], b = stops[i + 1]
            if t <= b.t {
                let f = (t - a.t) / (b.t - a.t)
                return (r: a.r + (b.r - a.r) * f,
                        g: a.g + (b.g - a.g) * f,
                        b: a.b + (b.b - a.b) * f)
            }
        }
        return (stops.last!.r, stops.last!.g, stops.last!.b)
    }

    var emotionLabel: String {
        switch emotionHue {
        case 0.0..<0.15: return "悲しみ"
        case 0.15..<0.35: return "穏やか"
        case 0.35..<0.65: return "平静"
        case 0.65..<0.85: return "喜び"
        default:           return "興奮"
        }
    }
}
