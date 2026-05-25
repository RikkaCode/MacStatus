//
//  ControlPanelWindowController.swift
//  MacStatus
//
//  主面板独立窗口（NSWindow + NSHostingController<ControlPanelView>）。
//  LSUIElement=YES 的 menu bar agent app 想弹一个能获焦的窗口，必须先
//  `NSApp.activate(ignoringOtherApps:)` 再 `makeKeyAndOrderFront`，否则窗口
//  会出现在后面或拿不到焦点。
//
//  关闭后用 `isReleasedWhenClosed = false` 保留实例，下次 show 直接复用，
//  避免悬空指针 crash。
//
//  不要给 hosting 设 `sizingOptions = [.preferredContentSize]`：那会让
//  NSHostingView 在 ViewGraph 更新中回写窗口 preferredContentSize，触发
//  `_postWindowNeedsUpdateConstraints` 抛 NSException。窗口给固定初始尺寸
//  + ControlPanelView 自己定宽即可。
//

import AppKit
import SwiftUI

@MainActor
final class ControlPanelWindowController: NSObject {
    /// 主面板需要观察的模块注册表。AppDelegate 先 init 控制器，
    /// 再设置 registry，避免 ModuleRegistry 与控制器互相强引用。
    var registry: ModuleRegistry?

    private var window: NSWindow?

    func showWindow() {
        if window == nil { build() }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        // 必须放在 makeKeyAndOrderFront 之后：此时窗口已上屏且 frame 已稳定，
        // 不会再被 AppKit 的 state restoration / 默认布局策略覆盖。
        centerOnActiveScreen()
    }

    private func build() {
        guard let registry else { return }
        let hosting = NSHostingController(
            rootView: ControlPanelView(registry: registry)
        )

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.contentViewController = hosting
        w.title = "MacStatus 设置"
        w.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        // NSWindow 默认 closed 时被 release，下次 show 会指悬空指针
        w.isReleasedWhenClosed = false
        // 关掉 state restoration，否则 makeKeyAndOrderFront 会恢复上次 frame，
        // 把我们手动 center 的位置覆盖回去
        w.isRestorable = false
        window = w
    }

    /// 把窗口移到当前活动屏幕（鼠标/主屏）的视觉中心稍偏上的位置。
    /// 不依赖 NSWindow.center() —— 它的"基于哪块屏"启发在多屏 / 不可见窗口下不稳定。
    private func centerOnActiveScreen() {
        guard let w = window else { return }
        let screen = NSScreen.main ?? w.screen ?? NSScreen.screens.first
        guard let visible = screen?.visibleFrame else { return }
        let size = w.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + visible.height * 0.08
        )
        w.setFrameOrigin(origin)
    }
}
