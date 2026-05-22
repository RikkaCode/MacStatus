//
//  AppDelegate.swift
//  test
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: UsageStore?
    private var tracker: SpeedTracker?
    private var controller: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let store = UsageStore()
        let tracker = SpeedTracker(store: store)
        let controller = StatusItemController(tracker: tracker)

        self.store = store
        self.tracker = tracker
        self.controller = controller

        tracker.start()

        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            self,
            selector: #selector(handleWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        wsCenter.addObserver(
            self,
            selector: #selector(handleDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        tracker?.stop()
        UserDefaults.standard.synchronize()
    }

    @objc private func handleWillSleep() {
        tracker?.stop()
    }

    @objc private func handleDidWake() {
        tracker?.markRebaseline()
        tracker?.start()
    }
}
