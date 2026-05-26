import SwiftUI

/// Brief animated splash shown on app launch. Fades out after ~1.5s.
/// The static iOS Launch Screen (Info.plist UILaunchScreen with a midnight color)
/// covers the milliseconds before this view appears, preventing a white flash.
struct SplashView: View {
    @State private var orbScale: CGFloat = 0.55
    @State private var orbOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var titleOpacity: Double = 0

    var body: some View {
        ZStack {
            AuraTheme.backgroundGradient.ignoresSafeArea()

            // Soft purple halo behind the orb
            Circle()
                .fill(AuraTheme.aurora1)
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .opacity(glowOpacity * 0.7)
                .offset(y: -10)

            // Gold halo bottom-right of orb
            Circle()
                .fill(AuraTheme.accent)
                .frame(width: 160, height: 160)
                .blur(radius: 60)
                .opacity(glowOpacity * 0.4)
                .offset(x: 40, y: 60)

            // The orb itself (matches the app icon)
            ZStack {
                Circle()
                    .fill(AuraTheme.auroraGradient)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.45), .clear],
                            center: UnitPoint(x: 0.3, y: 0.25),
                            startRadius: 4,
                            endRadius: 70
                        )
                    )
            }
            .frame(width: 140, height: 140)
            .shadow(color: AuraTheme.aurora1.opacity(0.5), radius: 30)
            .scaleEffect(orbScale)
            .opacity(orbOpacity)

            VStack {
                Spacer()
                Text("Aura")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .padding(.bottom, 80)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                orbScale = 1.0
                orbOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                glowOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                titleOpacity = 1.0
            }
        }
    }
}
