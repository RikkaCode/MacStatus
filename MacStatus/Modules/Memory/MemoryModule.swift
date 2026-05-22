//
//  MemoryModule.swift
//  MacStatus
//
//  Memory 模块入口：实现 StatModule，把 MemoryTracker + Renderer + DetailView 串起来。
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class MemoryModule: StatModule {
    let id = "memory"

    var statusItemWidth: CGFloat { MemoryStatusRenderer.statusItemWidth }

    private let tracker = MemoryTracker()

    private let imageSubject = CurrentValueSubject<NSImage, Never>(
        MemoryStatusRenderer.render(ratio: 0)
    )
    var statusImagePublisher: AnyPublisher<NSImage, Never> {
        imageSubject.eraseToAnyPublisher()
    }

    private var snapshotCancellable: AnyCancellable?

    func start() {
        if snapshotCancellable == nil {
            snapshotCancellable = tracker.$snapshot
                .sink { [weak self] snap in
                    self?.imageSubject.send(MemoryStatusRenderer.render(ratio: snap.usedRatio))
                }
        }
        tracker.start()
    }

    func stop() {
        tracker.stop()
    }

    func handleWake() {
        // 内存采样无差分基线，唤醒无需特殊处理
    }

    func makeDetailView() -> AnyView {
        AnyView(MemoryDetailView(tracker: tracker))
    }
}
