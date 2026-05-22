//
//  NetworkModule.swift
//  MacStatus
//
//  Network 模块入口：实现 StatModule 协议，把 SpeedTracker + Renderer + DetailView
//  打包成可注册到 ModuleRegistry 的单元。
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class NetworkModule: StatModule {
    let id = "network"

    var statusItemWidth: CGFloat { NetworkStatusRenderer.statusItemWidth }

    private let store: NetworkUsageStore
    private let tracker: SpeedTracker

    private let imageSubject = CurrentValueSubject<NSImage, Never>(NSImage())
    var statusImagePublisher: AnyPublisher<NSImage, Never> {
        imageSubject.eraseToAnyPublisher()
    }

    private var rateCancellable: AnyCancellable?

    init() {
        let store = NetworkUsageStore()
        self.store = store
        self.tracker = SpeedTracker(store: store)
        imageSubject.send(NetworkStatusRenderer.render(up: 0, down: 0))
    }

    func start() {
        if rateCancellable == nil {
            rateCancellable = tracker.$currentUpPerSec
                .combineLatest(tracker.$currentDownPerSec)
                .sink { [weak self] up, down in
                    self?.imageSubject.send(NetworkStatusRenderer.render(up: up, down: down))
                }
        }
        tracker.start()
    }

    func stop() {
        tracker.stop()
    }

    func handleWake() {
        tracker.markRebaseline()
    }

    func makeDetailView() -> AnyView {
        AnyView(NetworkDetailView(tracker: tracker))
    }
}
