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
        case .hostPort(host: let host, port: let port):
            coder.encode(EndpointType.hostPort.rawValue, forKey: Self._typeKey)
            coder.encode(host.debugDescription, forKey: "host")
            coder.encode(port.rawValue, forKey: "port")
        default:
            fatalError("unknown NWEndpoint type")
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
        case .hostPort:
            guard let host = coder.decodeObject(forKey: "host") as? String,
                  let portInt = coder.decodeObject(forKey: "port") as? UInt16,
                  let port = NWEndpoint.Port(rawValue: portInt) else {
                return nil
            }
            self.init(NWEndpoint.hostPort(host: .init(host), port: port))
        default:
            return nil
        }
    }
    
    let endpoint: NWEndpoint
    
    init(_ endpoint: NWEndpoint) {
        self.endpoint = endpoint
    }
}
