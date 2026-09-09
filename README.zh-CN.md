# Info Space

原生 SwiftUI macOS 信息工作区。把信息面板放进网格，拖动分隔线或交叉点调整比例，松手后吸附到最近的网格。既能嵌入一个小网格，也能组合成完整窗口。

[English](README.md) · [SDK 文档](docs/API.md) · [可编译示例](Examples) · [贡献指南](CONTRIBUTING.md)

![Info Space 的统一 Header 和四个信息面板](docs/images/workspace.png)

## 功能

- 支持 1–8 行、1–8 列，每个方向 32 个网格；拖动时连续跟随，松手时吸附。
- 每条分隔线可单独拖动，交叉点可同时调整两个方向，分隔线不会越过相邻线。
- 通过 API 在指定行列插入空间，自动播放动画；移动和插入时保留已有面板 ID。
- 最大化时其他面板缩成带颜色、横排名称的 banner；也能单独最小化，点击 banner 恢复。
- 面板颜色、正文、附加按钮、banner、空单元格、覆盖层和分隔线外观均可定制。
- 卡片 Header 保留图标、名称，以及右侧固定的最小化、最大化按钮；附加按钮放在它们前面。
- 窗口四周支持自定义区域。原生 Header 与红绿灯共用一行，Logo 右侧可添加最多 3 个自定义动作或链接。
- 右侧布局工具栏默认展开，点向右箭头后带动画收起，可再次展开。
- Footer 左右两侧是独立的内容插槽，支持自定义状态、文字、菜单和按钮。
- 支持键盘调整、辅助功能标签和系统“减弱动态效果”；无第三方运行时依赖。

## 环境与运行

需要 macOS 26+、Swift 6.3、Xcode 26.6+。构建脚本使用 `DEVELOPER_DIR`，不会更改系统的 Xcode 选择。

```sh
brew install xcodegen swiftlint
./scripts/build.sh -quiet
./scripts/run.sh
```

窗口启动时居中，使用屏幕可用宽度的 92%、高度的 90%。演示卡片的 `+` 会在当前位置添加空间，调色板按钮切换颜色；Header 中的代码图标打开 GitHub 仓库。演示内容和布局不跨启动保存。

## 接入 SDK

在 Xcode 中添加 `https://github.com/nocoo/infospace`，选择 `InfoSpaceCore` 与 `InfoSpaceUI` 两个 library product。开发时也可以直接把当前目录作为本地 Swift Package 引入。

| 组件 | 用法 |
| --- | --- |
| `InfoSpaceCanvas` | 只嵌入网格，可放在其他界面的右上角等任意位置。 |
| `InfoSpaceWorkspace` | 完整工作区，可定制上、下、左、右的周边视图。 |
| `InfoSpaceWindow` | 可选的原生窗口 Scene，提供居中、初始尺寸和统一 Header。 |
| `InfoSpaceToolbar` | 自定义 Logo/名称、旁边最多 3 个按钮，以及右侧工具。 |
| `InfoSpaceLayoutControls` | 可嵌入任意区域的行列工具，支持动画收起。 |
| `InfoSpaceFooter` | 放在底部区域，独立定制左侧和右侧内容。 |

`SpaceID` 表示内容身份，`SpacePosition` 表示当前行列。位置从 0 开始；移动后 ID 保持不变。

```swift
let model = InfoSpaceModel(rows: 2, columns: 4, fillEmptyCells: false)
let notes = SpaceID("notes")
try model.insertSpace(notes, at: SpacePosition(row: 1, column: 3))
try model.setProportions(rows: [1, 2], columns: [1, 2, 2, 1])
```

API 在主线程执行。目标位置已有空间时，插入默认把已有空间顺次移动；空间不足时扩展行列，上限为 8 × 8。失败会抛出错误，原布局保持不变。`collision: .reject` 可以要求目标位置必须为空。

`resizeGrid` 保留已有空间，容量不足则报错。演示用的 `setDimensions` 会填满新网格，并移除超出新行列的空间。接入真实数据时使用前者。

通过 `SpaceAppearance` 自定义每张卡片，通过 `SpaceAction` 添加卡片按钮，通过 `InfoSpaceHeaderAction` 添加 Logo 旁的按钮或链接。`InfoSpaceStyle` 管理工作区颜色、间距和动画。具体用法见 [SDK 文档](docs/API.md) 与 [Examples](Examples)，示例代码会随项目编译验证。

## 验证

```sh
./scripts/check.sh
python3 scripts/verify-ui.py
```

`check.sh` 执行严格 Lint、单元测试、SDK 示例编译及 Release 构建；GitHub Actions 还会构建原生 App。单元测试覆盖插入、移动、错误回滚、比例、吸附、稀疏布局，以及 12 面板的全部 4,096 种最小化组合。

原生窗口检查需要已登录的 macOS 桌面，并先构建 App。它只向自身窗口发送事件、截取自身窗口，检查按钮、拖动、工具栏、链接及内容状态保留；报告位于 `.local/inspections/`。几何计算耗时不代表实际渲染帧率。当前采用实时内容缩放，没有实现截图冻结。

## 协议

[MIT](LICENSE)，copyright © 2026 NOCOO。
