import SwiftUI

struct StandClockView: View {
    let currentTime: Date

    @State private var secondOpacity: Double = 1.0
    @State private var orbitProgress: CGFloat = 0.0  // 0.0〜1.0 周回進捗

    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    private var hour:   Int { calendar.component(.hour,   from: currentTime) }
    private var minute: Int { calendar.component(.minute, from: currentTime) }
    private var second: Int { calendar.component(.second, from: currentTime) }

    private var hourStr:   String { String(format: "%02d", hour) }
    private var minuteStr: String { String(format: "%02d", minute) }
    private var secondStr: String { String(format: "%02d", second) }

    private var dateStr: String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale   = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日　EEEE"
        return f.string(from: currentTime)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ── 日付
                Text(dateStr)
                    .font(.custom("HiraMinProN-W3", size: 15))
                    .foregroundColor(.white.opacity(0.38))
                    .tracking(2)
                    .padding(.bottom, 14)

                // ── 時刻メイン
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(hourStr)
                        .font(.custom("HiraMinProN-W3", size: 96))
                        .foregroundColor(.white.opacity(0.82))
                        .monospacedDigit()

                    Text(":")
                        .font(.custom("HiraMinProN-W3", size: 80))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.horizontal, 4)
                        .offset(y: -6)

                    Text(minuteStr)
                        .font(.custom("HiraMinProN-W3", size: 96))
                        .foregroundColor(.white.opacity(0.82))
                        .monospacedDigit()

                    Text(secondStr)
                        .font(.custom("HiraMinProN-W3", size: 28))
                        .foregroundColor(.white.opacity(0.28))
                        .monospacedDigit()
                        .padding(.leading, 10)
                        .offset(y: -8)
                        .opacity(secondOpacity)
                        .onAppear { blinkSecond() }
                        .onChange(of: second) { _ in blinkSecond() }
                }

                // ── 区切り線
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 240, height: 0.5)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                Text("スタンド時計モード")
                    .font(.custom("HiraMinProN-W3", size: 11))
                    .foregroundColor(.white.opacity(0.18))
                    .tracking(2)
            }
            .padding(.horizontal, 52)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.001))  // より透明
            )
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .opacity(0.75)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 6).repeatForever(autoreverses: false)
            ) {
                orbitProgress = 1.0
            }
        }
    }

    private func blinkSecond() {
        secondOpacity = 0.15
        withAnimation(.easeOut(duration: 0.3)) {
            secondOpacity = 1.0
        }
    }
}

// MARK: - OrbitingLight
//
//private struct OrbitingLight: View {
//    let progress:     CGFloat
//    let size:         CGSize
//    let cornerRadius: CGFloat
//
//    var body: some View {
//        Canvas { ctx, _ in
//            let pt   = pointOnRoundedRect(progress: progress, size: size, r: cornerRadius)
//            let tail = 0.06  // 尾の長さ（周長比）
//
//            // 尾（グラデーション的に複数点で描く）
//            let steps = 30
//            for i in (0..<steps).reversed() {
//                let t  = CGFloat(i) / CGFloat(steps)
//                let p  = (progress - t * tail + 2.0).truncatingRemainder(dividingBy: 1.0)
//                let tp = pointOnRoundedRect(progress: p, size: size, r: cornerRadius)
//                let alpha = Double(1.0 - t) * 0.45
//                ctx.fill(
//                    Path(ellipseIn: CGRect(x: tp.x - 1.5, y: tp.y - 1.5, width: 3, height: 3)),
//                    with: .color(Color.white.opacity(alpha))
//                )
//            }
//
//            // 光点（頭）
//            let glow = Path(ellipseIn: CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10))
//            ctx.fill(glow, with: .color(Color.white.opacity(0.12)))
//            let core = Path(ellipseIn: CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4))
//            ctx.fill(core, with: .color(Color.white.opacity(0.70)))
//        }
//        .frame(width: size.width, height: size.height)
//        .allowsHitTesting(false)
//    }
//
//    /// 0.0〜1.0 の progress を角丸矩形上の座標に変換
//    private func pointOnRoundedRect(progress: CGFloat, size: CGSize, r: CGFloat) -> CGPoint {
//        let W = size.width, H = size.height
//        // 周長の内訳: 直線4辺 + 角4つ（合計2πr）
//        let straightH = H - 2 * r
//        let straightW = W - 2 * r
//        let arcLen    = CGFloat.pi * 2 * r   // 4隅合計
//        let total     = 2 * straightW + 2 * straightH + arcLen
//
//        var d = progress * total
//
//        // 上辺（左→右）
//        let seg1 = straightW
//        if d < seg1 { return CGPoint(x: r + d, y: 0) }
//        d -= seg1
//
//        // 右上コーナー
//        let seg2 = CGFloat.pi / 2 * r
//        if d < seg2 {
//            let a = -CGFloat.pi / 2 + d / r
//            return CGPoint(x: W - r + cos(a) * r, y: r + sin(a) * r)
//        }
//        d -= seg2
//
//        // 右辺（上→下）
//        let seg3 = straightH
//        if d < seg3 { return CGPoint(x: W, y: r + d) }
//        d -= seg3
//
//        // 右下コーナー
//        let seg4 = CGFloat.pi / 2 * r
//        if d < seg4 {
//            let a = d / r
//            return CGPoint(x: W - r + cos(a) * r, y: H - r + sin(a) * r)
//        }
//        d -= seg4
//
//        // 下辺（右→左）
//        let seg5 = straightW
//        if d < seg5 { return CGPoint(x: W - r - d, y: H) }
//        d -= seg5
//
//        // 左下コーナー
//        let seg6 = CGFloat.pi / 2 * r
//        if d < seg6 {
//            let a = CGFloat.pi / 2 + d / r
//            return CGPoint(x: r + cos(a) * r, y: H - r + sin(a) * r)
//        }
//        d -= seg6
//
//        // 左辺（下→上）
//        let seg7 = straightH
//        if d < seg7 { return CGPoint(x: 0, y: H - r - d) }
//        d -= seg7
//
//        // 左上コーナー
//        let a = CGFloat.pi + d / r
//        return CGPoint(x: r + cos(a) * r, y: r + sin(a) * r)
//    }
//}

// MARK: - StandClockOverlay

struct StandClockOverlay: View {
    let currentTime: Date

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()

                StandClockView(currentTime: currentTime)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}
