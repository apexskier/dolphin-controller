import SwiftUI

struct ButtonTintViewModifier: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .tint(color)
        } else {
            content
        }
    }
}

struct SkinSelectorView: View {
    @Binding var skin: Skin

    var select: (Skin) -> Void

    var body: some View {
        List {
            ForEach(Skin.Rarity.allCases) { rarity in
                Section(header: Text(rarity.description)) {
                    ForEach(Skin.allCases.filter({ $0.rarity == rarity })) {
                        skin in
                        Button(action: {
                            select(skin)
                        }) {
                            HStack {
                                HStack(spacing: 20) {
                                    if UIApplication.shared
                                        .supportsAlternateIcons,
                                        let image = UIImage(
                                            named: skin == .indigo
                                                ? "AppIcon"
                                                : "AppIcon \(skin.name)")
                                    {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height: 60)
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius: 14,
                                                    style: .continuous))
                                    }

                                    Text(skin.name)
                                }

                                Spacer()

                                if self.skin == skin {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .modifier(ButtonTintViewModifier(color: .primary))
                    }
                }
            }
        }
    }
}

@available(iOS 18, *)
#Preview {
    @Previewable @State var skin = Skin.indigo
    SkinSelectorView(skin: $skin, select: { _ in })
}
