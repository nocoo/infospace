import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

enum DemoSpaces {
    private static let indices: [SpaceID: Int] = {
        var result: [SpaceID: Int] = [:]
        for row in 0..<8 {
            for column in 0..<8 {
                let index: Int
                if row < 2 && column < 2 {
                    index = row * 2 + column
                } else if row < 2 {
                    index = 4 + (column - 2) * 2 + row
                } else {
                    index = 16 + (row - 2) * 8 + column
                }
                result[SpaceID(row: row, column: column)] = index
            }
        }
        return result
    }()

    static func index(_ space: SpaceID) -> Int {
        indices[space] ?? (8 + space.rawValue.utf8.reduce(0) { ($0 + Int($1)) % 56 })
    }
    static let names = ["收件箱", "灵感笔记", "项目进展", "今日安排", "参考资料", "随手收藏", "团队动态", "阅读清单"]
    static let symbols = [
        "tray", "lightbulb", "chart.bar.xaxis", "calendar", "doc.text", "bookmark", "person.2", "book",
    ]
    static let colors: [Color] = [
        Color(red: 0.28, green: 0.36, blue: 0.69),
        Color(red: 0.20, green: 0.46, blue: 0.40),
        Color(red: 0.68, green: 0.36, blue: 0.26),
        Color(red: 0.46, green: 0.34, blue: 0.61),
        Color(red: 0.25, green: 0.43, blue: 0.59),
        Color(red: 0.56, green: 0.40, blue: 0.24),
        Color(red: 0.43, green: 0.40, blue: 0.63),
        Color(red: 0.28, green: 0.48, blue: 0.49),
    ]

    static func appearance(_ space: SpaceID) -> SpaceAppearance {
        let index = index(space)
        let suffix = index >= names.count ? " \(index / names.count + 1)" : ""
        return SpaceAppearance(
            title: names[index % names.count] + suffix,
            symbol: symbols[index % symbols.count], color: colors[index % colors.count])
    }
}

struct DemoPanelContent: View, Equatable {
    let space: SpaceID
    @State private var note = "好的想法，需要一点留白。"
    @State private var completed = false
    private var index: Int { DemoSpaces.index(space) }
    private var kind: Int { index % 4 }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { lhs.space == rhs.space }

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(alignment: .leading, spacing: 20) {
                heading
                detail
                Spacer(minLength: 0)
                bottomLabel
            }
            VStack(alignment: .leading, spacing: 12) {
                heading
                bottomLabel
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow).font(.system(size: 10, weight: .semibold, design: .monospaced)).opacity(0.55)
                Text(shortTitle).font(.system(size: 17, weight: .medium)).lineLimit(1)
            }
            Color.clear
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        #if DEBUG
        .onChange(of: note, initial: true) { _, value in
            if WindowInspection.isEnabled { WindowInspection.notes[space.id] = value }
        }
        #endif
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(eyebrow).tracking(2)
                Rectangle().fill(.white.opacity(0.3)).frame(width: 20, height: 1)
                Text(String(format: "%02d", index + 1)).monospacedDigit()
            }
            .font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.6))
            Text(shortTitle).font(.system(size: 29, weight: .medium)).tracking(-0.7)
                .lineLimit(2).minimumScaleFactor(0.7).fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var detail: some View {
        switch kind {
        case 0:
            VStack(spacing: 9) {
                informationRow(
                    symbol: "bubble.left.and.bubble.right", title: "设计讨论", subtitle: "把新的可能性放到一起", trailing: "3")
                informationRow(symbol: "doc.text", title: "本周简报", subtitle: "有两条值得关注的更新", trailing: "2")
            }
        case 1:
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "quote.opening").font(.system(size: 21, weight: .medium)).opacity(0.45)
                TextField("记下一闪而过的想法…", text: $note, axis: .vertical)
                    .textFieldStyle(.plain).font(.system(size: 18, weight: .medium)).lineLimit(1...3)
                    .accessibilityIdentifier("note-\(space.id)")
                    .modifier(InspectionMarker(id: "note-\(space.id)"))
                HStack(spacing: 6) {
                    tag("随手记")
                    tag("可直接编辑")
                }
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        case 2:
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("72").font(.system(size: 48, weight: .light, design: .rounded)).tracking(-2)
                    Text("%").font(.system(size: 20, weight: .light)).opacity(0.6)
                    Spacer(minLength: 8)
                    Text("进行顺利").font(.system(size: 11)).opacity(0.7)
                }
                ProgressView(value: 0.72).tint(.white.opacity(0.85))
                Button {
                    completed.toggle()
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                        Text(completed ? "交互原型已完成" : "下一步：完成交互原型")
                            .strikethrough(completed).lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .font(.system(size: 12)).foregroundStyle(.white.opacity(0.75))
                }
                .buttonStyle(.plain).accessibilityIdentifier("task-\(space.id)")
            }
        default:
            VStack(spacing: 0) {
                scheduleRow(time: "09:30", title: "留一点时间，专注创造", subtitle: "专注时段 · 60 分钟")
                Rectangle().fill(.white.opacity(0.12)).frame(height: 1).padding(.vertical, 15)
                scheduleRow(time: "14:00", title: "聊聊下一个好想法", subtitle: "设计交流 · 30 分钟")
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var bottomLabel: some View {
        HStack(spacing: 5) {
            Circle().fill(.white.opacity(0.4)).frame(width: 4, height: 4)
            Text(["留意重要的，收好有用的", "想法在这里慢慢生长", "每一小步，都算数", "给重要的事留出时间"][kind])
                .lineLimit(1)
        }
        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.45))
    }

    private var eyebrow: String { ["COLLECT", "EXPLORE", "BUILD", "MAKE TIME"][kind] }
    private var shortTitle: String { ["重要的，都在这里。", "给想法一点空间。", "让进展一目了然。", "按自己的节奏来。"][kind] }
    private var subtitle: String { ["消息、动态，以及值得回看的片段。", "灵感不必整齐，先把它留下来。", "从一个想法，到逐渐成形。", "在忙碌之间，为自己留一点余地。"][kind] }

    private func informationRow(symbol: String, title: String, subtitle: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 15)).opacity(0.75)
                .frame(width: 32, height: 32).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                Text(subtitle).font(.system(size: 10)).opacity(0.55).lineLimit(1)
            }
            Spacer(minLength: 2)
            Text(trailing).font(.system(size: 10, weight: .semibold, design: .rounded))
                .frame(width: 20, height: 20).background(.white.opacity(0.12), in: Circle())
        }
        .padding(12).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }

    private func tag(_ title: String) -> some View {
        Text(title).font(.system(size: 10)).foregroundStyle(.white.opacity(0.65))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.white.opacity(0.08), in: Capsule())
    }

    private func scheduleRow(time: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(time).font(.system(size: 12, weight: .medium, design: .monospaced)).opacity(0.65)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                Text(subtitle).font(.system(size: 10)).opacity(0.5).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}
