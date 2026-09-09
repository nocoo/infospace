import InfoSpaceCore
import InfoSpaceUI
import SwiftUI

/// A canvas owns no window, toolbar or minimum window size. This one sits in a host view's top-right corner.
struct EmbeddedGridExample: View {
    @State private var model = InfoSpaceModel()

    var body: some View {
        HStack(alignment: .top) {
            Text("Main document").font(.title)
            Spacer()
            InfoSpaceCanvas(model: model, appearance: appearance) { identity in
                Text("Content for \(identity.rawValue)")
            }
            .frame(width: 440, height: 320)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func appearance(_ identity: SpaceID) -> SpaceAppearance {
        SpaceAppearance(title: identity.rawValue, symbol: "doc.text", color: .indigo)
    }
}
