import Foundation

/// Persistable committed state. Drag previews and host content are deliberately excluded.
public struct SpaceSnapshot: Codable, Equatable, Sendable {
    public let version: Int
    public let revision: UInt64
    public let layout: SpaceLayout
    public let minimized: Set<SpaceID>
    public let maximized: SpaceID?

    public init(
        layout: SpaceLayout, revision: UInt64 = 0, minimized: Set<SpaceID> = [], maximized: SpaceID? = nil
    ) throws {
        version = 1
        self.revision = revision
        self.layout = layout
        self.minimized = minimized
        self.maximized = maximized
        try validate()
    }

    public func validate() throws {
        guard version == 1 else { throw InfoSpaceError.unsupportedSnapshotVersion }
        let identities = Set(layout.entries.map(\.id))
        guard minimized.isSubset(of: identities),
            maximized.map({ identities.contains($0) && !minimized.contains($0) }) ?? true
        else { throw InfoSpaceError.invalidSnapshot }
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        revision = try values.decode(UInt64.self, forKey: .revision)
        layout = try values.decode(SpaceLayout.self, forKey: .layout)
        minimized = try values.decode(Set<SpaceID>.self, forKey: .minimized)
        maximized = try values.decodeIfPresent(SpaceID.self, forKey: .maximized)
        try validate()
    }

    /// One atomic revision, including a batch of structural commands or an undo snapshot.
    public func applying(_ command: SpaceCommand, expectedRevision: UInt64) throws -> SpaceSnapshot {
        guard revision == expectedRevision, revision < UInt64.max else { throw InfoSpaceError.revisionConflict }
        var nextLayout = layout
        var nextMinimized = minimized
        var nextMaximized = maximized
        switch command {
        case .layout(let commands):
            nextLayout = try layout.applying(commands)
            nextMaximized = nextLayout == layout ? maximized : nil
            nextMinimized.formIntersection(Set(nextLayout.entries.map(\.id)))
        case .minimize(let identity):
            try require(identity)
            nextMinimized.insert(identity)
            nextMaximized = maximized == identity ? nil : maximized
        case .maximize(let identity):
            try require(identity)
            nextMinimized.remove(identity)
            nextMaximized = nextMaximized == identity ? nil : identity
        case .restore(let identity):
            try require(identity)
            nextMinimized.remove(identity)
            nextMaximized = nil
        case .restoreLayout: nextMaximized = nil
        case .restoreAll:
            nextMinimized = []
            nextMaximized = nil
        case .restoreSnapshot(let snapshot):
            try snapshot.validate()
            try snapshot.layout.validatePreservingConstraints(of: layout)
            nextLayout = snapshot.layout
            nextMinimized = snapshot.minimized
            nextMaximized = snapshot.maximized
        }
        guard nextLayout != layout || nextMinimized != minimized || nextMaximized != maximized else { return self }
        return try SpaceSnapshot(
            layout: nextLayout, revision: revision + 1, minimized: nextMinimized, maximized: nextMaximized)
    }

    private func require(_ identity: SpaceID) throws {
        guard layout.position(of: identity) != nil else { throw InfoSpaceError.unknownSpace(identity) }
    }
}

public enum SpaceCommand: Codable, Equatable, Sendable {
    case layout([SpaceLayoutCommand])
    case minimize(SpaceID)
    case maximize(SpaceID)
    case restore(SpaceID)
    case restoreLayout
    case restoreAll
    case restoreSnapshot(SpaceSnapshot)
}
