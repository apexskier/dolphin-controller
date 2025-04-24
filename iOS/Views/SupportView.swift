import SwiftUI
import StoreKit

struct TipButtonStyleButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color(red: 0, green: 0, blue: 0.5))
            // .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

@available(iOS 17.0, *)
struct SupportView: View {
    @Environment(\.purchase) private var purchase: PurchaseAction
    @State private var initialProducts: [Product]? = nil
    @State private var supports: [Product]? = nil
    @Environment(\.dismiss) private var dismiss

    var hasSupported: Bool
    var postSupport: () -> Void

    var products: [Product]? {
        hasSupported ? initialProducts : supports
    }

    @State var error: VerificationResult<StoreKit.Transaction>.VerificationError? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            if hasSupported {
                Text("Thanks for supporting this app! If you want to contribute more, thank you so much!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
            } else {
                Text("Thanks for using this app! By supporting development, you'll unlock special features and help keep this app running.")
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            HStack {
                if let products {
                    ForEach(products) { product in
                        Button {
                            Task {
                                switch try? await purchase(product) {
                                case .success(let verificationResult):
                                    switch verificationResult {
                                    case .verified(let transaction):
                                        await transaction.finish()
                                        dismiss()
                                        postSupport()
                                    case .unverified(_, let error):
                                        self.error = error
                                    }
                                default:
                                    break
                                }
                            }
                        } label: {
                            Text(product.displayPrice)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .buttonStyle(GCCButton(
                color: GameCubeColors.green,
                width: 100,
                height: 42,
                shape: RoundedRectangle(cornerRadius: 4, style: .continuous)
            ))
            Spacer()
        }
        .storeProductsTask(for: ["tip1", "tip5", "tip10"]) { states in
            initialProducts = states.products
        }
        .storeProductsTask(for: ["support1", "support5", "support10"]) { states in
            supports = states.products
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    SupportView(hasSupported: true) { }
}
