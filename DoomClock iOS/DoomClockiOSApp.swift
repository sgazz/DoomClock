//
//  DoomClockiOSApp.swift
//  DoomClock iOS
//
//  Created by Gazza on 20. 05. 2026..
//

import SwiftUI

@main
struct DoomClockiOSApp: App {
    @StateObject private var viewModel = CountdownViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
        }
    }
}