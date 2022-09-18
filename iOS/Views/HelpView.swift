import Foundation
import SwiftUI

let serverInstallURL = URL(string: "https://github.com/apexskier/dolphin-controller")!
let serverInstallURLDescription = "Server Installation Instructions"
let appURL = URL(string: "https://apps.apple.com/us/app/id1584272645")!

struct HelpView: View {
    var body: some View {
        Section(
            header: Text("No server?"),
            footer: Text("You'll need to install and run the server alongside Dolphin on your Mac.")
        ) {
            Link(serverInstallURLDescription, destination: serverInstallURL)
            if #available(iOS 16.0, *) {
                ShareLink(
                    item: serverInstallURL,
                    subject: Text("Dolphin Controller Server"),
                    message: Text("Follow this link to install the Dolphin Controller server on your Mac."),
                    label: {
                        Text("\(Image(systemName: "square.and.arrow.up")) Share \(serverInstallURLDescription)")
                    }
                )
                ShareLink(
                    item: appURL,
                    subject: Text("Dolphin Controller App"),
                    message: Text("Follow this link to install the Dolphin Controller app on your iOS device."),
                    label: {
                        Text("\(Image(systemName: "square.and.arrow.up")) Share iOS App")
                    }
                )
            } else {
                Link("iOS App", destination: appURL)
            }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
