import SwiftUI

struct PingView: View {
    static private let pingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var ping: TimeInterval?

    var body: some View {
        guard let ping = self.ping else {
            return AnyView(EmptyView())
        }
        let pingMilliseconds = ping.truncatingRemainder(dividingBy: 1) * 1000
        guard let pingString = Self.pingFormatter.string(from: NSNumber(value: pingMilliseconds)) else {
            return AnyView(EmptyView())
        }
        return AnyView(
            Text(pingString)
                .font(.callout.monospacedDigit())
                .foregroundColor(GameCubeColors.lightGray.opacity(0.6))
                .help("Server ping in milliseconds")
        )
    }
}

struct PingView_Previews: PreviewProvider {
    static var previews: some View {
        PingView()
    }
}
