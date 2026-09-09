<p align="center">
  <img src="logo.svg" width="128" height="128" alt="Info Space logo" />
</p>
<h1 align="center">Info Space</h1>
<p align="center"><strong>原生 SwiftUI macOS 信息工作区与可嵌入 SDK</strong><br>组织信息面板 · 拖动调整比例 · 定制交互空间</p>

<p align="center">
  <a href="https://github.com/nocoo/infospace/releases"><img src="https://img.shields.io/github/v/release/nocoo/infospace" alt="Release" /></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-222222?logo=apple" alt="macOS 26+" />
  <img src="https://img.shields.io/badge/Swift-6.3-F05138?logo=swift&logoColor=white" alt="Swift 6.3" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-007AFF" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/tests-51_passing-brightgreen" alt="51 unit tests" />
  <a href="https://github.com/nocoo/infospace/actions/workflows/ci.yml"><img src="https://github.com/nocoo/infospace/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT" /></a>
</p>
<p align="center"><a href="docs/README.en.md">English</a> · <a href="docs/API.md">SDK 文档</a> · <a href="https://github.com/nocoo/infospace/releases">Releases</a></p>
<p align="center"><img src="docs/images/workspace.png" width="720" alt="Info Space 的统一 Header、四个信息面板及自定义 Footer" /></p>

---

## 这是什么

Info Space 把多个信息面板放进同一个 macOS 工作区，通过拖动分隔线或交叉点分配空间。拖动时连续跟随指针，松手时吸附到最近的网格。

它同时提供 Swift Package 和演示应用。你可以只把网格嵌入现有 SwiftUI 页面，也可以组合完整工作区、原生窗口和自定义工具栏。布局模型与界面分开，内容和颜色由使用 SDK 的应用提供。

## 功能

- **网格布局** — 支持 1–8 行、1–8 列，每个方向 32 个网格；每条分隔线可独立拖动，交叉点同时调整两个方向。
- **展开与收起** — 最大化时，其余面板缩成带颜色和横排名称的 banner；也能单独最小化，点击 banner 恢复。
- **布局 API** — 在指定行列插入空间并自动播放动画，支持移动、移除和调整比例；稳定 ID 保留已有内容身份。
- **卡片定制** — 自定义颜色、正文和附加动作。Header 保留图标、名称及固定的最小化、最大化按钮。
- **组件替换** — 支持定制 banner、空单元格、覆盖层和分隔线外观，或单独嵌入网格。
- **窗口定制** — 原生 Header 与红绿灯共用一行，Logo 旁可添加最多 3 个动作或链接；右侧布局工具栏可带动画收起。
- **周边区域** — 上、下、左、右均可插入 SwiftUI 内容；Footer 左右两侧独立定制，也可留空。
- **原生交互** — 支持键盘操作、辅助功能标签及系统“减弱动态效果”，没有第三方运行时依赖。

## 安装

需要 macOS 26+、Swift 6.3 和 Xcode 26.6+。在 Xcode 中添加包地址 `https://github.com/nocoo/infospace`，选择 `InfoSpaceCore` 与 `InfoSpaceUI`。

在 Swift Package 中声明依赖：

```swift
.package(url: "https://github.com/nocoo/infospace.git", from: "0.1.0")
```

将两个 library product 加入目标：

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

`InfoSpaceCanvas` 不设置窗口最小尺寸，可放入任意 SwiftUI 布局。完整工作区使用 `InfoSpaceWorkspace`，原生窗口使用 `InfoSpaceWindow`。更多接入方式见 [可编译示例](Examples) 和 [SDK 文档](docs/API.md)。

v0.1.0 提供 Swift Package 与源码；演示应用按下方步骤在本机构建。

## 命令一览

以下快捷键用于演示应用：

| 快捷键 | 操作 |
| --- | --- |
| `⌘G` | 显示或隐藏网格 |
| `⌘0` | 均分行列 |
| `⇧⌘0` | 恢复所有空间 |
| `⌘1` / `⌘2` / `⌘3` | 切换 2 × 2、2 × 4、3 × 4 布局 |
| `Esc` | 退出最大化 |

卡片中的 `+` 在当前位置插入空间，调色板按钮切换颜色。Header 的代码按钮打开 GitHub 仓库，右箭头收起布局工具栏；Footer 左侧显示空间数量，右侧恢复全部。

## 项目结构

```text
infospace/
├── App/                    # 原生 macOS 演示与窗口检查
├── Sources/
│   ├── InfoSpaceCore/      # 布局、稳定 ID、比例与吸附
│   └── InfoSpaceUI/        # SwiftUI 网格、卡片和窗口组件
├── Tests/
│   └── InfoSpaceCoreTests/ # 布局与交互状态单元测试
├── Examples/               # 作为 SDK 使用者编译的示例
├── docs/                   # SDK 文档、英文 README 和截图
├── scripts/                # 构建、Lint、检查和版本校验
├── Package.swift           # Swift 包、产品与目标
├── package.json            # 发布版本元数据
└── project.yml             # XcodeGen 应用配置
```

## 技术栈

| 层 | 技术 |
| --- | --- |
| 界面 | [SwiftUI](https://developer.apple.com/xcode/swiftui/) |
| 原生窗口 | [AppKit](https://developer.apple.com/documentation/appkit) |
| 状态与并发 | [Observation](https://developer.apple.com/documentation/observation)、Swift 6 |
| 包与应用构建 | [Swift Package Manager](https://www.swift.org/documentation/package-manager/)、[XcodeGen](https://github.com/yonaskolb/XcodeGen) |
| 测试 | [Swift Testing](https://github.com/swiftlang/swift-testing)、原生窗口事件检查 |
| 代码检查 | [SwiftLint](https://github.com/realm/SwiftLint)、[swift-format](https://github.com/swiftlang/swift-format) |

## 开发

安装完整 Xcode 并完成首次启动设置，再从源码构建：

```sh
git clone https://github.com/nocoo/infospace.git
cd infospace
brew install xcodegen swiftlint
./scripts/build.sh -quiet
./scripts/run.sh
```

脚本默认使用 `/Applications/Xcode.app/Contents/Developer`，可通过 `DEVELOPER_DIR` 指定其他 Xcode。窗口启动时居中，占屏幕可用宽度的 92%、高度的 90%。演示中的笔记可以编辑，内容和布局不跨启动保存。

| 命令 | 用途 |
| --- | --- |
| `./scripts/build.sh -quiet` | 生成 Xcode 项目并构建原生 App |
| `./scripts/run.sh` | 打开演示窗口 |
| `./scripts/format.sh` | 应用 Swift 格式规范 |
| `./scripts/lint.sh` | 严格检查 SwiftLint 与 swift-format |
| `./scripts/check.sh` | 校验版本、运行 UT、编译示例和 Release |
| `python3 scripts/verify-ui.py` | 在已登录的 macOS 桌面运行原生窗口检查 |
| `python3 scripts/version.py --sync` | 从版本元数据同步 macOS 应用版本 |

根目录 `package.json` 仅维护发布版本，不引入 JavaScript 运行时。Swift 构建与依赖由 `Package.swift` 管理；版本同步和发布方法见 [贡献指南](CONTRIBUTING.md)。

## 测试

| 层 | 内容 | 触发时机 |
| --- | --- | --- |
| 静态检查 | 严格 SwiftLint、swift-format、版本一致性 | 本地与 GitHub Actions |
| 单元测试 | 插入、移动、碰撞、回滚、比例、吸附及稀疏布局 | 本地与 GitHub Actions |
| SDK 示例 | 编译独立网格、自定义工作区和完整窗口示例 | 本地与 GitHub Actions |
| 应用构建 | Swift Release 与原生 Debug bundle | 本地与 GitHub Actions |
| 原生窗口 | 按钮、拖动、松手吸附、Footer、工具栏与内容状态保留 | 本机桌面单独运行 |

```sh
./scripts/check.sh
./scripts/build.sh -quiet
python3 scripts/verify-ui.py
```

v0.1.0 包含 51 个单元测试和 36 项原生窗口检查。布局测试覆盖 12 面板的全部 4,096 种最小化组合。窗口检查仅向自身窗口发送事件并截取自身窗口，报告保存在 Git 忽略的 `.local/inspections/` 中；它不等同于系统辅助功能端到端测试，也不在 CI 的无交互环境运行。

拖动时采用实时内容缩放，尚未实现截图冻结。几何计算基准不包含 SwiftUI 布局和渲染耗时。

## 文档

| 文档 | 内容 |
| --- | --- |
| [SDK 文档](docs/API.md) | 容器、插槽、外观、动作和布局变更语义 |
| [示例](Examples) | 独立网格、自定义区域与原生窗口 |
| [贡献指南](CONTRIBUTING.md) | 开发约定、测试与发布 |
| [变更记录](CHANGELOG.md) | 各版本的改动 |
| [English README](docs/README.en.md) | 英文说明 |

## License

[MIT](LICENSE) © 2026 NOCOO
