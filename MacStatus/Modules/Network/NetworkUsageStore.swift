//
//  NetworkUsageStore.swift
//  MacStatus
//
//  Network 模块的 UserDefaults 持久化层：分接口今日/本月累计 + 跨日/跨月归档。
//

import Foundation

struct IfaceUsage: Codable, Equatable, Sendable {
    var inBytes: UInt64 = 0
    var outBytes: UInt64 = 0
}

@MainActor
final class NetworkUsageStore {
    private let defaults: UserDefaults
    private let todayKey = "usage.today.json"
    private let todayDateKey = "usage.today.date"
    private let monthKey = "usage.month.json"
    private let monthIdKey = "usage.month.yearMonth"
    private let historyPrefix = "usage.history."

    private(set) var today: [String: IfaceUsage]
    private(set) var month: [String: IfaceUsage]
    private(set) var todayDate: String
    private(set) var monthId: String

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        self.today = Self.loadMap(defaults: defaults, key: todayKey)
        self.month = Self.loadMap(defaults: defaults, key: monthKey)
        self.todayDate = defaults.string(forKey: todayDateKey) ?? Self.dayString(now)
        self.monthId = defaults.string(forKey: monthIdKey) ?? Self.monthString(now)
        rollover(now: now)
    }

    func accumulate(iface: String, inBytes: UInt64, outBytes: UInt64, now: Date = Date()) {
        rollover(now: now)
        var t = today[iface] ?? IfaceUsage()
        t.inBytes &+= inBytes
        t.outBytes &+= outBytes
        today[iface] = t

        var m = month[iface] ?? IfaceUsage()
        m.inBytes &+= inBytes
        m.outBytes &+= outBytes
        month[iface] = m

        persist()
    }

    func resetToday() {
        today.removeAll()
        persist()
    }

    func resetMonth() {
        month.removeAll()
        persist()
    }

    func totals(map: [String: IfaceUsage]) -> (inBytes: UInt64, outBytes: UInt64) {
        var i: UInt64 = 0
        var o: UInt64 = 0
        for v in map.values {
            i &+= v.inBytes
            o &+= v.outBytes
        }
        return (i, o)
    }

    private func rollover(now: Date) {
        let curDay = Self.dayString(now)
        if curDay != todayDate {
            todayDate = curDay
            today.removeAll()
        }
        let curMonth = Self.monthString(now)
        if curMonth != monthId {
            if !month.isEmpty,
               let data = try? JSONEncoder().encode(month) {
                defaults.set(data, forKey: historyPrefix + monthId)
            }
            monthId = curMonth
            month.removeAll()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(today) {
            defaults.set(data, forKey: todayKey)
        }
        if let data = try? JSONEncoder().encode(month) {
            defaults.set(data, forKey: monthKey)
        }
        defaults.set(todayDate, forKey: todayDateKey)
        defaults.set(monthId, forKey: monthIdKey)
    }

    private static func loadMap(defaults: UserDefaults, key: String) -> [String: IfaceUsage] {
        guard let data = defaults.data(forKey: key),
              let map = try? JSONDecoder().decode([String: IfaceUsage].self, from: data)
        else { return [:] }
        return map
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static func dayString(_ d: Date) -> String { dayFormatter.string(from: d) }
    private static func monthString(_ d: Date) -> String { monthFormatter.string(from: d) }
}
