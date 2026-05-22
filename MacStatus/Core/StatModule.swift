//
//  StatModule.swift
//  MacStatus
//
//  统一的"菜单栏监控模块"协议。任何新模块（CPU/电池/温度…）只需实现本协议，
//  注册到 ModuleRegistry 即可自动在菜单栏获得一个独立的 NSStatusItem。
//

import AppKit
import Combine
import SwiftUI

@MainActor
protocol StatModule: AnyObject {
    /// 稳定唯一标识，用于 UserDefaults 命名空间 / 调试日志
    var id: String { get }

    /// 菜单栏 NSStatusItem 固定宽度（px）。两行紧凑文字一般 72；单行百分比一般 56
    var statusItemWidth: CGFloat { get }

    /// 当前要在菜单栏渲染的图像。模块通过 send(_:) 推送更新；
    /// 实现端只需要在数值变化时调用一次 renderer 即可
    var statusImagePublisher: AnyPublisher<NSImage, Never> { get }

    /// 启动采样 / 定时器
    func start()

    /// 停止采样（系统睡眠 / app 退出）
    func stop()

    /// 系统唤醒：模块自行决定是否需要重设基线（如网络差分需要）
    func handleWake()

    /// 构造 popover 中显示的详情视图
    func makeDetailView() -> AnyView
}
