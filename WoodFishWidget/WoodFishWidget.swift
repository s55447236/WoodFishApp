import WidgetKit
import SwiftUI

class Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WoodFishWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            Image("woodfish")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            Text("轻轻一敲，功德自在")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "703232"))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .containerBackground(for: .widget) {
            Color(hex: "F8F5E4")
        }
    }
}

struct WoodFishWidget: Widget {
    private let kind: String = "com.xumengzhang.WoodFishApp.WoodFishWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            WoodFishWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("随身拜-木鱼")
        .description("显示木鱼")
        .supportedFamilies([.systemSmall])
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
