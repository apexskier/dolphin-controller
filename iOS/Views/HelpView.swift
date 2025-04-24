import Foundation
import SwiftUI

let serverInstallURL = URL(string: "https://github.com/apexskier/dolphin-controller")!
let serverInstallURLDescription = "Server Installation Instructions"
let appURL = URL(string: "https://apps.apple.com/us/app/id1584272645")!

struct CustomLink<Label: View>: View {
    var item: URL
    var subject: String
    var message: String
    @ViewBuilder var label: () -> Label

    var body: some View {
        if #available(iOS 16.0, *) {
            ShareLink(
                item: item,
                subject: Text(subject),
                message: Text(message),
                label: label
            )
        } else {
            Link(subject, destination: item)
        }
    }
}

struct HelpView: View {
    var body: some View {
        Section(
            header: Text("No server?"),
            footer: Text("You'll need to install and run the server alongside Dolphin on your Mac.")
        ) {
            Link(serverInstallURLDescription, destination: serverInstallURL)
            CustomLink(
                item: serverInstallURL,
                subject: "Dolphin Controller Server",
                message: "Follow this link to install the Dolphin Controller server on your Mac.",
                label: {
                    Text("\(Image(systemName: "square.and.arrow.up")) Share \(serverInstallURLDescription)")
                }
            )
        }
    }
}

#Preview {
    HelpView()
}
