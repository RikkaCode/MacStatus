//
//  ModuleRegistry.swift
//  MacStatus
//
//  集中托管所有 StatModule 实例的生命周期；每个模块对应一个 StatusItemHost。
//  AppDelegate 只跟它打交道，从此添加新模块 = 在 init 里 append 一行。
//

import AppKit
import Combine

@MainActor
final class ModuleRegistry {
    private var modules: [StatModule] = []
    private var hosts: [StatusItemHost] = []

    func register(_ module: StatModule) {
        modules.append(module)
    }

    /// 真正挂上菜单栏 + 启动采样。注册顺序 = 菜单栏从右往左的排列顺序
    /// （macOS 默认新加入的 NSStatusItem 出现在最左侧）。
    func activate() {
        for module in modules {
            let host = StatusItemHost(module: module)
            hosts.append(host)
            module.start()
        }
    }

    func stopAll() {
        for module in modules { module.stop() }
    }

    func wakeAll() {
        for module in modules {
            module.handleWake()
            module.start()
        }
    }
}
