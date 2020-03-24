//
//  ViewController.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/9/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import UIKit
import ARMDevSuite
import QRCodeReader

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

var readerVC: QRCodeReaderViewController = {
    let builder = QRCodeReaderViewControllerBuilder {
        $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        
        // Configure the view controller (optional)
        $0.showTorchButton        = true
        $0.showSwitchCameraButton = true
        $0.showCancelButton       = true
        $0.showOverlayView        = true
        $0.rectOfInterest         = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
    }
    
    return QRCodeReaderViewController(builder: builder)
}()



class SetupViewController: GCVC, QRCodeReaderViewControllerDelegate {
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		print(result.value)
		reader.dismiss(animated: true, completion: nil)

		guard let ip = result.value.split(separator: ":").first, let port = result.value.split(separator: ":").last else {
			
			self.alerts.displayAlert(titled: "Oops", withDetail: "Failed to parse config from QR Code", completion: nil)
			return
		}
		
		self.ipRequest.text = String(ip)
		self.portRequest.text = String(port)
		self.prepForController(self.connectButton)
	}
	
	func readerDidCancel(_ reader: QRCodeReaderViewController) {
		reader.dismiss(animated: true, completion: nil)
		return
	}
	
	
	let welcomeImage = UIImageView()
	
	let ipRequest = ARMTextField()
	let portRequest = ARMTextField()
	
	let connectButton = UIButton()
	
	let qrButton = UIButton()
	let controllerButton = UIButton()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		initUI()
		
		readerVC.delegate = self
		
	}
	
	func initUI() {
		initImages()
		initFields()
		initConnectButton()
		initActions()
	}
	
	func initActions() {
		
		let buttonSize: CGFloat = 50
		let radius: CGFloat = 10
		let padding: CGFloat = 15
		
		view.addSubview(qrButton)
		qrButton.translatesAutoresizingMaskIntoConstraints = false
		qrButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: -radius).isActive = true
		qrButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: radius).isActive = true
		qrButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
		qrButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
		
		qrButton.clipsToBounds = true
		qrButton.layer.cornerRadius = radius
		qrButton.setImage(.qr, for: .normal)
		qrButton.imageEdgeInsets = UIEdgeInsets(top: padding/2, left: padding, bottom: padding, right: padding/2)
		
		view.addSubview(controllerButton)
		controllerButton.translatesAutoresizingMaskIntoConstraints = false
		controllerButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: radius).isActive = true
		controllerButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: radius).isActive = true
		controllerButton.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
		controllerButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
		
		controllerButton.clipsToBounds = true
		controllerButton.layer.cornerRadius = radius
		controllerButton.setImage(.controller, for: .normal)
		controllerButton.imageEdgeInsets = UIEdgeInsets(top: padding/2, left: padding/2, bottom: padding, right: padding)
		
		
		qrButton.addTarget(self, action: #selector(openQRScanner), for: .touchUpInside)
		controllerButton.addTarget(self, action: #selector(showController), for: .touchUpInside)
		
		
		styleButton(qrButton)
		styleButton(controllerButton)
	}
	
	@objc func openQRScanner() {
		self.present(readerVC, animated: true, completion: nil)
	}
	
	@objc func showController() {
		self.performSegue(withIdentifier: "2controller", sender: nil)
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
		styleButton(qrButton)
		styleButton(controllerButton)
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
			if let id = sender as? Int {
				c.playerID = id
			} else {
				c.isSimulator = true
			}
			
		}
	}
	
	
	
}

