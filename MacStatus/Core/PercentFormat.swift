//
//  PercentFormat.swift
//  MacStatus
//
//  统一的百分比格式化：内存、未来的 CPU 使用率等都会用到。
//

import Foundation

enum PercentFormat {
    /// 0.0 ~ 1.0 -> "53%"。负值视为 0，>1 截断到 100%
    static func percent(_ ratio: Double) -> String {
        let clamped = max(0.0, min(1.0, ratio))
        return "\(Int((clamped * 100).rounded()))%"
    }
}
