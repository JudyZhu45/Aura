import SwiftUI

enum AuraTheme {
    static let midnight = Color(red: 0.04, green: 0.05, blue: 0.12)
    static let deepNavy = Color(red: 0.07, green: 0.09, blue: 0.20)
    static let accent = Color(red: 0.95, green: 0.82, blue: 0.50) // soft gold
    static let aurora1 = Color(red: 0.45, green: 0.30, blue: 0.95)
    static let aurora2 = Color(red: 0.20, green: 0.78, blue: 0.86)

    static let backgroundGradient = LinearGradient(
        colors: [midnight, deepNavy],
        startPoint: .top,
        endPoint: .bottom
    )

    static let auroraGradient = LinearGradient(
        colors: [aurora1, aurora2, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct FrostedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct PrimaryAuroraButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AuraTheme.auroraGradient)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
