//
//  AppDelegate.swift
//  MacStatus
//
//  App 装配总入口：构造 ModuleRegistry，把 Network / Memory 等模块注册并激活；
//  订阅系统睡眠/唤醒通知，统一转发给所有模块。
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let registry = ModuleRegistry()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 注册顺序 ≈ 菜单栏出现顺序（macOS 默认新加的在最左）
        // 先注册 Network（更靠右）再注册 Memory（更靠左）
        registry.register(NetworkModule())
        registry.register(MemoryModule())
        registry.activate()

        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            self,
            selector: #selector(handleWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        wsCenter.addObserver(
            self,
            selector: #selector(handleDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        registry.stopAll()
        UserDefaults.standard.synchronize()
    }

    @objc private func handleWillSleep() {
        registry.stopAll()
    }

    @objc private func handleDidWake() {
        registry.wakeAll()
    }
}
