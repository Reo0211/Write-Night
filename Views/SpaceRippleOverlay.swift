import SwiftUI

struct SpaceRippleOverlay: View {
    let position:   CGPoint
    let onComplete: () -> Void

    @State private var scale:   CGFloat = 0.1
    @State private var opacity: Double  = 0.7

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .strokeBorder(Color.white.opacity(opacity), lineWidth: 0.8)
                .frame(width: 90, height: 90)
                .scaleEffect(scale)
                .blur(radius: 0.5)
                .position(position)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                scale   = 1.0
                opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                onComplete()
            }
        }
    }
}
