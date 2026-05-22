# MacStatus

> 一个常驻 macOS 顶部菜单栏的轻量级网速监控小工具。当前仓库内置 **NetSpeed** —— 实时上下行速度 + 今日/本月累计流量统计，无 Dock 图标、无主窗口。

![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue)
![Language](https://img.shields.io/badge/Swift-5-orange)
![Architecture](https://img.shields.io/badge/Apple%20Silicon-arm64-success)

---

## ✨ 功能

- 🚀 **菜单栏常驻**：右上方两行紧凑文字显示 `↑ 上传速度` / `↓ 下载速度`，使用 monospaced 字体不抖动
- 📊 **累计统计**：左键点击弹出面板，按网络接口（en0 / en5 等）分别列出
  - 今日累计上传/下载
  - 本月累计上传/下载
  - 当前实时速度
- 🌗 **自动深浅色适配**：跟随系统菜单栏外观
- 💤 **睡眠感知**：合盖/睡眠期间不计入流量，唤醒后重新校准基线
- 🔁 **柜台回绕处理**：正确处理 macOS 系统接口字节计数器 4 GB 回绕的已知问题
- 🚪 **无主窗口 / 无 Dock 图标**：纯 menu bar agent app
- 🛑 **右键退出**：右键（或 Ctrl+左键）菜单栏图标可退出

## 🖥 系统要求

- macOS **26.5+**（部署目标）
- Apple Silicon (arm64)；Intel 未测试
- Xcode **26.5+** 用于构建

## 🛠 构建与安装

### 用 Xcode（推荐）

1. clone 仓库
   ```bash
   git clone https://github.com/<your-username>/MacStatus.git
   cd MacStatus
   ```
2. 双击 `MacStatus.xcodeproj` 打开
3. `Cmd-R` 直接运行；或 `Product → Archive` 打 Release 包

### 命令行 Release 构建

```bash
xcodebuild -project MacStatus.xcodeproj \
           -scheme test \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

产物：
```
build/Build/Products/Release/NetSpeed.app
```

将 `NetSpeed.app` 拖到 `/Applications/` 即可。首次启动若被 Gatekeeper 拦截，去 `系统设置 → 隐私与安全性` 点 **"仍要打开"**。

### 设为开机启动

`系统设置 → 通用 → 登录项 → 添加 NetSpeed`

## 🏗 技术栈

| 层 | 用什么 | 说明 |
|---|---|---|
| 数据采集 | `Darwin.getifaddrs(3)` + `if_data` | 直接读内核 sysctl，**无需任何 entitlement** |
| 状态栏 UI | `AppKit.NSStatusItem` + `NSImage` (绘制 attributed string) | 用图片渲染绕过 `NSButtonCell` 多行文字居中的固有问题 |
| 弹出面板 | `NSPopover` + `NSHostingController<StatsView>` | AppKit + SwiftUI 混合 |
| 持久化 | `UserDefaults`（沙盒容器内） | 按 `usage.today.<iface>` / `usage.month.<iface>` 等键存储 |
| 并发 | `DispatchSourceTimer` + `@MainActor` + `nonisolated` 采样 | 1 秒采一次，回主线程更新 |
| 睡眠唤醒 | `NSWorkspace` willSleep / didWake 通知 | 唤醒时重置基线，避免误算 |

## 📁 仓库结构

```
MacStatus/
├── MacStatus.xcodeproj/      # Xcode 工程
├── MacStatus/                # 源码
│   ├── testApp.swift         # @main 入口，挂载 AppDelegate
│   ├── AppDelegate.swift     # 启动装配 + sleep/wake 监听
│   ├── NetworkSampler.swift  # nonisolated 接口采样（getifaddrs）
│   ├── SpeedTracker.swift    # 1s 定时差分、4GB 回绕处理
│   ├── UsageStore.swift      # UserDefaults 持久化层
│   ├── StatusItemController.swift  # NSStatusItem + NSImage 渲染
│   ├── StatsView.swift       # SwiftUI popover 视图
│   ├── ByteFormat.swift      # ByteCountFormatter 包装
│   └── Assets.xcassets       # AppIcon / AccentColor
└── README.md
```

## 🔐 隐私

- ✅ **不联网**，App Sandbox 已启用、无任何 network entitlement
- ✅ 流量数据仅读自系统接口计数器，**不抓包、不嗅探**
- ✅ 所有统计数据**仅本地** UserDefaults（`~/Library/Containers/com.rikkacode.NetSpeed/`），不上传任何服务器
- ✅ 无遥测、无埋点、无第三方依赖

## ⚠️ 已知限制

- macOS 系统接口字节计数器是 `u_int32_t`（4GB 回绕），高速链路下若 1 秒内传输 > 4 GB 会读不准。本工具用 `UInt32 &-` 模减法 + 单秒 > 10GB 视为异常丢弃来兜底，能覆盖绝大多数家用/办公场景
- Wi-Fi 关再开会导致接口计数器清零，工具会自动 sanity check 跳过该次采样
- 跨日/跨月切换时如 app 未运行，归档会延迟到下次启动

## 📄 License

[选择并补充：MIT / Apache-2.0 / 私有未授权]

## 🤝 贡献

Issues 和 PR 欢迎。如果你想加 CPU / 内存 / 电池等监控模块到 MacStatus 这个壳里，开 issue 讨论一下设计。
