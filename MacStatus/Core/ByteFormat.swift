//
//  ByteFormat.swift
//  MacStatus
//

import Foundation

enum ByteFormat {
    private static let rateFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .binary
        f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        f.zeroPadsFractionDigits = false
        f.includesUnit = true
        f.isAdaptive = true
        f.allowsNonnumericFormatting = false
        return f
    }()

    private static let totalFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .binary
        f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        f.includesUnit = true
        f.isAdaptive = true
        f.allowsNonnumericFormatting = false
        return f
    }()

    static func rate(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond == 0 { return "0 B/s" }
        return rateFormatter.string(fromByteCount: Int64(min(bytesPerSecond, UInt64(Int64.max)))) + "/s"
    }

    static func total(_ bytes: UInt64) -> String {
        if bytes == 0 { return "0 B" }
        return totalFormatter.string(fromByteCount: Int64(min(bytes, UInt64(Int64.max))))
    }
}
