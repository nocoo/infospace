import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

/// A protected editor with two independently arranged reference panels.
struct ProtectedWorkspaceExample: View {
    @State private var model: InfoSpaceModel

    init() throws {
        let layout = try SpaceLayout(
            grid: SpaceGrid(rows: 2, columns: 2),
            entries: [
                SpaceEntry(
                    id: SpaceID("editor"), position: .init(row: 0, column: 0),
                    span: .fullHeight(columns: 1), allowsMove: false, allowsRemoval: false),
                SpaceEntry(id: SpaceID("reference"), position: .init(row: 0, column: 1)),
            ])
        _model = State(initialValue: InfoSpaceModel(layout: layout))
    }

    private func appearance(_ identity: SpaceID) -> SpaceAppearance {
        SpaceAppearance(title: identity.rawValue.capitalized, symbol: "doc.text", color: .teal)
    }

    var body: some View {
        InfoSpaceCanvas(model: model, appearance: appearance) { identity in
            Text(identity.rawValue)
        }
    }
}
