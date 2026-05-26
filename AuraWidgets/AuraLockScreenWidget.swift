import WidgetKit
import SwiftUI

struct AuraLockScreenWidget: Widget {
    let kind: String = "AuraLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuraTimelineProvider()) { entry in
            AuraWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Aura")
        .description("Today's wallpaper on your lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct AuraWidgetEntryView: View {
    let entry: AuraEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        default:
            EmptyView()
        }
    }
}

// MARK: - Circular

private struct CircularView: View {
    let entry: AuraEntry

    var body: some View {
        ZStack {
            if let data = entry.imageData, let img = UIImage(data: data) {
                // Lock screen renders this in `.accented` mode — iOS will tint it
                // monochrome. We still pass the image so the silhouette is recognizable.
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
            }
        }
        .widgetURL(URL(string: "aura://today"))
    }
}

// MARK: - Rectangular

private struct RectangularView: View {
    let entry: AuraEntry

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if let data = entry.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "sparkles")
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.hasContent ? "Today's Aura" : "Aura")
                    .font(.caption2)
                    .opacity(0.7)
                Text(entry.hasContent ? entry.mood : "Tap to generate")
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "aura://today"))
    }
}

// MARK: - Inline

private struct InlineView: View {
    let entry: AuraEntry

    var body: some View {
        if entry.hasContent {
            Text("✨ Today: \(entry.mood)")
        } else {
            Text("✨ Aura — tap to generate today's wallpaper")
        }
    }
}
