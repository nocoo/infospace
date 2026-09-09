<p align="center">
  <img src="logo.svg" width="128" height="128" alt="Info Space logo" />
</p>
<h1 align="center">Info Space</h1>
<p align="center">在 macOS 应用中组织信息面板，拖动分隔线调整布局。</p>
<p align="center"><a href="docs/README.en.md">English</a></p>

<p align="center"><img src="docs/images/workspace.png" width="720" alt="Info Space 的信息面板、原生工具栏和自定义页脚" /></p>

## 这是什么

Info Space 是面向 macOS 应用开发者的 SwiftUI 工作区 SDK，附带一个可运行的演示应用。它把多个信息面板放进同一网格，通过拖动分隔线或交叉点调整比例，也可以收起面板或最大化其中一个。

`InfoSpaceCore` 提供布局与交互状态，`InfoSpaceUI` 提供网格、卡片、工作区和原生窗口组件。内容、数据来源与持久化由接入 SDK 的应用负责。演示中的收件箱、项目进度和日程使用示例数据；笔记可以编辑，内容和布局不会跨启动保存。

## 功能

- 使用 1–8 行、1–8 列安排面板。拖动时连续跟随指针，松手时吸附到每轴 32 等分的网格。
- 最小化单个面板，或最大化一个面板并把其余面板收成带标题的横条；点击横条恢复。
- 通过 API 在指定单元格插入、移动或移除面板，设置行列比例，支持保留空单元格的稀疏布局。稳定 ID 让已有面板在移动、收起和展开时保留视图状态。
- 自定义面板颜色、图标、标题、正文和附加动作；替换横条、空单元格、空状态、覆盖层和分隔线外观。
- 单独嵌入网格，或组合带上下左右区域、独立页脚插槽的工作区。原生窗口工具栏支持自定义品牌、品牌旁最多三个动作和可收起的布局控件。
- 使用方向键微调分隔线，提供辅助功能标签，并遵循系统的“减弱动态效果”设置。

## 使用

### 接入 SDK

需要 macOS 26+ 和 Swift 6.3；仓库使用 Xcode 26.6+ 开发。在 Xcode 中添加包地址 `https://github.com/nocoo/infospace`，选择 `InfoSpaceCore` 与 `InfoSpaceUI`。

在 Swift Package 的依赖中加入：

```swift
.package(url: "https://github.com/nocoo/infospace.git", from: "0.1.0")
```

将需要的 library product 加入目标依赖：

```swift
.product(name: "InfoSpaceCore", package: "infospace"),
.product(name: "InfoSpaceUI", package: "infospace")
```

最小网格示例：

```swift
import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

struct MyGrid: View {
    @State private var model = InfoSpaceModel(rows: 2, columns: 2)

    var body: some View {
        InfoSpaceCanvas(model: model, appearance: { identity in
            SpaceAppearance(title: identity.rawValue, symbol: "doc.text", color: .indigo)
        }) { identity in
            Text("Content for \(identity.rawValue)")
        }
    }
}
```

`InfoSpaceCanvas` 可嵌入现有 SwiftUI 页面，不设置窗口最小尺寸。需要周边区域时使用 `InfoSpaceWorkspace`，需要原生窗口时使用 `InfoSpaceWindow`；完整接入方式见 [SDK 文档](docs/API.md)和[示例](Examples)。模型变更在主 actor 上执行。

调整承载用户数据的布局时，使用 `resizeGrid(rows:columns:)`：它保留所有面板，容量不足时抛错。演示应用采用的 `setDimensions(rows:columns:)` 会删除新范围之外的面板并填充空位，适合重建示例布局。插入、移动和碰撞策略见[布局变更说明](docs/API.md#insertion-and-collisions)。

### 使用演示应用

按下方开发步骤构建并打开演示窗口。拖动分隔线调整比例，卡片中的 `+` 在当前位置插入面板，调色板按钮切换颜色。页脚显示展开与收起的数量，并提供恢复全部按钮。

| 快捷键 | 操作 |
| --- | --- |
| `⌘G` | 显示或隐藏网格 |
| `⌘0` | 均分行列 |
| `⇧⌘0` | 恢复所有面板 |
| `⌘1` / `⌘2` / `⌘3` | 切换 2 × 2、2 × 4、3 × 4 布局 |
| `Esc` | 退出最大化 |

缩小演示布局会移除超出范围的面板及其临时编辑状态。需要保存的内容应由接入 SDK 的应用单独管理。

## 开发

安装完整 Xcode 并完成首次启动设置。原生应用构建还需要 XcodeGen 2.46+ 和 Python 3，代码检查使用 SwiftLint 与 Xcode 自带的 swift-format。

```bash
git clone https://github.com/nocoo/infospace.git
cd infospace
brew install xcodegen swiftlint
./scripts/build.sh -quiet
./scripts/run.sh
```

构建脚本生成 Xcode 工程，把 Debug 应用写入 `.build/xcode/Build/Products/Debug/InfoSpace.app`；运行脚本打开该应用。脚本默认使用 `/Applications/Xcode.app/Contents/Developer`，可通过 `DEVELOPER_DIR` 指定其他 Xcode 安装。

| 命令 | 用途 |
| --- | --- |
| `./scripts/build.sh -quiet` | 构建原生演示应用 |
| `./scripts/run.sh` | 打开演示窗口；尚未构建时先构建 |
| `./scripts/format.sh` | 格式化 Swift 代码 |
| `./scripts/lint.sh` | 运行 SwiftLint 与 swift-format 检查 |
| `./scripts/check.sh` | 运行本地检查、单元测试、示例编译与 Release 包构建 |

```text
Sources/InfoSpaceCore/       布局、稳定 ID、比例与吸附
Sources/InfoSpaceUI/         SwiftUI 网格、卡片、工作区与窗口
App/                        演示内容与原生窗口检查
Examples/                   SDK 使用示例
Tests/InfoSpaceCoreTests/    布局与交互状态单元测试
```

Swift Package Manager 管理依赖与包构建，`package.json` 保存发布版本元数据。开发约定与发布步骤见[贡献指南](CONTRIBUTING.md)。

## 测试

在仓库根目录运行。直接调用 Swift 工具前，选择已安装的完整 Xcode；以下路径可按本机安装位置调整：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

| 范围 | 命令 |
| --- | --- |
| 核心布局与交互状态单元测试 | `swift test -Xswiftc -warnings-as-errors` |
| SDK 使用示例编译 | `swift build --target InfoSpaceExamples -Xswiftc -warnings-as-errors` |

原生窗口检查需要已登录的 macOS 桌面、Python 3 和已构建的 Debug 应用：

```bash
./scripts/build.sh -quiet
python3 scripts/verify-ui.py
```

检查脚本启动独立演示进程，在自身窗口内执行操作并截图；报告与截图保存到 `.local/inspections/`。

## 技术栈

![Swift](https://img.shields.io/badge/Swift-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?logo=swift&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-222222?logo=apple&logoColor=white)

| 部分 | 实现 |
| --- | --- |
| 界面 | SwiftUI 网格、卡片、工具栏与插槽 |
| 原生窗口 | AppKit 窗口配置与事件处理 |
| 布局与状态 | Swift、Observation、MainActor |
| 包与应用构建 | Swift Package Manager、XcodeGen、Xcode |
| 验证 | Swift Testing、原生窗口事件检查、ScreenCaptureKit 窗口截图 |
| 开发工具 | SwiftLint、swift-format、Python 脚本 |

SDK 没有第三方运行时依赖。

## 文档

- [SDK 文档](docs/API.md)：容器、插槽、外观、动作和布局变更语义。
- [使用示例](Examples)：独立网格、自定义工作区与原生窗口。
- [贡献指南](CONTRIBUTING.md)：开发、检查与发布步骤。
- [变更记录](CHANGELOG.md)：各版本的改动。

## 许可证

[MIT](LICENSE) © 2026 NOCOO
