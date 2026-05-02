//
//  EkkoAppApp.swift
//  EkkoApp
//
//  Created by Guilherme Palma on 02/05/26.
//

import SwiftUI

@main
struct EkkoAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
