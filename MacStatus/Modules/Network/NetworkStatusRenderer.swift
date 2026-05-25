//
//  NetworkStatusRenderer.swift
//  MacStatus
//
//  把上下行速度渲染成菜单栏 NSImage（两行紧凑文字，宽度按当前文字动态调整）。
//  绕过 NSButtonCell 多行 baseline 居中的固有问题：用 NSImage + isTemplate
//  自适应深浅色。
//

import AppKit

enum NetworkStatusRenderer {
    private static let lineFont: NSFont =
        .monospacedDigitSystemFont(ofSize: 9, weight: .regular)

    /// 右侧与菜单栏边缘的视觉留白（px）
    private static let horizontalPadding: CGFloat = 4

    private static let paragraphStyle: NSParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.alignment = .right
        p.lineSpacing = 0
        p.maximumLineHeight = 10
        p.minimumLineHeight = 10
        p.lineBreakMode = .byClipping
        return p
    }()

    /// 渲染上下行速度为模板图像。isTemplate=true 让系统自适应深浅色菜单栏。
    static func render(up: UInt64, down: UInt64) -> NSImage {
        let text = "↑ \(ByteFormat.rate(up))\n↓ \(ByteFormat.rate(down))"
        return renderImage(text: text)
    }

    private static func renderImage(text: String) -> NSImage {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: lineFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.black,
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let bounds = attributed.boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude,
                         height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin
        )
        let textWidth = ceil(bounds.width)
        let canvasWidth = textWidth + horizontalPadding
        let canvas = NSSize(width: canvasWidth, height: 22)
        let image = NSImage(size: canvas, flipped: false) { rect in
            let lineHeight: CGFloat = 10
            let totalHeight = lineHeight * 2
            let yOffset = ((rect.height - totalHeight) / 2).rounded()
            let drawRect = NSRect(
                x: 0,
                y: yOffset,
                width: rect.width,
                height: totalHeight
            )
            attributed.draw(with: drawRect, options: .usesLineFragmentOrigin)
            return true
        }
        image.isTemplate = true
        return image
    }
}
