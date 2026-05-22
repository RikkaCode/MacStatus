//
//  MemorySampler.swift
//  MacStatus
//
//  Mach `host_statistics64(HOST_VM_INFO64, ...)` 采样物理内存状态。
//  公式参考 Activity Monitor "已用内存" = App Memory + Wired + Compressed。
//
//  - App Memory ≈ (active + inactive + speculative - purgeable) × pageSize
//  - Wired      = wire × pageSize（内核常驻不可换出）
//  - Compressed = compressor_page_count × pageSize
//

import Darwin
import Foundation

struct MemorySnapshot: Sendable {
    /// 物理总内存（字节）
    let totalBytes: UInt64
    /// 已用（App + Wired + Compressed），与 Activity Monitor 口径一致
    let usedBytes: UInt64
    /// 0.0 ~ 1.0
    var usedRatio: Double {
        totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes)
    }

    let appBytes: UInt64
    let wiredBytes: UInt64
    let compressedBytes: UInt64
}

enum MemorySampler {
    /// 系统物理内存总量（启动后不变，只读一次即可）。来自 host_info(HOST_BASIC_INFO)
    nonisolated static let totalPhysicalBytes: UInt64 = readTotalPhysicalBytes()

    nonisolated static func sample() -> MemorySnapshot? {
        let host = mach_host_self()
        var size = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        var stats = vm_statistics64_data_t()

        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &size)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let active       = UInt64(stats.active_count)        * pageSize
        let inactive     = UInt64(stats.inactive_count)      * pageSize
        let speculative  = UInt64(stats.speculative_count)   * pageSize
        let wired        = UInt64(stats.wire_count)          * pageSize
        let compressed   = UInt64(stats.compressor_page_count) * pageSize
        let purgeable    = UInt64(stats.purgeable_count)     * pageSize

        // App Memory: 真正被进程占用的"可计入内存压力"部分
        let app = saturatingSub(active &+ inactive &+ speculative, purgeable)
        let used = app &+ wired &+ compressed

        return MemorySnapshot(
            totalBytes: totalPhysicalBytes,
            usedBytes: used,
            appBytes: app,
            wiredBytes: wired,
            compressedBytes: compressed
        )
    }

    /// purgeable 偶尔可能 > active+inactive+speculative（边界采样），做饱和减法
    private nonisolated static func saturatingSub(_ a: UInt64, _ b: UInt64) -> UInt64 {
        a > b ? a - b : 0
    }

    private nonisolated static func readTotalPhysicalBytes() -> UInt64 {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        let ret = sysctlbyname("hw.memsize", &size, &len, nil, 0)
        if ret == 0 && size > 0 { return size }
        // 兜底：host_info BASIC（HOST_BASIC_INFO_COUNT 是 C 宏 Swift 不可见，运行时算）
        let basicCount = MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size
        var hostSize = mach_msg_type_number_t(basicCount)
        var info = host_basic_info_data_t()
        let rc = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: basicCount) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &hostSize)
            }
        }
        return rc == KERN_SUCCESS ? UInt64(info.max_mem) : 0
    }
}
