//
//  AdvanceWidgetBundle.swift
//  AdvanceWidget
//
//  Created by Zach Babb on 9/13/25.
//

import WidgetKit
import SwiftUI

@main
struct AdvanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        AdvanceWidget()
        AdvanceWidgetControl()
        AdvanceWidgetBarControl()
        AdvanceWidgetLiveActivity()
    }
}
