import Foundation
import CoreGraphics
import simd

/// 記憶の惑星の種別
enum MemoryPlanetType: Int, Codable, CaseIterable, Identifiable {
    case mercury = 0
    case venus   = 1
    case mars    = 2
    case jupiter = 3
    case saturn  = 4
    case uranus  = 5
    case neptune = 6

    var id: Int { rawValue }

    // MARK: - Milestone & Memo Range

    var milestonekind: MilestoneKind {
        switch self {
        case .mercury: return .mercury
        case .venus:   return .venus
        case .mars:    return .mars
        case .jupiter: return .jupiter
        case .saturn:  return .saturn
        case .uranus:  return .uranus
        case .neptune: return .neptune
        }
    }

    var requiredCount: Int { milestonekind.rawValue }

    /// この惑星に格納されるメモの作成順
    var memoIndexRange: ClosedRange<Int> {
        switch self {
        case .mercury: return  1...100
        case .venus:   return 101...200
        case .mars:    return 201...300
        case .jupiter: return 301...400
        case .saturn:  return 401...500
        case .uranus:  return 501...600
        case .neptune: return 601...700
            
            //テスト
//        case .mercury: return  1...2
//        case .venus:   return  1...2
//        case .mars:    return  1...2
//        case .jupiter: return  1...2
//        case .saturn:  return  1...2
//        case .uranus:  return  1...2
//        case .neptune: return  1...2
        }
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .mercury: return "記憶の水星"
        case .venus:   return "記憶の金星"
        case .mars:    return "記憶の火星"
        case .jupiter: return "記憶の木星"
        case .saturn:  return "記憶の土星"
        case .uranus:  return "記憶の天王星"
        case .neptune: return "記憶の海王星"
        }
    }

    // MARK: - Metal Rendering

    /// Metalシェーダーへ渡すベースカラー
    var metalColor: SIMD3<Float> {
        switch self {
        case .mercury: return SIMD3(0.72, 0.70, 0.68)   // グレー
        case .venus:   return SIMD3(0.92, 0.82, 0.60)   // 黄土
        case .mars:    return SIMD3(0.80, 0.40, 0.25)   // 赤橙
        case .jupiter: return SIMD3(0.78, 0.65, 0.50)   // 茶ベージュ
        case .saturn:  return SIMD3(0.88, 0.80, 0.62)   // 淡金
        case .uranus:  return SIMD3(0.55, 0.85, 0.88)   // 青緑
        case .neptune: return SIMD3(0.35, 0.50, 0.90)   // 深青
        }
    }

    /// ポイントサイズ（土星はリング分を大きめに）
    func pointSizePixels(scale: Float) -> Float {
        // グロー分の余白を十分に確保
        let base: Float = self == .saturn ? 35.0 : 25.0
        return base * scale
    }

    // MARK: - Orbit

    /// 正規化スクリーン座標（y=0 が画面上端）での軌道位置
    func normPosition(at date: Date = Date()) -> CGPoint {
        let p: (cx: Double, cy: Double, rx: Double, ry: Double, period: Double)
        switch self {
        // 月は右上(~0.62, 0.38)なので、惑星は下半分・左右に分散
        case .mercury: p = (0.22, 0.58, 0.10, 0.06, 86400 * 3)   // 左中
        case .venus:   p = (0.78, 0.62, 0.11, 0.07, 86400 * 5)   // 右中下
        case .mars:    p = (0.30, 0.75, 0.12, 0.06, 86400 * 4)   // 左下
        case .jupiter: p = (0.62, 0.78, 0.14, 0.05, 86400 * 7)   // 中央下（大きい）
        case .saturn:  p = (0.80, 0.45, 0.10, 0.07, 86400 * 6)   // 右中
        case .uranus:  p = (0.50, 0.88, 0.16, 0.04, 86400 * 9)   // 最下部
        case .neptune: p = (0.20, 0.35, 0.10, 0.07, 86400 * 8)   // 左上
        }
        let t     = date.timeIntervalSinceReferenceDate
        let angle = (t / p.period) * .pi * 2
        return CGPoint(
            x: p.cx + cos(angle) * p.rx,
            y: p.cy + sin(angle) * p.ry
        )
    }
}

// MARK: - Render vertex (C-compatible for Metal buffer)

struct PlanetRenderVertex {
    var position:   SIMD2<Float>
    var pointSize:  Float
    var planetType: UInt32
}   // 合計16バイト
