import Foundation
import MetalKit
import simd

struct MetalStar {
    var position:   SIMD2<Float>  // 8 bytes
    var radius:     Float          // 4 bytes
    var brightness: Float          // 4 bytes
    var color:      SIMD4<Float>  // 16 bytes
    var type:       UInt32         // 4 bytes
    var hasSparkle: UInt32         // 4 bytes

}

final class Renderer: NSObject, MTKViewDelegate {
    private weak var view: MTKView?
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!

    private var gradientPipelineState: MTLRenderPipelineState!
    private var starPipelineState:     MTLRenderPipelineState!

    private var quadVertexBuffer:    MTLBuffer!
    private var bgStarBuffer:        MTLBuffer?
    private var memoStarBuffer:      MTLBuffer?
    private var moonPipelineState:   MTLRenderPipelineState!
    private var planetPipelineState: MTLRenderPipelineState?

    var memoryPlanets: [PlanetRenderVertex] = []
    var moonPosition: SIMD2<Float> = SIMD2<Float>(0.62, 0.38)
    var moonPhase:    Float        = 1.0
    var moonVisible:  Bool         = false
    var moonPointSize: Float       = 54.0

    private var bgStarCount:   Int = 0
    private var memoStarCount: Int = 0

    private var time: Float = 0
    var uvOffset: SIMD2<Float> = .zero

    var nebulaParams: [NebulaParams] = NebulaParams.generateRandom()

    var selectionState: SIMD3<Float> = SIMD3<Float>(0, 0, -1)
    var zoomProgress: Float = 1.0

    // MARK: - Setup

    func configure(with view: MTKView, device: MTLDevice) {
        self.view   = view
        self.device = device
        guard let cq = device.makeCommandQueue() else { return }
        commandQueue = cq
        buildPipelines()
        buildQuad()
        view.delegate = self
    }

    private func buildPipelines() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Metal library not found.")
        }

        let gradDesc = MTLRenderPipelineDescriptor()
        gradDesc.vertexFunction   = library.makeFunction(name: "gradient_vertex")
        gradDesc.fragmentFunction = library.makeFunction(name: "gradient_fragment")
        gradDesc.colorAttachments[0].pixelFormat = view?.colorPixelFormat ?? .bgra8Unorm

        let starDesc = MTLRenderPipelineDescriptor()
        starDesc.vertexFunction   = library.makeFunction(name: "star_vertex")
        starDesc.fragmentFunction = library.makeFunction(name: "star_fragment")
        starDesc.colorAttachments[0].pixelFormat        = view?.colorPixelFormat ?? .bgra8Unorm
        starDesc.colorAttachments[0].isBlendingEnabled  = true
        starDesc.colorAttachments[0].rgbBlendOperation  = .add
        starDesc.colorAttachments[0].alphaBlendOperation = .add
        starDesc.colorAttachments[0].sourceRGBBlendFactor    = .one
        starDesc.colorAttachments[0].sourceAlphaBlendFactor  = .one
        starDesc.colorAttachments[0].destinationRGBBlendFactor   = .one
        starDesc.colorAttachments[0].destinationAlphaBlendFactor  = .one

        let moonDesc = MTLRenderPipelineDescriptor()
        moonDesc.vertexFunction   = library.makeFunction(name: "moon_vertex")
        moonDesc.fragmentFunction = library.makeFunction(name: "moon_fragment")
        moonDesc.colorAttachments[0].pixelFormat       = view?.colorPixelFormat ?? .bgra8Unorm
        moonDesc.colorAttachments[0].isBlendingEnabled = true
        moonDesc.colorAttachments[0].rgbBlendOperation   = .add
        moonDesc.colorAttachments[0].alphaBlendOperation  = .add
        moonDesc.colorAttachments[0].sourceRGBBlendFactor      = .sourceAlpha
        moonDesc.colorAttachments[0].sourceAlphaBlendFactor    = .sourceAlpha
        moonDesc.colorAttachments[0].destinationRGBBlendFactor   = .oneMinusSourceAlpha
        moonDesc.colorAttachments[0].destinationAlphaBlendFactor  = .oneMinusSourceAlpha

        do {
            gradientPipelineState = try device.makeRenderPipelineState(descriptor: gradDesc)
            starPipelineState     = try device.makeRenderPipelineState(descriptor: starDesc)
            moonPipelineState     = try device.makeRenderPipelineState(descriptor: moonDesc)
        } catch {
            fatalError("Pipeline creation failed: \(error)")
        }

        do {
            let planetDesc = MTLRenderPipelineDescriptor()
            planetDesc.vertexFunction   = library.makeFunction(name: "planet_vertex")
            planetDesc.fragmentFunction = library.makeFunction(name: "planet_fragment")
            planetDesc.colorAttachments[0].pixelFormat       = view?.colorPixelFormat ?? .bgra8Unorm
            planetDesc.colorAttachments[0].isBlendingEnabled = true
            planetDesc.colorAttachments[0].rgbBlendOperation   = .add
            planetDesc.colorAttachments[0].alphaBlendOperation  = .add
            planetDesc.colorAttachments[0].sourceRGBBlendFactor      = .sourceAlpha
            planetDesc.colorAttachments[0].sourceAlphaBlendFactor    = .sourceAlpha
            planetDesc.colorAttachments[0].destinationRGBBlendFactor   = .oneMinusSourceAlpha
            planetDesc.colorAttachments[0].destinationAlphaBlendFactor  = .oneMinusSourceAlpha
            planetPipelineState = try device.makeRenderPipelineState(descriptor: planetDesc)
        } catch {
            print("⚠️ Planet pipeline creation failed: \(error)")
            planetPipelineState = nil
        }
    }

    private func buildQuad() {
        struct QuadVertex { var position: SIMD2<Float>; var uv: SIMD2<Float> }
        let vertices: [QuadVertex] = [
            .init(position: [-1,-1], uv: [0,0]),
            .init(position: [ 1,-1], uv: [1,0]),
            .init(position: [-1, 1], uv: [0,1]),
            .init(position: [ 1,-1], uv: [1,0]),
            .init(position: [ 1, 1], uv: [1,1]),
            .init(position: [-1, 1], uv: [0,1]),
        ]
        quadVertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<QuadVertex>.stride * vertices.count,
            options: []
        )
    }

    // MARK: - Star updates

    func updateBackgroundStars(_ stars: [StarRenderData]) {
        bgStarCount = stars.count
        guard bgStarCount > 0 else { bgStarBuffer = nil; return }
        let metal = stars.map { s in
            MetalStar(
                position:   SIMD2<Float>(Float(s.position.x), Float(s.position.y)),
                radius:     Float(s.radius),
                brightness: Float(s.brightness),
                color:      SIMD4<Float>(s.color.x, s.color.y, s.color.z, 0),
                type:       0,
                hasSparkle: 0
            )
        }
        bgStarBuffer = device.makeBuffer(
            bytes: metal,
            length: MemoryLayout<MetalStar>.stride * metal.count,
            options: []
        )
    }

    func updateMemoStars(_ stars: [StarRenderData]) {
        memoStarCount = stars.count
        guard memoStarCount > 0 else { memoStarBuffer = nil; return }
        let metal = stars.map { s in
            MetalStar(
                position:   SIMD2<Float>(Float(s.position.x), Float(s.position.y)),
                radius:     Float(s.radius),
                brightness: Float(s.brightness),
                color:      SIMD4<Float>(s.color.x, s.color.y, s.color.z, 0),
                type:       1,
                hasSparkle: s.hasSparkle ? 1 : 0
            )
        }
        memoStarBuffer = device.makeBuffer(
            bytes: metal,
            length: MemoryLayout<MetalStar>.stride * metal.count,
            options: []
        )
    }

    // MARK: - NebulaParams

struct NebulaParams {
    var color:     SIMD4<Float>
    var center:    SIMD2<Float>
    var radius:    Float
    var elongX:    Float
    var elongY:    Float
    var rotation:  Float
    var seed:      Float
    var _pad:      Float = 0

    static func generateRandom() -> [NebulaParams] {
        let s = Float(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
        func rnd(_ base: Float, _ range: Float) -> Float {
            let v: Float = base * 127.1 + s * 311.7
            let h: Float = sin(v) * 43758.5
            return (h - h.rounded(.down)) * range
        }

        // 星雲のカラーパレット
        let palettes: [SIMD3<Float>] = [
            SIMD3(0.12, 0.05, 0.22),
            SIMD3(0.04, 0.10, 0.22),  // 青
            SIMD3(0.04, 0.16, 0.13),  // 青緑
            SIMD3(0.18, 0.05, 0.08),  // 深紅
            SIMD3(0.07, 0.07, 0.20),  // 藍
            SIMD3(0.15, 0.10, 0.03),  // 琥珀
        ]

        var result: [NebulaParams] = []
        for i in 0..<2 {
            let fi = Float(i)
            let cx = 0.15 + rnd(fi * 1.1 + 0.3, 0.70)
            let cy = 0.15 + rnd(fi * 2.3 + 0.7, 0.70)
            let pIdx = Int(rnd(fi * 3.7 + 1.1, 1.0) * Float(palettes.count)) % palettes.count
            let col  = palettes[pIdx]
            let intensity = 0.16 + rnd(fi * 4.1 + 2.1, 0.14)
            let radius    = 0.18 + rnd(fi * 5.3 + 3.3, 0.20)
            let elongX    = 0.7  + rnd(fi * 6.1 + 1.7, 1.0)
            let elongY    = 0.7  + rnd(fi * 7.3 + 2.9, 1.0)
            let rotation  = rnd(fi * 8.9 + 0.5, Float.pi)
            let seed      = rnd(fi * 9.7 + 4.3, 10.0)

            result.append(NebulaParams(
                color:    SIMD4(col.x, col.y, col.z, intensity),
                center:   SIMD2(cx, cy),
                radius:   radius,
                elongX:   elongX,
                elongY:   elongY,
                rotation: rotation,
                seed:     seed
            ))
        }

        // 3個目のみ右上固定
        let fi: Float = 2.0
        let pIdx3 = Int(rnd(fi * 3.7 + 1.1, 1.0) * Float(palettes.count)) % palettes.count
        let col3  = palettes[pIdx3]
        result.append(NebulaParams(
            color:    SIMD4(col3.x, col3.y, col3.z, 0.17 + rnd(fi * 4.1, 0.10)),
            center:   SIMD2(0.72 + rnd(fi * 1.3, 0.14), 0.10 + rnd(fi * 2.1, 0.14)),
            radius:   0.16 + rnd(fi * 5.3, 0.12),
            elongX:   0.8  + rnd(fi * 6.1, 0.7),
            elongY:   0.6  + rnd(fi * 7.3, 0.6),
            rotation: rnd(fi * 8.9, Float.pi),
            seed:     rnd(fi * 9.7, 10.0)
        ))

        return result
    }
}

// MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let descriptor    = view.currentRenderPassDescriptor,
            let drawable      = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder       = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        time += 1.0 / Float(max(view.preferredFramesPerSecond, 1))


        encoder.setRenderPipelineState(gradientPipelineState)
        encoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0)
        var t = time
        encoder.setFragmentBytes(&t, length: MemoryLayout<Float>.size, index: 0)
        var off = uvOffset
        encoder.setFragmentBytes(&off, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        var sel = selectionState
        encoder.setFragmentBytes(&sel, length: MemoryLayout<SIMD3<Float>>.size, index: 2)
        encoder.setFragmentBytes(&nebulaParams,
                                 length: MemoryLayout<NebulaParams>.size * nebulaParams.count,
                                 index: 3)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)


        encoder.setRenderPipelineState(starPipelineState)
        var vpSize = SIMD2<Float>(
            Float(view.drawableSize.width),
            Float(view.drawableSize.height)
        )
        encoder.setVertexBytes(&vpSize, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setVertexBytes(&t,      length: MemoryLayout<Float>.size,        index: 2)
        var starOff = uvOffset
        encoder.setVertexBytes(&starOff, length: MemoryLayout<SIMD2<Float>>.size, index: 3)
        var starSel = selectionState
        encoder.setVertexBytes(&starSel, length: MemoryLayout<SIMD3<Float>>.size, index: 4)
        var zp = zoomProgress
        encoder.setVertexBytes(&zp, length: MemoryLayout<Float>.size, index: 5)

        if let buf = bgStarBuffer, bgStarCount > 0 {
            encoder.setVertexBuffer(buf, offset: 0, index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: bgStarCount)
        }
        if let buf = memoStarBuffer, memoStarCount > 0 {
            encoder.setVertexBuffer(buf, offset: 0, index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: memoStarCount)
        }


        if moonVisible {
            encoder.setRenderPipelineState(moonPipelineState)
            var mpos = SIMD2<Float>(moonPosition.x + uvOffset.x, moonPosition.y - uvOffset.y)
            var msize  = moonPointSize
            var mphase = moonPhase
            encoder.setVertexBytes(&mpos,   length: MemoryLayout<SIMD2<Float>>.size, index: 0)
            encoder.setVertexBytes(&msize,  length: MemoryLayout<Float>.size,        index: 1)
            encoder.setFragmentBytes(&mphase, length: MemoryLayout<Float>.size,      index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
        }

    
        if !memoryPlanets.isEmpty, let pps = planetPipelineState {
            encoder.setRenderPipelineState(pps)
            var planets = memoryPlanets
            var off = uvOffset
            encoder.setVertexBytes(&planets,
                                   length: MemoryLayout<PlanetRenderVertex>.stride * planets.count,
                                   index: 0)
            encoder.setVertexBytes(&off, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: memoryPlanets.count)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
