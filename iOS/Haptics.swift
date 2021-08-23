import UIKit
import CoreHaptics

class Haptics {
    private var engine: CHHapticEngine?
    private var engineNeedsStart = true
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    
    private lazy var supportsHaptics: Bool = {
        // Check if the device supports haptics.
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        return hapticCapability.supportsHaptics
    }()
    
    private let sharpness: Float
    
    init(sharpness: Float) {
        self.sharpness = sharpness
        if supportsHaptics {
            createAndStartHapticEngine()
            createContinuousHapticPlayer()
        }
    }
    
    private func createAndStartHapticEngine() {
        do {
            engine = try CHHapticEngine()
        } catch let error {
            print("haptic error", error)
        }
        
        // Mute audio to reduce latency for collision haptics.
        engine?.playsHapticsOnly = true
        
        // The stopped handler alerts you of engine stoppage.
        engine?.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt:
                print("Audio session interrupt")
            case .applicationSuspended:
                print("Application suspended")
            case .idleTimeout:
                print("Idle timeout")
            case .systemError:
                print("System error")
            case .notifyWhenFinished:
                print("Playback finished")
            case .gameControllerDisconnect:
                print("Controller disconnected.")
            case .engineDestroyed:
                print("Engine destroyed.")
            @unknown default:
                print("Unknown error")
            }
        }
        
        // The reset handler provides an opportunity to restart the engine.
        engine?.resetHandler = {
            
            print("Reset Handler: Restarting the engine.")
            
            do {
                // Try restarting the engine.
                try self.engine?.start()
                
                // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                self.engineNeedsStart = false
                
                // Recreate the continuous player.
                self.createContinuousHapticPlayer()
                
            } catch {
                print("Failed to start the engine")
            }
        }
        
        // Start the haptic engine for the first time.
        do {
            try self.engine?.start()
        } catch {
            print("Failed to start the engine: \(error)")
        }
    }
    
    /// - Tag: CreateContinuousPattern
    private func createContinuousHapticPlayer() {
        // Create an intensity parameter:
        let intensity = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: 0.5
        )
        
        // Create a sharpness parameter:
        let sharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: self.sharpness
        )
        
        // Create a continuous event with a long duration from the parameters.
        let continuousEvent = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 100
        )
        
        do {
            // Create a pattern from the continuous haptic event.
            let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
            
            // Create a player from the continuous haptic pattern.
            continuousPlayer = try engine?.makeAdvancedPlayer(with: pattern)
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
    }
    
    public func start() {
        try? self.continuousPlayer?.start(atTime: CHHapticTimeImmediate)
    }
    
    public func stop() {
        try? self.continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
    }
    
    public func setIntensity(_ val: CGFloat) {
        // Create dynamic parameters for the updated intensity & sharpness.
        let intensityParameter = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl,
            value: 0.5 * Float(val),
            relativeTime: 0
        )
        
        // Send dynamic parameters to the haptic player.
        do {
            try self.continuousPlayer?.sendParameters([intensityParameter], atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Dynamic Parameter Error: \(error)")
        }
    }
}
