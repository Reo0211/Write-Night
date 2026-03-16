import Foundation
import CoreGraphics

struct GalaxyStarPlacer {
    static func generatePosition(existing: [CGPoint],
                                 minDistance: CGFloat = 0.045) -> CGPoint {
        var rng = SystemRandomNumberGenerator()
        
        let start = CGPoint(x: 0.12, y: 0.2)
        let end   = CGPoint(x: 0.88, y: 0.85)
        
        func randomNormal(mean: CGFloat, stdDev: CGFloat) -> CGFloat {
            let u1 = max(CGFloat(Double.random(in: 0.0001...0.9999, using: &rng)), 0.0001)
            let u2 = CGFloat(Double.random(in: 0.0...1.0, using: &rng))
            let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
            return mean + z0 * stdDev
        }
        
        func lerp(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t,
                    y: a.y + (b.y - a.y) * t)
        }
        
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx * dx + dy * dy)
        }
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(sqrt(dx*dx + dy*dy), 0.0001)
        let perp = CGPoint(x: -dy / length, y: dx / length)
        
        for _ in 0..<32 {
            var t = randomNormal(mean: 0.5, stdDev: 0.18)
            t = min(max(t, 0.0), 1.0)
            
            var center = lerp(start, end, t: t)
            let phase = CGFloat.random(in: 0...(.pi * 2), using: &rng)
            let wave = sin(t * .pi * 2 + phase)
            center.y += wave * 0.06
            
            let offset = randomNormal(mean: 0.0, stdDev: 0.16)
            var pos = CGPoint(
                x: center.x + perp.x * offset,
                y: center.y + perp.y * offset
            )
            
            pos.x += CGFloat.random(in: -0.015...0.015, using: &rng)
            pos.y += CGFloat.random(in: -0.015...0.015, using: &rng)
            
            pos.x = min(max(pos.x, 0.05), 0.95)
            pos.y = min(max(pos.y, 0.05), 0.95)
            
            var tooClose = false
            for p in existing {
                if distance(p, pos) < minDistance {
                    tooClose = true
                    break
                }
            }
            if !tooClose {
                return pos
            }
        }
        
        return CGPoint(x: CGFloat.random(in: 0.1...0.9, using: &rng),
                       y: CGFloat.random(in: 0.1...0.9, using: &rng))
    }
    
    static func brightness(forTitle title: String, body: String) -> Double {
        let length = max(1, title.count + body.count)
        let minB: Double = 0.4
        let maxB: Double = 1.0
        let ref: Double = 800.0
        
        let logLen = log(Double(length) + 1.0)
        let logRef = log(ref + 1.0)
        var t = logLen / logRef
        t = min(max(t, 0.0), 1.2)
        t = t / 1.2
        return minB + (maxB - minB) * t
    }
}
