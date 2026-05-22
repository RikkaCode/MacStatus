//
//  MemoryDetailView.swift
//  MacStatus
//
//  Memory 模块的 popover 详情视图：总量 / 已用 / App / Wired / Compressed。
//

import SwiftUI

struct MemoryDetailView: View {
    @ObservedObject var tracker: MemoryTracker

    var body: some View {
        let snap = tracker.snapshot
        VStack(alignment: .leading, spacing: 12) {
            header(used: snap.usedBytes, total: snap.totalBytes, ratio: snap.usedRatio)
            section(title: "明细") {
                row(label: "App Memory", value: snap.appBytes)
                row(label: "Wired",      value: snap.wiredBytes)
                row(label: "Compressed", value: snap.compressedBytes)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 300, alignment: .topLeading)
        .font(.system(size: 12))
    }

    private func header(used: UInt64, total: UInt64, ratio: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.tint)
                Text("内存占用")
                    .font(.headline)
                Spacer()
                Text(PercentFormat.percent(ratio))
                    .monospacedDigit()
                    .font(.system(size: 14, weight: .semibold))
            }
            HStack {
                Text("\(ByteFormat.total(used)) / \(ByteFormat.total(total))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
            }
            ProgressView(value: ratio)
                .progressViewStyle(.linear)
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func row(label: String, value: UInt64) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(ByteFormat.total(value)).monospacedDigit()
        }
    }
}
