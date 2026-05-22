# MacStatus

> 一个常驻 macOS 顶部菜单栏的轻量级系统监控小工具，**模块化**架构，目前内置：
> - **NetSpeed**：实时上下行速度 + 今日/本月累计流量
> - **Memory**：实时内存占用百分比 + 已用/Wired/Compressed 明细
>
> 无 Dock 图标、无主窗口、无第三方依赖。

![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-blue)
![Language](https://img.shields.io/badge/Swift-5-orange)
![Architecture](https://img.shields.io/badge/Apple%20Silicon-arm64-success)

---

## ✨ 功能

菜单栏布局示意（从右往左）：

```
... [ MEM 53% ] [ ↑ 1.2 MB/s / ↓ 5.6 MB/s ]
```

### NetSpeed 模块
- 🚀 菜单栏右侧两行紧凑文字 `↑ 上传` / `↓ 下载`，monospaced 数字防抖动
- 📊 左键弹出面板，分接口（en0 / en5…）列出今日/本月累计 + 实时速度
- 💤 合盖/睡眠不计入流量，唤醒重设基线
- 🔁 正确处理 macOS 接口字节计数器的 4 GB 回绕

### Memory 模块
- 💾 菜单栏显示 `MEM xx%`，使用率口径对齐**活动监视器**（已用 = App + Wired + Compressed）
- 📊 左键弹出面板，显示总量 / 已用 / App / Wired / Compressed 明细 + 占用进度条
- ⚡ 直接读 Mach `host_statistics64(HOST_VM_INFO64, …)`，无需任何 entitlement

### 公共
- 🌗 自动深浅色适配（菜单栏图像 `isTemplate=true`）
- 🛑 右键（或 Ctrl+左键）任一菜单栏图标弹出退出菜单
- 🚪 无主窗口 / 无 Dock 图标，纯 menu bar agent app

## 🖥 系统要求

- macOS **26.5+**（部署目标）
- Apple Silicon (arm64)；Intel 未测试
- Xcode **26.5+** 用于构建

## 🛠 构建与安装

> ⚠️ 仓库**不包含 `.xcodeproj` 工程文件**。clone 后需要自行在 Xcode 新建一个 macOS App 工程，然后把 `MacStatus/` 目录下的所有 `.swift` 文件加入 target。
> 关键 build settings：
> - Deployment Target: macOS 26.5+
> - `INFOPLIST_KEY_LSUIElement = YES`（隐藏 Dock 图标）
> - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
> - 启用 App Sandbox（不需要任何 network entitlement）

### 用 Xcode（推荐）

1. clone 仓库并按上述说明建好工程
2. `Cmd-R` 直接运行；或 `Product → Archive` 打 Release 包

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
| 网络数据采集 | `Darwin.getifaddrs(3)` + `if_data` | 内核 sysctl 读取，无 entitlement |
| 内存数据采集 | Mach `host_statistics64(HOST_VM_INFO64, …)` | 物理页统计，无 entitlement |
| 状态栏 UI | `AppKit.NSStatusItem` + `NSImage`（绘制 attributed string） | 模板图像自适应深浅色，绕过 NSButtonCell 多行 baseline 问题 |
| 弹出面板 | `NSPopover` + `NSHostingController<SwiftUI View>` | AppKit + SwiftUI 混合 |
| 持久化 | `UserDefaults`（沙盒容器内） | 仅 Network 模块使用，按接口/日期归档 |
| 并发 | `DispatchSourceTimer` + `@MainActor` + `nonisolated` 采样 | 1 秒采一次，回主线程更新 |
| 睡眠唤醒 | `NSWorkspace` willSleep / didWake 通知 | 全局派发给所有模块 |

## 📁 项目结构（模块化）

```
MacStatus/
├── MacStatus/                        # 源码根（.xcodeproj 不入库，需自建）
│   ├── App/                          # @main 入口 + Assets
│   │   ├── MacStatusApp.swift
│   │   ├── AppDelegate.swift         # ModuleRegistry 装配 + sleep/wake 派发
│   │   └── Assets.xcassets
│   ├── Core/                         # 模块抽象层
│   │   ├── StatModule.swift          # 协议：菜单栏监控模块统一契约
│   │   ├── ModuleRegistry.swift      # 模块生命周期总管
│   │   ├── StatusItemHost.swift      # NSStatusItem + NSPopover + 点击路由
│   │   ├── ByteFormat.swift          # 字节速率/总量格式化
│   │   └── PercentFormat.swift       # 百分比格式化
│   └── Modules/
│       ├── Network/                  # 网络监控模块
│       │   ├── NetworkModule.swift          # StatModule 实现
│       │   ├── NetworkSampler.swift         # getifaddrs 采样
│       │   ├── SpeedTracker.swift           # 1s 差分 + 4GB 回绕
│       │   ├── NetworkUsageStore.swift      # UserDefaults 持久化
│       │   ├── NetworkStatusRenderer.swift  # 菜单栏 NSImage 渲染
│       │   └── NetworkDetailView.swift      # popover 详情视图
│       └── Memory/                   # 内存监控模块
│           ├── MemoryModule.swift           # StatModule 实现
│           ├── MemorySampler.swift          # host_statistics64 采样
│           ├── MemoryTracker.swift          # 1s 采样 timer
│           ├── MemoryStatusRenderer.swift   # 菜单栏 NSImage 渲染
│           └── MemoryDetailView.swift       # popover 详情视图
├── LICENSE
└── README.md
```

## 🧩 扩展新模块

加 CPU / 电池 / 温度等监控只需 3 步：

1. 在 `Modules/` 下新建子目录，写 5 个文件套件（参考 `Modules/Memory/`）：
   - `XxxSampler.swift` —— `nonisolated` 数据采集
   - `XxxTracker.swift` —— `@MainActor ObservableObject` + DispatchSourceTimer
   - `XxxStatusRenderer.swift` —— 渲染菜单栏 `NSImage`
   - `XxxDetailView.swift` —— SwiftUI popover 视图
   - `XxxModule.swift` —— 实现 `StatModule` 协议把上面 4 件套粘起来
2. 在 `App/AppDelegate.swift` 的 `applicationDidFinishLaunching` 里加一行 `registry.register(XxxModule())`
3. 编译

`PBXFileSystemSynchronizedRootGroup` 会自动把新文件加入构建，无需手动改 pbxproj。

## 🔐 隐私

- ✅ **不联网**，App Sandbox 已启用、无任何 network entitlement
- ✅ 数据仅来自内核接口/Mach 统计，**不抓包、不嗅探**
- ✅ 所有累计数据**仅本地** UserDefaults（`~/Library/Containers/com.rikkacode.NetSpeed/`），不上传任何服务器
- ✅ 无遥测、无埋点、无第三方依赖

## ⚠️ 已知限制

- 网络：macOS 接口字节计数器是 `u_int32_t`（4GB 回绕），单秒 > 4 GB 的链路读不准。用 `UInt32 &-` 模减法 + 单秒 > 10 GB 视为异常丢弃来兜底
- 网络：Wi-Fi 关再开会导致计数器清零，自动 sanity check 跳过该次采样
- 网络：跨日/跨月切换时如 app 未运行，归档延迟到下次启动
- 内存：`MEM xx%` 与活动监视器口径一致（含 Wired + Compressed），不是 `top` 的 free 视角

## 📄 License

**MIT License** —— 详见 [LICENSE](./LICENSE)。可自由复制、修改、分发、商用，唯一要求是保留原版权与许可声明。

## 🤝 贡献

Issues 和 PR 欢迎。新模块按 [扩展新模块](#-扩展新模块) 步骤实现，保持 `StatModule` 协议契约即可。
