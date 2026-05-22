//
//  NetworkSampler.swift
//  test
//

import Darwin
import Foundation

struct InterfaceSnapshot: Sendable {
    let name: String
    let ibytes: UInt64
    let obytes: UInt64
}

enum NetworkSampler {
    nonisolated private static let blocklistPrefixes: [String] = [
        "lo", "utun", "awdl", "llw", "anpi", "ap",
        "bridge", "gif", "stf", "XHC", "vmenet", "ipsec",
    ]

    nonisolated static func sample() -> [InterfaceSnapshot] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }

        var out: [InterfaceSnapshot] = []
        for cursor in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let ifa = cursor.pointee
            guard let addr = ifa.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            let name = String(cString: ifa.ifa_name)
            guard !isBlocked(name) else { continue }
            guard let raw = ifa.ifa_data else { continue }
            let data = raw.assumingMemoryBound(to: if_data.self)
            out.append(InterfaceSnapshot(
                name: name,
                ibytes: UInt64(data.pointee.ifi_ibytes),
                obytes: UInt64(data.pointee.ifi_obytes)
            ))
        }
        return out
    }

    private nonisolated static func isBlocked(_ name: String) -> Bool {
        for prefix in blocklistPrefixes where name.hasPrefix(prefix) {
            return true
        }
        return false
    }
}
