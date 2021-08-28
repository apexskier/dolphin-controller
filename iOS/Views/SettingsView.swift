import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("joystickHapticsEnabled") private var joystickHapticsEnabled = true

    var body: some View {
        NavigationView {
            List {
                HStack {
                    Toggle("Continuous Joystick Haptics", isOn: $joystickHapticsEnabled)
                }
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
