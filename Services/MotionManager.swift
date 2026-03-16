import CoreMotion
import Combine

final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    @Published private(set) var offsetX: Float = 0
    @Published private(set) var offsetY: Float = 0

    private let motion = CMMotionManager()
    private let smoothing: Float = 0.06

    private var baseRoll:  Double? = nil
    private var basePitch: Double? = nil

    private init() {}

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let roll  = data.attitude.roll
            let pitch = data.attitude.pitch

            // 初回基準値を設定
            if baseRoll  == nil { baseRoll  = roll  }
            if basePitch == nil { basePitch = pitch }

            let dx = Float(roll  - (baseRoll  ?? roll))
            let dy = Float(pitch - (basePitch ?? pitch))

            // 視差強度（0.04 = 画面幅の4%まで動く）
            let strength: Float = 0.04
            let targetX = max(-1, min(1, dx)) * strength
            let targetY = max(-1, min(1, dy)) * strength

            // ローパスフィルタで滑らかに追従
            self.offsetX += (targetX - self.offsetX) * self.smoothing
            self.offsetY += (targetY - self.offsetY) * self.smoothing
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        baseRoll  = nil
        basePitch = nil
    }

    /// 端末を持ち直したとき基準をリセット
    func recalibrate() {
        baseRoll  = nil
        basePitch = nil
    }
}
