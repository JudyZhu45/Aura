import WidgetKit
import SwiftUI

/// Home-screen widgets render in `.fullColor` mode (unlike Lock-Screen widgets
/// which iOS forces to monochrome). So here we can show the actual wallpaper
/// JPEG as the widget background.
struct AuraHomeScreenWidget: Widget {
    let kind: String = "AuraHomeScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuraTimelineProvider()) { entry in
            AuraHomeScreenEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    backgroundLayer(for: entry)
                }
        }
        .configurationDisplayName("Today's Aura")
        .description("Full-color wallpaper preview on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    @ViewBuilder
    private func backgroundLayer(for entry: AuraEntry) -> some View {
        if let data = entry.imageData, let img = UIImage(data: data) {
            ZStack {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                // Dark gradient overlay so text is readable on any image.
                LinearGradient(
                    colors: [.black.opacity(0.05), .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.07, green: 0.09, blue: 0.20),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct AuraHomeScreenEntryView: View {
    let entry: AuraEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallHomeView(entry: entry)
        case .systemMedium: MediumHomeView(entry: entry)
        default: EmptyView()
        }
    }
}

private struct SmallHomeView: View {
    let entry: AuraEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer(minLength: 0)
            if entry.hasContent {
                Text(entry.mood)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                Text(entry.displayDate, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            } else {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.white)
                Text("Tap to start")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "aura://today"))
    }
}

private struct MediumHomeView: View {
    let entry: AuraEntry

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.hasContent ? "Today's Aura" : "Aura")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.4), radius: 2)
                if entry.hasContent {
                    Text(entry.mood)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                } else {
                    Text("Tap to generate")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 4)
                if entry.hasContent {
                    Text(entry.displayDate, format: .dateTime.weekday(.wide).month().day())
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.4), radius: 2)
                }
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "aura://today"))
    }
}
