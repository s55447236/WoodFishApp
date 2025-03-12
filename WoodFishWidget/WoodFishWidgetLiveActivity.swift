//
//  WoodFishWidgetLiveActivity.swift
//  WoodFishWidget
//
//  Created by 张栩萌 on 2025/3/7.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WoodFishWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WoodFishWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WoodFishWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WoodFishWidgetAttributes {
    fileprivate static var preview: WoodFishWidgetAttributes {
        WoodFishWidgetAttributes(name: "World")
    }
}

extension WoodFishWidgetAttributes.ContentState {
    fileprivate static var smiley: WoodFishWidgetAttributes.ContentState {
        WoodFishWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WoodFishWidgetAttributes.ContentState {
         WoodFishWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WoodFishWidgetAttributes.preview) {
   WoodFishWidgetLiveActivity()
} contentStates: {
    WoodFishWidgetAttributes.ContentState.smiley
    WoodFishWidgetAttributes.ContentState.starEyes
}
