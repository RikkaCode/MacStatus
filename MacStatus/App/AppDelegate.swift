//
//  AppDelegate.swift
//  MacStatus
//
//  App 装配总入口：
//  - 构造 ModuleRegistry + ControlPanelWindowController，互相牵线
//  - 注册 Network / Memory 等模块并激活
//  - 订阅 registry.visibility：所有模块都隐藏时挂出 FallbackStatusItem，避免 UI 自锁
//  - 首次启动自动弹一次主面板（让用户看见"原来这里能开关模块"）
//  - 处理 reopen：app 已在跑、再次双击 .app 时再弹一次主面板
//  - 订阅系统睡眠/唤醒通知，统一转发给所有模块
//

import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let registry = ModuleRegistry()
    private let controlPanel = ControlPanelWindowController()
    private lazy var fallback = FallbackStatusItem(controlPanel: controlPanel)
    private var visibilityCancellable: AnyCancellable?

    private let firstLaunchKey = "module.visible.firstLaunchDone"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        controlPanel.registry = registry
        registry.controlPanel = controlPanel

        // 注册顺序 ≈ 菜单栏出现顺序（macOS 默认新加的在最左）
        // 先注册 Network（更靠右）再注册 Memory（更靠左）
        registry.register(NetworkModule())
        registry.register(MemoryModule())
        registry.activate()

        // 订阅模块可见性：全部隐藏时挂兜底齿轮项，至少保留一个 UI 入口；
        // 任一模块重新可见就摘掉它，避免冗余槽位。
        // @Published 会立即向新订阅者吐出当前值，所以 activate() 之后立刻订阅即可。
        visibilityCancellable = registry.$visibility
            .map { $0.values.filter { $0 }.count == 0 }
            .removeDuplicates()
            .sink { [weak self] allHidden in
                guard let self else { return }
                if allHidden {
                    self.fallback.install()
                } else {
                    self.fallback.remove()
                }
            }

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

        // 第一次启动自动把主面板亮出来一次
        if !UserDefaults.standard.bool(forKey: firstLaunchKey) {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            controlPanel.showWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        registry.stopAll()
        UserDefaults.standard.synchronize()
    }

    /// 处理 app 已在跑、用户从 Finder 双击 .app 的情况：再次弹出主面板。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controlPanel.showWindow()
        return true
    }

    @objc private func handleWillSleep() {
        registry.stopAll()
    }

    @objc private func handleDidWake() {
        registry.wakeAll()
    }
}
