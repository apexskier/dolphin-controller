import Foundation
import Combine

extension ObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher {
    func forwardChanges<T: ObservableObject>(
        to forwardTo: T
    ) -> AnyCancellable where T.ObjectWillChangePublisher == ObservableObjectPublisher {
        return self.objectWillChange.sink { _ in
            DispatchQueue.main.async {
                forwardTo.objectWillChange.send()
            }
        }
    }
    
    func forwardChanges<T: ObservableObject>(
        from forwardFrom: T
    ) -> AnyCancellable where T.ObjectWillChangePublisher == ObservableObjectPublisher {
        return forwardFrom.objectWillChange.sink { _ in
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}

class ObservableArray<T>: ObservableObject {
    @Published var contents: Array<T>
    
    init(_ contents: Array<T>) {
        self.contents = contents
    }
    
    init() {
        self.contents = Array<T>()
    }
}
