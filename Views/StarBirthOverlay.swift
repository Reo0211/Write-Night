import SwiftUI

struct StarBirthOverlay: View {
    let target: CGPoint
    let onArrival: () -> Void

    @State private var progress: CGFloat = 0.0
    @State private var opacity:  Double  = 0.0
    @State private var arrived:  Bool    = false

    // 軌跡用：過去の座標を記録
    @State private var trail: [CGPoint] = []

    private let totalDuration: Double = 0.75
    private let trailLength = 18

    var body: some View {
        GeometryReader { geo in
            let start = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.88)
            let current = interpolate(from: start, to: target, t: easeInOut(progress))

            ZStack {
                // ── 軌跡（連続した線）─────────────────────────────
                if trail.count >= 2 {
                    Path { path in
                        path.move(to: trail.first!)
                        for pt in trail.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color(red: 0.7, green: 0.88, blue: 1.0).opacity(0.25),
                                Color.white.opacity(0.55)
                            ],
                            startPoint: .init(
                                x: trail.first!.x / geo.size.width,
                                y: trail.first!.y / geo.size.height
                            ),
                            endPoint: .init(
                                x: trail.last!.x / geo.size.width,
                                y: trail.last!.y / geo.size.height
                            )
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 1.2)
                }

                // ── 光球グロー ────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color(red: 0.7, green: 0.88, blue: 1.0).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: arrived ? 30 : 14
                            )
                        )
                        .frame(width: arrived ? 60 : 28, height: arrived ? 60 : 28)
                        .blur(radius: arrived ? 6 : 3)

                    Circle()
                        .fill(Color.white)
                        .frame(width: arrived ? 2 : 5, height: arrived ? 2 : 5)
                        .shadow(color: Color(red: 0.8, green: 0.92, blue: 1.0), radius: 4)
                }
                .scaleEffect(arrived ? 1.6 : 1.0)
                .opacity(opacity)
                .position(arrived ? target : current)
                .animation(arrived ? .easeOut(duration: 0.2) : nil, value: arrived)
            }
            .onAppear {
                runAnimation(start: start, geo: geo)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Animation

    private func runAnimation(start: CGPoint, geo: GeometryProxy) {
        AudioManager.shared.playStarBirth()
        withAnimation(.easeIn(duration: 0.15)) { opacity = 1.0 }

        // 軌跡を60fpsで記録
        let steps = Int(totalDuration * 60)
        for i in 0...steps {
            let delay = Double(i) / 60.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let t = CGFloat(i) / CGFloat(steps)
                progress = t
                let pt = interpolate(from: start, to: target, t: easeInOut(t))
                trail.append(pt)
                if trail.count > trailLength { trail.removeFirst() }
            }
        }

        // 着地
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            arrived = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onArrival()
                withAnimation(.easeOut(duration: 0.25)) { opacity = 0.0 }
                trail = []
            }
        }
    }

    // MARK: - Helpers

    private func interpolate(from: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(x: from.x + (to.x - from.x) * t,
                y: from.y + (to.y - from.y) * t)
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}
