//
//  SpeedTracker.swift
//  test
//

import Foundation
import Combine

@MainActor
final class SpeedTracker: ObservableObject {
    /// 单次 1 秒采样的字节差，超过此阈值视为计数器重置（接口 flap / 系统唤醒），丢弃此次采样
    private let sanityCeiling: UInt64 = 10_000_000_000

    @Published private(set) var currentDownPerSec: UInt64 = 0
    @Published private(set) var currentUpPerSec: UInt64 = 0
    @Published private(set) var perInterfaceRate: [String: (down: UInt64, up: UInt64)] = [:]
    @Published private(set) var todaySnapshot: [String: IfaceUsage] = [:]
    @Published private(set) var monthSnapshot: [String: IfaceUsage] = [:]

    let store: UsageStore

    private var previous: [String: InterfaceSnapshot] = [:]
    private var needsRebaseline: Bool = true
    private var timer: DispatchSourceTimer?

    init(store: UsageStore) {
        self.store = store
        self.todaySnapshot = store.today
        self.monthSnapshot = store.month
    }

    func start() {
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        t.schedule(deadline: .now() + 1.0, repeating: 1.0, leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in
            let snapshot = NetworkSampler.sample()
            Task { @MainActor [weak self] in
                self?.ingest(snapshot)
            }
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func markRebaseline() {
        needsRebaseline = true
        previous.removeAll()
        currentDownPerSec = 0
        currentUpPerSec = 0
        perInterfaceRate.removeAll()
    }

    func resetToday() {
        store.resetToday()
        todaySnapshot = store.today
    }

    func resetMonth() {
        store.resetMonth()
        monthSnapshot = store.month
    }

    private func ingest(_ samples: [InterfaceSnapshot]) {
        defer {
            previous = Dictionary(uniqueKeysWithValues: samples.map { ($0.name, $0) })
        }

        if needsRebaseline {
            needsRebaseline = false
            return
        }

        var totalDown: UInt64 = 0
        var totalUp: UInt64 = 0
        var perIface: [String: (down: UInt64, up: UInt64)] = [:]

        for sample in samples {
            guard let prev = previous[sample.name] else {
                // 新出现的接口，下次再计差
                continue
            }
            let dIn = wrapDelta(new: sample.ibytes, old: prev.ibytes)
            let dOut = wrapDelta(new: sample.obytes, old: prev.obytes)

            // sanity check: 单秒 > 10GB 视为计数器重置
            guard dIn < sanityCeiling, dOut < sanityCeiling else { continue }

            totalDown &+= dIn
            totalUp &+= dOut
            perIface[sample.name] = (dIn, dOut)
            store.accumulate(iface: sample.name, inBytes: dIn, outBytes: dOut)
        }

        currentDownPerSec = totalDown
        currentUpPerSec = totalUp
        perInterfaceRate = perIface
        todaySnapshot = store.today
        monthSnapshot = store.month
    }

    /// 处理 ifi_ibytes / ifi_obytes 的 4GB 回绕（u_int32_t 计数器）：
    /// 用 UInt32 的环形减法得到本次 1s 内真实增量。
    private func wrapDelta(new: UInt64, old: UInt64) -> UInt64 {
        let n = UInt32(truncatingIfNeeded: new)
        let o = UInt32(truncatingIfNeeded: old)
        return UInt64(n &- o)
    }
}
