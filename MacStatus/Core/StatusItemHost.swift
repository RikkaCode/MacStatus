//
//  StatusItemHost.swift
//  MacStatus
//
//  把一个 StatModule 绑定到一个 NSStatusItem + NSPopover。
//  - 左键 / Ctrl+左键：切换 popover
//  - 右键：弹出三项菜单（打开主面板… / 隐藏 [模块名] / 退出 MacStatus）
//  - 订阅模块的 statusImagePublisher，自动刷新菜单栏图像
//
//  registry / controlPanel 都是 weak，避免和 app 级单例形成强环。
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemHost: NSObject {
    private let module: StatModule
    private weak var registry: ModuleRegistry?
    private weak var controlPanel: ControlPanelWindowController?

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    init(
        module: StatModule,
        registry: ModuleRegistry?,
        controlPanel: ControlPanelWindowController?
    ) {
        self.module = module
        self.registry = registry
        self.controlPanel = controlPanel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupButton()
        setupPopover()
        bind()
    }

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageOnly
        button.title = ""
    }

    private func setupPopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 360)
        popover.contentViewController = NSHostingController(rootView: module.makeDetailView())
    }

    private func bind() {
        module.statusImagePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                self?.statusItem.button?.image = image
            }
            .store(in: &cancellables)
    }

    // MARK: - Visibility

    /// 设置该模块的菜单栏槽位可见性。隐藏前如果 popover 还开着先关掉，
    /// 否则 popover 会浮空显示。
    func setVisible(_ visible: Bool) {
        if !visible, popover.isShown {
            popover.performClose(nil)
        }
        statusItem.isVisible = visible
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
            togglePopover(sender)
        }
    }

    private func makeContextMenu() -> NSMenu {
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

        let hideItem = NSMenuItem(
            title: "隐藏 \(module.displayName)",
            action: #selector(hideThisModule),
            keyEquivalent: ""
        )
        hideItem.target = self
        menu.addItem(hideItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 MacStatus",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func showContextMenu() {
        if popover.isShown { popover.performClose(nil) }
        let menu = makeContextMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Menu actions

    @objc private func openControlPanel() {
        controlPanel?.showWindow()
    }

    @objc private func hideThisModule() {
        registry?.setVisible(id: module.id, visible: false)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
