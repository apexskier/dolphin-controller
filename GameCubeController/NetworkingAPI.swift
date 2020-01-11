//
//  NetworkingAPI.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/9/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import Foundation

typealias GameCubeError = String
typealias Response<T> = ((T?, GameCubeError?) -> ())
typealias ErrorReturn = (GameCubeError?) -> ()
typealias BlankClosure = ()->()

func onMain(exec: BlankClosure?) {
	DispatchQueue.global().async {
		DispatchQueue.main.async {
			exec?()
		}
	}
}

enum Endpoint: String {
	case controller = "controller"
	case connect = "controller/connect"
	case command = "controller/command"
	case disconnect = "controller/disconnect"
	
	var description: String { return self.rawValue }
}

class ControllerAPI {
	static let shared = ControllerAPI()
	
	var host: String?
	var port: String?
	
	
	func endpoint(_ e: Endpoint) -> String? {
		guard let h = host, let p = port else { return nil }
		return endpoint(e, host: h, port: p)
	}
	
	func endpoint(_ e: Endpoint, host: String, port: String) -> String {
		return "http://\(host):\(port)/\(e.description)"
	}
	
	func connectToServer(ip: String, port: String, completion: ErrorReturn?) {
		let urlString = endpoint(.controller, host: ip, port: port)
		NetworkingLib.shared.get(url: urlString, params: nil) { (_, err) in
			self.host = ip
			self.port = port
			completion?(err)
		}
	}
	
	func getControllers(completion: Response<[Int]>?) {
		let urlString = endpoint(.connect)
		NetworkingLib.shared.get(url: urlString, params: nil) { (controllers, err) in
			guard err == nil else { completion?(nil, err); return }
			if let c = controllers as? [Int] {
				if c.count == 0 {
					completion?(nil, "No Controllers Available")
				} else {
					completion?(c, nil)
				}
			} else {
				completion?(nil, "Controller response failed to match expected format.")
			}
		}
	}
	
	func becomeController(idx: Int, completion: ErrorReturn?) {
		NetworkingLib.shared.post(url: endpoint(.connect), params: ["player_idx": idx]) { (_, err) in
			completion?(err)
		}
	}
	func disconnectController(idx: Int, completion: ErrorReturn?) {
		NetworkingLib.shared.post(url: endpoint(.disconnect), params: ["player_idx": idx]) { (_, err) in
			completion?(err)
		}
	}
	
	func sendCommand(player: Int, action: String, control: String, value: String?, completion: ErrorReturn?) {
		NetworkingLib.shared.post(url: endpoint(.command), params: [
			"player_idx": player,
			"action": action,
			"input_name": control,
			"value": value
		]) { (_, err) in
			completion?(err)
		}
	}
	
}


class NetworkingLib {
	static let shared = NetworkingLib()
	let session = URLSession.shared
	
	func post(url: String? , params: [String: Any]?, completion: Response<Any>?) {
		guard
				let urlString = url,
				let url = URL(string: urlString)
		else { completion?(nil, "Invalid URL provided"); return }
		
		guard let jsonData = try? JSONSerialization.data(withJSONObject: params ?? [:], options: [])
			else { completion?(nil, "Invalid body params provided"); return }
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.httpBody = jsonData
		
		let task = session.uploadTask(with: request, from: nil) { (data, resp, err) in
			onMain {
				guard let data = data, let resp = resp, err == nil else {
					completion?(nil, err?.localizedDescription)
					return
				}
				guard let mime = resp.mimeType else {
					completion?(nil, "Unable to recognize format of response")
					return
				}
				
				guard let httpResponse = resp as? HTTPURLResponse,
							(200...299).contains(httpResponse.statusCode) else {
								// can try to extract more info from the error here
								if mime == "text/html", let txt = String(data: data, encoding: .utf8) {
									completion?(nil, txt)
								} else {
									completion?(nil, "Invalid Response Code \((resp as? HTTPURLResponse)?.statusCode ?? 0)")
								}
								
						return
				}
				
				if mime == "application/json", let json = try? JSONSerialization.jsonObject(with: data, options: []) {
					completion?(json, nil)
				} else if mime == "text/html", let txt = String(data: data, encoding: .utf8) {
					completion?(txt, nil)
				} else {
					completion?(nil, "Unable to parse response (Type: \(mime))")
				}
			}
		}
		
		task.resume()

	}
	
	func get(url: String?, params: [String: String]?, completion: Response<Any>?) {
		guard
			let urlString = url,
			let url = URL(string: urlString),
			var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			else { completion?(nil, "Invalid URL provided"); return }
		
		if let params = params {
			components.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value)})
		}
		
		guard let targetURL = components.url else { completion?(nil, "Invalid URL provided"); return }
		
		let task = session.dataTask(with: targetURL) { (data, resp, err) in
			onMain {
				guard let data = data, let resp = resp, err == nil else {
					completion?(nil, err?.localizedDescription)
					return
				}
				guard let httpResponse = resp as? HTTPURLResponse,
							(200...299).contains(httpResponse.statusCode) else {
								// can try to extract more info from the error here
								completion?(nil, "Invalid Response Code \((resp as? HTTPURLResponse)?.statusCode ?? 0)")
						return
				}
				
				
				guard let mime = resp.mimeType else {
					completion?(nil, "Unable to recognize format of response")
					return
				}
				if mime == "application/json", let json = try? JSONSerialization.jsonObject(with: data, options: []) {
					completion?(json, nil)
				} else if mime == "text/html", let txt = String(data: data, encoding: .utf8) {
					completion?(txt, nil)
				} else {
					completion?(nil, "Unable to parse response (Type: \(mime))")
				}
			}
		}
		
		task.resume()
		
	}
	
}
