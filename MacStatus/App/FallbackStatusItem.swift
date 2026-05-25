//
//  FallbackStatusItem.swift
//  MacStatus
//
//  当所有 StatModule 都被隐藏时，挂出一个兜底的菜单栏入口（齿轮图标），
//  保证用户始终能呼出主面板，避免"全部隐藏 + 关闭面板"导致 UI 自锁。
//
//  install/remove 由 AppDelegate 根据 ModuleRegistry.visibility 的实时计数驱动。
//  install/remove 都是幂等操作。
//

import AppKit

@MainActor
final class FallbackStatusItem: NSObject {
    private weak var controlPanel: ControlPanelWindowController?
    private var statusItem: NSStatusItem?

    init(controlPanel: ControlPanelWindowController?) {
        self.controlPanel = controlPanel
        super.init()
    }

    /// 在菜单栏挂出齿轮图标的兜底项；重复调用幂等
    func install() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(
                systemSymbolName: "gearshape",
                accessibilityDescription: "MacStatus 设置"
            )
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageOnly
            button.title = ""
        }
        statusItem = item
    }

    /// 从菜单栏摘掉兜底项；重复调用幂等
    func remove() {
        guard let item = statusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
    }

    // MARK: - Click routing

    @objc private func handleClick(_ sender: Any?) {
        let event = NSApp.currentEvent
        let isRight = event?.type == .rightMouseUp
        let isCtrlLeft = event?.type == .leftMouseUp
            && event?.modifierFlags.contains(.control) == true
        if isRight || isCtrlLeft {
            showContextMenu()
        } else {
            controlPanel?.showWindow()
        }
    }

    private func showContextMenu() {
        guard let item = statusItem else { return }
        let menu = NSMenu()
        menu.autoenablesItems = false

        let openItem = NSMenuItem(
            title: "打开主面板…",
            action: #selector(openControlPanel),
            keyEquivalent: ","
        )
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 MacStatus",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func openControlPanel() {
        controlPanel?.showWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
