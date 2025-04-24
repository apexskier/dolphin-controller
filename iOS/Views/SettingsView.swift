import StoreKit
import SwiftUI

struct HelpTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            content
                .font(.caption)
        }
    }
}

extension Text {
    func helpText() -> some View {
        modifier(HelpTextModifier())
    }
}

enum SupportState {
    case loading
    case supported
    case notYet
}

@available(iOS 17.0, *)
struct SupportModifier: ViewModifier {
    @State var support1Entitlement:
        StoreKit.EntitlementTaskState<
            StoreKit.VerificationResult<StoreKit.Transaction>?
        > = .loading
    @State var support5Entitlement:
        StoreKit.EntitlementTaskState<
            StoreKit.VerificationResult<StoreKit.Transaction>?
        > = .loading
    @State var support10Entitlement:
        StoreKit.EntitlementTaskState<
            StoreKit.VerificationResult<StoreKit.Transaction>?
        > = .loading

    var action:
        (
            StoreKit.EntitlementTaskState<
                StoreKit.VerificationResult<StoreKit.Transaction>?
            >
        ) -> Void

    private func test() {
        // if any entitlement has a transaction, call the action, otherwise return the first which will be loading or failed
        for entitlement in [
            support1Entitlement, support5Entitlement, support10Entitlement,
        ] {
            if entitlement.transaction != nil {
                action(entitlement)
                return
            }
        }
        action(support1Entitlement)
    }

    func body(content: Content) -> some View {
        content
            .currentEntitlementTask(for: "support1") { state in
                support1Entitlement = state
                test()
            }
            .currentEntitlementTask(for: "support5") { state in
                support1Entitlement = state
                test()
            }
            .currentEntitlementTask(for: "support10") { state in
                support1Entitlement = state
                test()
            }
    }
}

enum SupportPageConf {
    case hidden
    case visible(Skin?)
}

struct SettingsView: View {
    @EnvironmentObject private var client: Client
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("keepScreenAwake") private var keepScreenAwake = true
    @AppStorage("joystickHapticsEnabled") private var joystickHapticsEnabled =
        true
    @AppStorage("showPing") private var showPing = false
    @State private var hasSupported: SupportState = .loading

    @Binding var skin: Skin
    @State private var showSupportAlert: SupportPageConf = .hidden
    @State private var showSupportPage: SupportPageConf = .hidden

    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading) {
                    Toggle("Keep Screen Awake", isOn: $keepScreenAwake)
                        .onChange(of: keepScreenAwake) { newValue in
                            client.idleManager?.update()
                        }
                    Text(
                        "Prevent the screen from dimming or turning off while connected to a server."
                    )
                    .helpText()
                }
                VStack(alignment: .leading) {
                    Toggle(
                        "Continuous Joystick Haptics",
                        isOn: $joystickHapticsEnabled)
                    Text("Increase rumble as you move a joystick to its edge.")
                        .helpText()
                }
                Toggle("Display Server Ping", isOn: $showPing)

                if #available(iOS 17.0, *) {
                    Section(
                        header: Text("Supporter Features"),
                        footer: Text(
                            "Support the development of this app and unlock special customization options!"
                        )
                    ) {
                        NavigationLink(
                            isActive: .init(
                                get: {
                                    switch showSupportPage {
                                    case .hidden:
                                        return false
                                    case .visible:
                                        return true
                                    }
                                },
                                set: { isActive in
                                    showSupportPage =
                                        isActive ? .visible(nil) : .hidden
                                })
                        ) {
                            switch hasSupported {
                            case .loading:
                                ProgressView()
                            case .supported:
                                SupportView(hasSupported: true, postSupport: changeSkinAfterSupport)
                            case .notYet:
                                SupportView(hasSupported: false, postSupport: changeSkinAfterSupport)
                            }
                        } label: {
                            Text("Support the App")
                        }

                        NavigationLink {
                            SkinSelectorView(skin: $skin, select: changeSkinWithValidation)
                                .navigationTitle("Choose Appearance")
                        } label: {
                            Text("Change Appearance")
                        }
                    }
                    .alert(
                        "Support the App!",
                        isPresented: .init(
                            get: {
                                switch showSupportAlert {
                                case .hidden:
                                    return false
                                case .visible:
                                    return true
                                }
                            },
                            set: { isPresented in
                                showSupportAlert =
                                    isPresented ? .visible(nil) : .hidden
                            })
                    ) {
                        Button {
                            showSupportPage = showSupportAlert
                        } label: {
                            Text("Support")
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Support the app to use this skin.")
                    }
                    .modifier(
                        SupportModifier(action: { state in
                            switch state {
                            case .loading:
                                hasSupported = .loading
                            default:
                                hasSupported =
                                    state.transaction != nil
                                    ? .supported : .notYet
                            }
                        }))
                }

                HelpView()

                CustomLink(
                    item: appURL,
                    subject: "Dolphin Controller App",
                    message:
                        "Follow this link to install the Dolphin Controller app on your iOS device.",
                    label: {
                        Text(
                            "\(Image(systemName: "square.and.arrow.up")) Share iOS App"
                        )
                    }
                )

                NavigationLink("Attribution") {
                    Text(
                        "Clear background provided by iFixit under the [Creative Commons BY-NC-SA 3.0](http://creativecommons.org/licenses/by-nc-sa/3.0/)."
                    )
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(
                trailing: Button(
                    "Close",
                    action: {
                        self.presentationMode.wrappedValue.dismiss()
                    })
            )
        }
    }

    func postSupportSkin() -> Skin? {
        switch showSupportPage {
        case .hidden:
            return nil
        case .visible(let skin):
            return skin
        }
    }

    func changeSkinAfterSupport() {
        guard let newSkin = postSupportSkin() else {
            return
        }

        changeSkin(skin: newSkin)
    }

    func changeSkinWithValidation(skin: Skin) {
        if skin.requiresSupport
            && hasSupported != .supported
        {
            showSupportAlert = .visible(skin)
            return
        }

        changeSkin(skin: skin)
    }

    func changeSkin(skin: Skin) {
        self.skin = skin

        let current = UIApplication.shared
            .alternateIconName
        let new =
            skin == .indigo
            ? nil : "AppIcon \(skin.name)"
        if current == new {
            return
        }
        UIApplication.shared.setAlternateIconName(new)
    }
}

#Preview {
    SettingsView(skin: .constant(.indigo))
}
