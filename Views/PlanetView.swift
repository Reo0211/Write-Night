import SwiftUI

// MARK: - MoonPhaseShape

struct MoonPhaseShape: View {
    let phase: Double   // 1.0=満月, 0.5=半月, 0.0=新月

    var body: some View {
        Canvas { ctx, size in
            let r  = min(size.width, size.height) / 2
            let cx = size.width  / 2
            let cy = size.height / 2
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)

            ctx.fill(
                Path(ellipseIn: rect),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.92, green: 0.92, blue: 0.82),
                        Color(red: 0.72, green: 0.72, blue: 0.62),
                    ]),
                    startPoint: CGPoint(x: cx - r, y: cy - r),
                    endPoint:   CGPoint(x: cx + r, y: cy + r)
                )
            )

            let shadow = shadowFor(phase: phase, cx: cx, cy: cy, r: r)
            ctx.fill(shadow,
                     with: .color(Color(red: 0.04, green: 0.05, blue: 0.14).opacity(0.93)))

            ctx.stroke(Path(ellipseIn: rect),
                       with: .color(Color.white.opacity(0.12)),
                       lineWidth: 0.5)
        }
    }

    private func shadowFor(phase: Double, cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        let fullRect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
        if phase >= 0.99 { return Path() }
        if phase <= 0.01 { return Path(ellipseIn: fullRect) }

        let xr = abs(phase - 0.5) * 2 * r
        if phase >= 0.5 {
            let light = Path(ellipseIn: CGRect(x: cx - xr, y: cy - r,
                                               width: xr * 2, height: r * 2))
                .union(Path(CGRect(x: cx, y: cy - r, width: r, height: r * 2)))
            return Path(ellipseIn: fullRect).subtracting(light)
        } else {
            var p = Path()
            p.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                     startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            let ellipsePath = Path(ellipseIn: CGRect(x: cx - xr, y: cy - r,
                                                      width: xr * 2, height: r * 2))
            return p.union(ellipsePath)
        }
    }
}
