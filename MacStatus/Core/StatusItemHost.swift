//
//  StatusItemHost.swift
//  MacStatus
//
//  把一个 StatModule 绑定到一个 NSStatusItem + NSPopover。
//  - 左键 / Ctrl+左键：切换 popover
//  - 右键：弹出"退出"菜单
//  - 订阅模块的 statusImagePublisher，自动刷新菜单栏图像
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemHost: NSObject {
    private let module: StatModule
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellables: Set<AnyCancellable> = []

    init(module: StatModule) {
        self.module = module
        self.statusItem = NSStatusBar.system.statusItem(withLength: module.statusItemWidth)
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

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let quitItem = NSMenuItem(
            title: "退出 NetSpeed",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        quitItem.isEnabled = true
        menu.addItem(quitItem)
        return menu
    }()

    private func showContextMenu() {
        if popover.isShown { popover.performClose(nil) }
        statusItem.menu = contextMenu
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
