//
//  MemoryStatusRenderer.swift
//  MacStatus
//
//  内存模块的菜单栏图像渲染：单行紧凑文字 "MEM 53%"，宽度按当前文字动态调整。
//  和 NetworkStatusRenderer 共享同一套 isTemplate 自适应深浅色风格。
//

import AppKit

enum MemoryStatusRenderer {
    private static let labelFont: NSFont =
        .monospacedDigitSystemFont(ofSize: 10, weight: .regular)

    /// 右侧与菜单栏边缘的视觉留白（px）
    private static let horizontalPadding: CGFloat = 4

    private static let paragraphStyle: NSParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.alignment = .right
        p.lineBreakMode = .byClipping
        return p
    }()

    static func render(ratio: Double) -> NSImage {
        let text = "MEM \(PercentFormat.percent(ratio))"
        return renderImage(text: text)
    }

    private static func renderImage(text: String) -> NSImage {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
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
            let lineHeight: CGFloat = 12
            let yOffset = ((rect.height - lineHeight) / 2).rounded()
            let drawRect = NSRect(
                x: 0,
                y: yOffset,
                width: rect.width,
                height: lineHeight
            )
            attributed.draw(with: drawRect, options: .usesLineFragmentOrigin)
            return true
        }
        image.isTemplate = true
        return image
    }
}
