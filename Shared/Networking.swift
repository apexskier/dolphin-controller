import Foundation
import Network
import CryptoKit

let serviceType = "dolphinC"

extension NWParameters {
    static func custom() -> NWParameters {
        // Customize TCP options to enable keepalives.
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        // Create parameters with custom TLS and TCP options.
        let params = NWParameters(tls: NWParameters.tlsOptions(passcode: "passcode"), tcp: tcpOptions)

        // Enable using a peer-to-peer link.
        params.includePeerToPeer = true
        params.acceptLocalOnly = false
        params.serviceClass = .interactiveVideo // not really, but I want this fast, and it's low size

        // Add your custom game protocol to support game messages.
        let controllerProtocolOptions = NWProtocolFramer.Options(definition: ControllerProtocol.definition)
        params.defaultProtocolStack.applicationProtocols.insert(controllerProtocolOptions, at: 0)
        
        return params
    }
    
    // Create TLS options using a passcode to derive a pre-shared key.
    private static func tlsOptions(passcode: String) -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()

        let authenticationKey = SymmetricKey(data: passcode.data(using: .utf8)!)
        var authenticationCode = HMAC<SHA256>.authenticationCode(
            for: "DolphinController".data(using: .utf8)!,
            using: authenticationKey
        )

        let authenticationDispatchData = withUnsafeBytes(of: &authenticationCode) { ptr in
            DispatchData(bytes: ptr)
        }

        sec_protocol_options_add_pre_shared_key(
            tlsOptions.securityProtocolOptions,
            authenticationDispatchData as __DispatchData,
            stringToDispatchData("DolphinController")! as __DispatchData
        )
        sec_protocol_options_append_tls_ciphersuite(
            tlsOptions.securityProtocolOptions,
            tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256))!
        )
        return tlsOptions
    }
    
    // Utility function to encode strings as pre-shared key data.
    private static func stringToDispatchData(_ string: String) -> DispatchData? {
        guard let stringData = string.data(using: .unicode) else {
            return nil
        }
        let dispatchData = withUnsafeBytes(of: stringData) { ptr in
            DispatchData(bytes: UnsafeRawBufferPointer(start: ptr.baseAddress, count: stringData.count))
        }
        return dispatchData
    }
}

extension NWParameters {
    static func cemuhook() -> NWParameters {
        let udpOptions = NWProtocolUDP.Options()
        let params = NWParameters(dtls: nil, udp: udpOptions)

        // Enable using a peer-to-peer link.
        params.includePeerToPeer = true
        params.acceptLocalOnly = false
        params.serviceClass = .interactiveVideo // not really, but I want this fast, and it's low size

        let controllerProtocolOptions = NWProtocolFramer.Options(definition: CemuhookProtocol.definition)
        params.defaultProtocolStack.applicationProtocols.insert(controllerProtocolOptions, at: 0)

        return params
    }
}

extension NWConnection: Equatable {
    public static func == (lhs: NWConnection, rhs: NWConnection) -> Bool {
        lhs.endpoint == rhs.endpoint
    }
}

extension NWConnection {
    func sendMessage(_ type: ControllerMessageType, data: Data) {
        let message = NWProtocolFramer.Message(controllerMessageType: type)
        let context = NWConnection.ContentContext(
            identifier: type.debugDescription,
            metadata: [message]
        )

        self.send(
            content: data,
            contentContext: context,
            isComplete: true,
            completion: .idempotent
        )
    }

    func handleReceiveError(error: NWError) {
        var shouldCancel = true
        if case .posix(let code) = error {
            switch code {
            case .ENODATA:
                print("Disconnected (no data)")
            case .ECONNABORTED:
                print("Connection aborted")
            case .ECANCELED:
                shouldCancel = false
                print("Connection cancelled")
            default:
                print("Posix error", error)
            }
        } else {
            print("Error", error)
        }
        if shouldCancel {
            // we explicitly cancel even if the connection has been aborted
            // without this, the connection takes a bit to transition to its
            // cancelled state, which is not a great UX
            self.cancel()
        }
    }
}
