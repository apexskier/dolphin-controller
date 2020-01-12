//
//  SocketCommand.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/11/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import Foundation
import SocketIO

struct TwoWayResponse {
	var status: Int
	var error: String?
	var data: [String: Any]?
}

class SocketCommander: NSObject {
	static let shared = SocketCommander()
	
	let address = "172.20.10.4:4000"
	
	var manager: SocketManager!
	var socket: SocketIOClient!
	
	override init() {
			super.init()
		
	}
	
	func connect(host: String, port: String, completion: ErrorReturn?) {
		let url = "http://\(host):\(port)"
		manager = SocketManager(socketURL: URL(string: url)!)
		socket = manager.defaultSocket
		
		var handler = completion
		
		socket.connect(timeoutAfter: 3000) {
			handler?("Failed to connect to server at \(url)")
			handler = nil
		}
		
		socket.on(clientEvent: .connect) { (_, _) in
			handler?(nil)
			self.socket.on(clientEvent: .statusChange) { (d, a) in
				print(type(of: d.first))
				if let stat = d.first as? SocketIOStatus {
					if stat == .connecting {
						self.socket.disconnect()
					}
				}
			}
		}
		
		
		

	}
	
	func emitCommand(data: SocketData) {
		print(Date().timeIntervalSince1970, data, "\n\n")
		socket.emit("command", data)
	}
	
	func twoWayRequest(on channel: String, payload: SocketData, completion: Response<TwoWayResponse>?) {
		socket.emit(channel, payload) {
			self.socket.on(channel) { (data, ack) in
				guard let resp = data.first as? [String: Any] else {
					completion?(nil, "No Response Payload")
					return
				}
				
				guard let stat = resp["status"] as? Int else {
					completion?(nil, "Response Payload does not match expected format")
					return
				}
				
				if (200..<300).contains(stat) {
					if let data = resp["data"] as? [String: Any] {
						completion?(TwoWayResponse(status: stat, error: nil, data: data), nil)
					} else {
						completion?(TwoWayResponse(status: stat, error: nil, data: nil), nil)
					}
				} else {
					let err = resp["error"] as? String ?? "No error message provided"
					completion?(TwoWayResponse(status: stat, error: err, data: nil), nil)
				}
				
			}
		}
	}
	
	
	

	
	
}
