//
//  StatsView.swift
//  test
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var tracker: SpeedTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            section(title: "实时速度", content: {
                rateRow(label: "下载", value: tracker.currentDownPerSec, system: "arrow.down")
                rateRow(label: "上传", value: tracker.currentUpPerSec, system: "arrow.up")
            })

            section(title: "今日累计", trailing: { resetButton(title: "重置今日", action: tracker.resetToday) }) {
                let totals = tracker.store.totals(map: tracker.todaySnapshot)
                totalRow(label: "下载", value: totals.inBytes)
                totalRow(label: "上传", value: totals.outBytes)
                interfaceBreakdown(map: tracker.todaySnapshot)
            }

            section(title: "本月累计", trailing: { resetButton(title: "重置本月", action: tracker.resetMonth) }) {
                let totals = tracker.store.totals(map: tracker.monthSnapshot)
                totalRow(label: "下载", value: totals.inBytes)
                totalRow(label: "上传", value: totals.outBytes)
                interfaceBreakdown(map: tracker.monthSnapshot)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, alignment: .topLeading)
        .font(.system(size: 12))
    }

    private var header: some View {
        HStack {
            Image(systemName: "network")
                .foregroundStyle(.tint)
            Text("网速监控")
                .font(.headline)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("退出")
        }
    }

    @ViewBuilder
    private func section<Trailing: View, Content: View>(
        title: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                trailing()
            }
            content()
        }
    }

    private func rateRow(label: String, value: UInt64, system: String) -> some View {
        HStack {
            Image(systemName: system).frame(width: 14)
            Text(label)
            Spacer()
            Text(ByteFormat.rate(value))
                .monospacedDigit()
        }
    }

    private func totalRow(label: String, value: UInt64) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(ByteFormat.total(value))
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func interfaceBreakdown(map: [String: IfaceUsage]) -> some View {
        let entries = map
            .map { ($0.key, $0.value) }
            .sorted { ($0.1.inBytes + $0.1.outBytes) > ($1.1.inBytes + $1.1.outBytes) }
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(entries, id: \.0) { iface, usage in
                    HStack {
                        Text(iface)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text("↓ " + ByteFormat.total(usage.inBytes))
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text("↑ " + ByteFormat.total(usage.outBytes))
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private func resetButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.borderless)
            .font(.system(size: 10))
            .foregroundStyle(.tint)
    }
}
