//
//  DoomClockApp.swift
//  DoomClock Watch App
//
//  Created by Gazza on 4. 5. 2026..
//

import SwiftUI

@main
struct DoomClockWatchApp: App {
    @StateObject private var viewModel = CountdownViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
        }
    }
}
