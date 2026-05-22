//
//  testApp.swift
//  test
//
//  Created by Rikka Takanashi on 2026/5/22.
//

import SwiftUI

@main
struct testApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
