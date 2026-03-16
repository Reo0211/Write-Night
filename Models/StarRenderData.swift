import Foundation
import CoreGraphics
import simd

struct StarRenderData: Identifiable {
    enum StarType {
        case background
        case memo
    }
    
    let id: UUID
    var position: CGPoint
    var radius: CGFloat
    var brightness: CGFloat     
    var color: SIMD3<Float>   
    var type: StarType
    var hasSparkle: Bool
}
