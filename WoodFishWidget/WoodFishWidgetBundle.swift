//
//  WoodFishWidgetBundle.swift
//  WoodFishWidget
//
//  Created by 张栩萌 on 2025/3/7.
//

import WidgetKit
import SwiftUI

@main
struct WoodFishWidgetBundle: WidgetBundle {
    var body: some Widget {
        WoodFishWidget()
        WoodFishWidgetControl()
        WoodFishWidgetLiveActivity()
    }
}
