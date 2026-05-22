//
//  StatusItemController.swift
//  test
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let tracker: SpeedTracker

    private var cancellables: Set<AnyCancellable> = []

    private static let lineFont: NSFont =
        .monospacedDigitSystemFont(ofSize: 9, weight: .regular)

    private static let paragraphStyle: NSParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.alignment = .right
        p.lineSpacing = 0
        p.maximumLineHeight = 10
        p.minimumLineHeight = 10
        p.lineBreakMode = .byClipping
        return p
    }()

    init(tracker: SpeedTracker) {
        self.tracker = tracker
        self.statusItem = NSStatusBar.system.statusItem(withLength: 72)
        super.init()

        setupButton()
        setupPopover()
        bind()
        render(up: 0, down: 0)
    }

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemAction(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageOnly
        button.image = nil
        button.title = ""
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

    private func setupPopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 360)
        popover.contentViewController = NSHostingController(
            rootView: StatsView(tracker: tracker)
        )
    }

    private func bind() {
        tracker.$currentUpPerSec
            .combineLatest(tracker.$currentDownPerSec)
            .receive(on: RunLoop.main)
            .sink { [weak self] up, down in
                self?.render(up: up, down: down)
            }
            .store(in: &cancellables)
    }

    private func render(up: UInt64, down: UInt64) {
        guard let button = statusItem.button else { return }
        let text = "↑ \(ByteFormat.rate(up))\n↓ \(ByteFormat.rate(down))"
        button.image = Self.renderTitleImage(text: text)
    }

    private static func renderTitleImage(text: String) -> NSImage {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: lineFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.black,
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let canvas = NSSize(width: 72, height: 22)
        let image = NSImage(size: canvas, flipped: false) { rect in
            let lineHeight: CGFloat = 10
            let totalHeight = lineHeight * 2
            let yOffset = ((rect.height - totalHeight) / 2).rounded()
            let drawRect = NSRect(
                x: 0,
                y: yOffset,
                width: rect.width - 4,
                height: totalHeight
            )
            attributed.draw(with: drawRect, options: .usesLineFragmentOrigin)
            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func statusItemAction(_ sender: Any?) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
        let isControlClick = event?.type == .leftMouseUp
            && event?.modifierFlags.contains(.control) == true
        if isRightClick || isControlClick {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func showContextMenu() {
        if popover.isShown {
            popover.performClose(nil)
        }
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
