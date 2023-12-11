import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var client: Client
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("keepScreenAwake") private var keepScreenAwake = true
    @AppStorage("joystickHapticsEnabled") private var joystickHapticsEnabled = true
    @AppStorage("showPing") private var showPing = false

    var body: some View {
        NavigationView {
            List {
                Toggle("Keep Screen Awake (when connected to server)", isOn: $keepScreenAwake)
                    .onChange(of: keepScreenAwake) { newValue in
                        client.idleManager?.update()
                    }
                Toggle("Continuous Joystick Haptics", isOn: $joystickHapticsEnabled)
                Toggle("Display Ping", isOn: $showPing)

                HelpView()
            }
                .navigationBarTitle("Settings")
                .navigationBarItems(trailing: Button("Close", action: {
                    self.presentationMode.wrappedValue.dismiss()
                }))
        }
    }
}

#Preview {
    SettingsView()
}
