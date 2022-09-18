import Foundation
import UIKit
import Combine

class IdleManager {
    static let storage = UserDefaults.standard

    var client: Client

    private var cancellable: AnyCancellable? = nil

    init(client: Client) {
        self.client = client

        self.cancellable = client.connection.publisher.sink { _ in
            self.update()
        }
        self.update()
    }

    func update() {

        DispatchQueue.main.async {
            let settingVal = Self.storage.value(forKey: "keepScreenAwake") as? Bool ?? true
            let hasConnection = self.client.connection != nil
            UIApplication.shared.isIdleTimerDisabled = settingVal && hasConnection
        }
    }
}
