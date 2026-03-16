import SwiftUI
import MetalKit
import Combine

struct MetalStarFieldView: UIViewRepresentable {
    var memoStars: [StarRenderData]
    var backgroundStars: [StarRenderData]
    var selectionState: SIMD3<Float>
    var zoomProgress: Float = 1.0

    func makeCoordinator() -> Renderer {
        Renderer()
    }

    var preferredFPS:   Int    = 24
    var moonNormPos:   CGPoint = .zero
    var moonPhase:     Double  = 1.0
    var moonVisible:   Bool    = false
    var memoryPlanets: [MemoryPlanetType] = []
    var planetPositions: [MemoryPlanetType: CGPoint] = [:]

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = preferredFPS
        mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)

        guard let device = mtkView.device else { return mtkView }

        context.coordinator.configure(with: mtkView, device: device)
        context.coordinator.updateBackgroundStars(backgroundStars)
        context.coordinator.updateMemoStars(memoStars)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.preferredFramesPerSecond = preferredFPS
        let scale = Float(UITraitCollection.current.displayScale > 0 ? UITraitCollection.current.displayScale : 3.0)
        context.coordinator.moonPosition  = SIMD2<Float>(Float(moonNormPos.x), Float(moonNormPos.y))
        context.coordinator.moonPhase     = Float(moonPhase)
        context.coordinator.moonVisible   = moonVisible
        context.coordinator.moonPointSize = Float(49.0 * scale)
        context.coordinator.memoryPlanets = memoryPlanets.compactMap { planet in
            guard let pos = planetPositions[planet] else { return nil }
            return PlanetRenderVertex(
                position:   SIMD2<Float>(Float(pos.x), Float(pos.y)),
                pointSize:  planet.pointSizePixels(scale: scale),
                planetType: UInt32(planet.rawValue)
            )
        }
        context.coordinator.updateBackgroundStars(backgroundStars)
        context.coordinator.updateMemoStars(memoStars)
        context.coordinator.uvOffset = .zero
        context.coordinator.selectionState = selectionState
    }
}
