//
//  MacStatusApp.swift
//  MacStatus
//
//  @main 入口。LSUIElement=YES 时必须用 Settings 而非 WindowGroup，
//  否则会闪一下幽灵窗口并破坏 Cmd-Q 行为。
//

import SwiftUI

@main
struct MacStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
