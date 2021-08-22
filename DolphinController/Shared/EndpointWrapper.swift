import Foundation
import Network

/// EndpointWrapper provides a type wrapping a NWEndpoint that that can be serialized and deserialized.
class EndpointWrapper: NSObject, NSCoding {
    private enum EndpointType: UInt8 {
        case hostPort
        case service
        case unix
        case url
    }
    
    private static let _typeKey = "__endpoint_type"
    
    func encode(with coder: NSCoder) {
        switch endpoint {
        case .service(name: let name, type: let type, domain: let domain, interface: _):
            coder.encode(EndpointType.service.rawValue, forKey: Self._typeKey)
            coder.encode(name, forKey: "name")
            coder.encode(type, forKey: "type")
            coder.encode(domain, forKey: "domain")
        default:
            fatalError("unknown NWEndpoint case")
        }
    }
    
    required convenience init?(coder: NSCoder) {
        guard let endpointTypeRaw = coder.decodeObject(forKey: Self._typeKey) as? UInt8,
              let endpointType = EndpointType(rawValue: endpointTypeRaw) else {
            return nil
        }
        switch endpointType {
        case .service:
            guard let name = coder.decodeObject(forKey: "name") as? String,
                  let type = coder.decodeObject(forKey: "type") as? String,
                  let domain = coder.decodeObject(forKey: "domain") as? String else {
                return nil
            }
            self.init(NWEndpoint.service(name: name, type: type, domain: domain, interface: nil))
        default:
            return nil
        }
    }
    
    let endpoint: NWEndpoint
    
    init(_ endpoint: NWEndpoint) {
        self.endpoint = endpoint
    }
}
