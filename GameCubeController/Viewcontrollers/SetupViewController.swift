//
//  ViewController.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/9/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import UIKit
import ARMDevSuite

class GCVC: UIViewController {
	static let shared = GCVC()
	var alerts: AlertManager!

	override func viewDidLoad() {
		super.viewDidLoad()
		UIView.appearance().tintColor = text
		// Do any additional setup after loading the view.
		self.alerts = AlertManager(vc: self)
		self.alerts.hud.backgroundAlpha = 0.9
		self.alerts.hud.overlayStyle = self.isDark ? .dark : .light
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		UIView.appearance().tintColor = text
	}
}

class SetupViewController: GCVC {

	let welcomeImage = UIImageView()
	
	let ipRequest = ARMTextField()
	let portRequest = ARMTextField()
	
	let connectButton = UIButton()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		initUI()

		ipRequest.text = "172.20.10.4"
		portRequest.text = "3000"
	}

	func initUI() {
		initImages()
		initFields()
		initConnectButton()
	}
	
	func initImages() {
		view.addSubview(welcomeImage)
		welcomeImage.translatesAutoresizingMaskIntoConstraints = false
		welcomeImage.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
		welcomeImage.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: .padding).isActive = true
		welcomeImage.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.35).isActive = true
		welcomeImage.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor).isActive = true
		welcomeImage.contentMode = .scaleAspectFit
		welcomeImage.image = UIImage.logo
	}
	
	func styleField(_ tf: ARMTextField) {
		tf.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 1/3).isActive = true
		tf.textAlignment = .center
		
		tf.textColor = text
		tf.tintColor = text
		tf.selectedTitleColor = text
		tf.selectedLineColor = text
		
		tf.titleColor = placeholder
		tf.placeholderColor = placeholder
		tf.lineColor = placeholder
		
		tf.lineErrorColor = textAccent
		tf.errorColor = textAccent
	}
	func styleButton(_ b: UIButton) {
		b.setBackgroundColor(color: text, forState: .normal)
		b.setTitleColor(stdBkgrnd, for: .normal)
	}
	
	func initFields() {
		view.addSubview(ipRequest)
		ipRequest.center(in: self.view, direction: .horizontal)
		ipRequest.topAnchor.constraint(equalTo: welcomeImage.bottomAnchor, constant: .padding).isActive = true
		
		ipRequest.placeholder = "IP Address"
		ipRequest.keyboardType = .decimalPad
		
		
		view.addSubview(portRequest)
		portRequest.center(in: self.view, direction: .horizontal)
		portRequest.topAnchor.constraint(equalTo: ipRequest.bottomAnchor, constant: .padding).isActive = true
		
		portRequest.placeholder = "Port Number"
		portRequest.keyboardType = .numberPad
		portRequest.returnKeyType = .go
		
		portRequest.addTarget(self, action: #selector(prepForController(_:)), for: .editingDidEndOnExit)
		
		
		styleField(ipRequest)
		styleField(portRequest)

	}
	
	func initConnectButton() {
		view.addSubview(connectButton)
		connectButton.center(in: self.view, direction: .horizontal)
		connectButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
		connectButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 1/3).isActive = true
		connectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -.padding).isActive = true
		
		connectButton.layer.cornerRadius = 20
		connectButton.clipsToBounds = true
		
		connectButton.setTitle("Connect", for: .normal)
		connectButton.addTarget(self, action: #selector(prepForController(_:)), for: .touchUpInside)
		
		styleButton(connectButton)
	}
	
	func setColors() {
		styleField(ipRequest)
		styleField(portRequest)
		
		styleButton(connectButton)
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		
		guard UIApplication.shared.applicationState == .inactive else {
				return
		}

		setColors()
		
	}
	
	@objc func prepForController(_ sender: UIButton) {
		guard let ip = ipRequest.text, let port = portRequest.text else { self.alerts.displayAlert(titled: "Oops", withDetail: "Invalid URL Provided", completion: nil); return }
		sender.isUserInteractionEnabled = false
		
		self.alerts.startProgressHud(withTitle: "Fetching Available Slots")
		ControllerAPI.shared.connectToServer(ip: ip, port: port) { (err) in
			guard err == nil else {
				self.alerts.triggerHudFailure(withHeader: "Oops", andDetail: err)
				sender.isUserInteractionEnabled = true
				return
			}
			
			ControllerAPI.shared.getControllers { (playerIDs, err) in
				sender.isUserInteractionEnabled = true
				guard let ids = playerIDs, err == nil else {
					self.alerts.triggerHudFailure(withHeader: "Oops", andDetail: err)
					return
				}
				
				self.alerts.dismissHUD()
				self.attachToController(options: ids)
				
				
				
			}
			
		}
	}
	
	
	func attachToController(options: [Int]) {
		let alert = UIAlertController(title: "Pick a Controller", message: nil, preferredStyle: .alert)
		
		for option in options {
			alert.addAction(UIAlertAction(title: "Player \(option)", style: .default, handler: { (_) in
				self.becomePlayer(option)
			}))
		}
		
		self.present(alert, animated: true, completion: nil)
		
	}
	
	func becomePlayer(_ idx: Int) {
		self.alerts.startProgressHud(withTitle: "Connecting to Player \(idx)")
		ControllerAPI.shared.becomeController(idx: idx) { (err) in
			guard err == nil else {
				self.alerts.triggerHudFailure(withHeader: "Oops", andDetail: err)
				return
			}
			
			self.alerts.triggerHudSuccess(withHeader: "Success", andDetail: "Connected to Player \(idx)", onComplete: {
				self.advanceToController(idx: idx)
			})
			
		}
	}
	
	func advanceToController(idx: Int) {
		self.performSegue(withIdentifier: "2controller", sender: idx)
	}
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let c = segue.destination as? ControllerViewController {
			c.playerID = sender as! Int
		}
	}
	
	

}

