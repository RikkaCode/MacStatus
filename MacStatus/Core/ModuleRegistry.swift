//
//  ModuleRegistry.swift
//  MacStatus
//
//  集中托管所有 StatModule 实例的生命周期；每个模块对应一个 StatusItemHost。
//  额外维护「模块菜单栏是否显示」的可见性状态，供主面板 Toggle 双向绑定使用。
//

import AppKit
import Combine

@MainActor
final class ModuleRegistry: ObservableObject {
    /// 主面板观察的「模块 id → 是否显示」表。
    /// 用字典而非 [StatModule] 上的 @Published，是因为 SwiftUI Toggle 绑定按 id 寻址更清晰。
    @Published private(set) var visibility: [String: Bool] = [:]

    /// 已注册模块（顺序 = 注册顺序 = 菜单栏从右往左顺序）。主面板 ForEach 用。
    private(set) var modules: [StatModule] = []

    /// 模块 id → 对应的状态项宿主。隐藏/显示菜单栏槽位时按 id 查表。
    private var hosts: [String: StatusItemHost] = [:]

    /// 主面板控制器；StatusItemHost 右键的「打开主面板…」需要它。
    /// 由 AppDelegate 在 register 之前赋值。
    weak var controlPanel: ControlPanelWindowController?

    func register(_ module: StatModule) {
        modules.append(module)
    }

    /// 真正挂上菜单栏 + 启动采样。注册顺序 = 菜单栏从右往左的排列顺序
    /// （macOS 默认新加入的 NSStatusItem 出现在最左侧）。
    func activate() {
        for module in modules {
            let visible = UserDefaults.standard.object(forKey: visibilityKey(module.id)) as? Bool ?? true
            visibility[module.id] = visible
            let host = StatusItemHost(
                module: module,
                registry: self,
                controlPanel: controlPanel
            )
            host.setVisible(visible)
            hosts[module.id] = host
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

    // MARK: - Visibility

    func isVisible(id: String) -> Bool {
        visibility[id] ?? true
    }

    func setVisible(id: String, visible: Bool) {
        visibility[id] = visible
        UserDefaults.standard.set(visible, forKey: visibilityKey(id))
        hosts[id]?.setVisible(visible)
    }

    func displayName(of id: String) -> String {
        modules.first { $0.id == id }?.displayName ?? id
    }

    private func visibilityKey(_ id: String) -> String {
        "module.visible.\(id)"
    }
}
