import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("joystickHapticsEnabled") private var joystickHapticsEnabled = true
    @AppStorage("showPing") private var showPing = false

    var body: some View {
        NavigationView {
            List {
                Toggle("Continuous Joystick Haptics", isOn: $joystickHapticsEnabled)
                Toggle("Display Ping", isOn: $showPing)
            }
                .navigationBarTitle("Settings")
                .navigationBarItems(trailing: Button("Close", action: {
                    self.presentationMode.wrappedValue.dismiss()
                }))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
