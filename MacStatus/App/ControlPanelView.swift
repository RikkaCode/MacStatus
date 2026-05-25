//
//  ControlPanelView.swift
//  MacStatus
//
//  主面板 SwiftUI 视图：
//  - 顶部：app 名 + 简短副标
//  - 中部：模块开关列表（Toggle 双向绑定到 ModuleRegistry.visibility）
//  - 底部：「退出 MacStatus」按钮
//
//  Toggle 的 binding 必须经 registry.setVisible(...) 落到 StatusItemHost，
//  不能用 @State 自己存，否则菜单栏的状态项不会真正隐藏。
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var registry: ModuleRegistry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 10) {
                Text("显示模块")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(registry.modules, id: \.id) { module in
                    Toggle(module.displayName, isOn: binding(for: module.id))
                        .toggleStyle(.switch)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Text("退出 MacStatus")
                        .frame(minWidth: 100)
                }
                .keyboardShortcut("q", modifiers: [.command])
            }
        }
        .padding(20)
        // 用显式宽度而非 fixedSize + hosting preferredContentSize 双向反馈，
        // 否则会触发 NSHostingView ↔ NSWindow 约束更新循环导致 NSException。
        .frame(width: 280, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("MacStatus")
                    .font(.title2.weight(.semibold))
                Text("菜单栏系统监控")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { registry.isVisible(id: id) },
            set: { registry.setVisible(id: id, visible: $0) }
        )
    }
}
