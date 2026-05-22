//
//  MemoryTracker.swift
//  MacStatus
//
//  Memory 模块的"@MainActor 数据源"：1s DispatchSourceTimer 驱动采样，
//  把最新 MemorySnapshot 发到 SwiftUI 视图。
//

import Foundation
import Combine

@MainActor
final class MemoryTracker: ObservableObject {
    @Published private(set) var snapshot: MemorySnapshot = MemorySnapshot(
        totalBytes: MemorySampler.totalPhysicalBytes,
        usedBytes: 0,
        appBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0
    )

    private var timer: DispatchSourceTimer?

    func start() {
        guard timer == nil else { return }
        // 立刻先来一次，避免菜单栏第 1 秒空着
        if let first = MemorySampler.sample() {
            self.snapshot = first
        }
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        t.schedule(deadline: .now() + 1.0, repeating: 1.0, leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in
            guard let snap = MemorySampler.sample() else { return }
            Task { @MainActor [weak self] in
                self?.snapshot = snap
            }
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
