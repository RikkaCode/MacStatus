//
//  MemoryStatusRenderer.swift
//  MacStatus
//
//  内存模块的菜单栏图像渲染：单行紧凑文字 "MEM 53%"。
//  和 NetworkStatusRenderer 共享同一套 isTemplate 自适应深浅色风格。
//

import AppKit

enum MemoryStatusRenderer {
    private static let labelFont: NSFont =
        .monospacedDigitSystemFont(ofSize: 10, weight: .regular)

    private static let paragraphStyle: NSParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.alignment = .right
        p.lineBreakMode = .byClipping
        return p
    }()

    /// 菜单栏 NSStatusItem 用的固定宽度
    static let statusItemWidth: CGFloat = 56

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
        let canvas = NSSize(width: statusItemWidth, height: 22)
        let image = NSImage(size: canvas, flipped: false) { rect in
            let lineHeight: CGFloat = 12
            let yOffset = ((rect.height - lineHeight) / 2).rounded()
            let drawRect = NSRect(
                x: 0,
                y: yOffset,
                width: rect.width - 4,
                height: lineHeight
            )
            attributed.draw(with: drawRect, options: .usesLineFragmentOrigin)
            return true
        }
        image.isTemplate = true
        return image
    }
}
