//
//  WatchApp.swift
//  strongbox.watch.pro Watch App
//
//  Created by Strongbox on 07/12/2024.
//  Copyright © 2024 Mark McGuill. All rights reserved.
//

import SwiftUI

@main
struct WatchApp: App {
    
    let syncer: WatchClientSyncer!
    let model: WatchAppModel!

    init() {
        model = WatchAppModel()

        syncer = WatchClientSyncer(model: model)

        activate()
    }

    func activate() {
        Task {
            do {
                let ret = try await syncer.activate()

                swlog("🟢 Watch activated: \(ret)")
            } catch {
                swlog("🔴 Error activating: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeScreen()
                .environmentObject(model)
                .onLoad {
                    model.refreshSettings() 
                }
                .onOpenURL { url in
                    if url.host == "2fa" {
                        model.selectTab(tab: .twoFactorCodes)
                    }
                }
        }
    }
}
