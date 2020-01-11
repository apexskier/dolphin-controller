//
//  ControllerViewController.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/10/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//


import UIKit
import ARMDevSuite
import FlexColorPicker

extension UIDevice {
	static func vibrate(intensity: CGFloat) {
		let generator = UIImpactFeedbackGenerator()
		generator.impactOccurred(intensity: intensity)
	}
	static func vibrate(style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
}

protocol GCButtonDelegate {
	func didPressGCButton(_ gcButton: GCButton)
	func didReleaseGCButton(_ gcButton: GCButton)
}

class GCButton: UIButton {
	var dolphinName: String
	var delegate: GCButtonDelegate?
	
	init(name: String, delegate: GCButtonDelegate?) {
		self.dolphinName = name
		self.delegate = delegate
		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false
		
		self.addTarget(self, action: #selector(handleDown), for: .touchDown)
		self.addTarget(self, action: #selector(handleUp), for: .touchUpInside)
		self.addTarget(self, action: #selector(handleUpWarn), for: .touchUpOutside)
		
	}
	
	@objc func handleDown() {
		UIDevice.vibrate(style: .light)
		delegate?.didPressGCButton(self)
	}
	@objc func handleUp() {
		UIDevice.vibrate(style: .heavy)
		delegate?.didReleaseGCButton(self)
	}
	@objc func handleUpWarn() {
		UIDevice.vibrate(style: .heavy)
		delegate?.didReleaseGCButton(self)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setColor(_ c: UIColor) {
		self.setBackgroundColor(color: c, forState: .normal)
		self.setTitleColor(c.modified(withAdditionalHue: 0, additionalSaturation: 0, additionalBrightness: -0.4), for: .normal)
		self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
		self.titleLabel?.adjustsFontSizeToFitWidth = true
	}
}

protocol GCStickDelegate {
	func gcStick(_ gcStick: GCStick, didMoveTo point: CGPoint)
	func didRelease(_ gcStick: GCStick)
}

class GCStick: UIView {
	var dolphinName: String
	var delegate: GCStickDelegate?
	
	var stickIndicator: UIView = UIView()
	
	private var dynamicX: NSLayoutConstraint!
	private var dynamicY: NSLayoutConstraint!
	
	private var centerXDefault: NSLayoutConstraint!
	private var centerYDefault: NSLayoutConstraint!
	
	private var lastOrigin: CGPoint?
	private var originIndicator: UIView = UIView()
	
	private var dynamicXOrigin: NSLayoutConstraint!
	private var dynamicYOrigin: NSLayoutConstraint!
	
	private var cnt: Int = 0
	var broadcastSampling: Int = 3
	
	init(name: String, delegate: GCStickDelegate, size: CGFloat = 60) {
		self.dolphinName = name
		self.delegate = delegate
		super.init(frame: .zero)
		
		self.translatesAutoresizingMaskIntoConstraints = false
		buildIndicator(size: size)
		
		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
				
		
	}
	
	func setStickPosition(p: CGPoint) {
		self.dynamicX.constant = p.x - stickIndicator.frame.width/2
		self.dynamicY.constant = p.y - stickIndicator.frame.height/2
		
		if let lo = lastOrigin {
			self.dynamicXOrigin.constant = lo.x - originIndicator.frame.width/2
			self.dynamicYOrigin.constant = lo.y - originIndicator.frame.height/2
		}
		
		self.layoutSubviews()
		
	}
	
	@objc func panned(_ g: UIPanGestureRecognizer) {
		if g.state == .began {
			UIDevice.vibrate(style: .heavy)
			let curr = g.location(in: self)
			let mv = g.translation(in: self)
			
			lastOrigin = CGPoint(x: curr.x - mv.x, y: curr.y - mv.y)
			
			setCentered(false)
			setStickPosition(p: lastOrigin!)
		} else if g.state == .ended {
			lastOrigin = nil
			setCentered(true)
			self.delegate?.didRelease(self)
			cnt = 0
		} else {
//			setStickPosition(p: g.location(in: self))
			cnt += 1
			if cnt % broadcastSampling == 1 {
				let movement = g.translation(in: self)
				
				let threshold: CGFloat = 0.25
				
				
				let ref = min(self.frame.width, self.frame.height)
				
				var percentX = abs(movement.x)/ref
				var percentY = abs(movement.y)/ref
				
				var pointX = movement.x/(ref/3)
				var pointY = movement.y/(ref/3)
				
				var violated = false
				
				if percentX > threshold {
					pointX = pointX < 0 ? -1 : 1
					percentX = threshold
					violated = true
				}
				
				if percentY > threshold {
					pointY = pointY < 0 ? -1 : 1
					percentY = threshold
					violated = true
				}
				
				if violated && cnt % 5 == 0 {
					UIDevice.vibrate(style: .light)
				}
				
				if let lo = lastOrigin {
					let sX: CGFloat = pointX < 0 ? -1 : 1
					let sY: CGFloat = pointY < 0 ? -1 : 1
					setStickPosition(p: CGPoint(x: lo.x + percentX * sX * ref , y: lo.y + percentY * sY * ref))
				}
				
				
				self.delegate?.gcStick(self, didMoveTo: CGPoint(x: pointX, y: pointY))
			}
		}
	}
	
	func buildIndicator(size: CGFloat) {
		self.addSubview(stickIndicator)
		stickIndicator.translatesAutoresizingMaskIntoConstraints = false
		self.centerXDefault = stickIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor)
		self.centerYDefault = stickIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
		
		self.dynamicX = stickIndicator.leftAnchor.constraint(equalTo: self.leftAnchor)
		self.dynamicY = stickIndicator.topAnchor.constraint(equalTo: self.topAnchor)
		
		let indicatorSize: CGFloat = size
		
		stickIndicator.widthAnchor.constraint(equalToConstant: indicatorSize).isActive = true
		stickIndicator.heightAnchor.constraint(equalToConstant: indicatorSize).isActive = true
		stickIndicator.layer.cornerRadius = indicatorSize/2
		stickIndicator.clipsToBounds = true
		
		let originIndicatorScale: CGFloat = 1.2
		
		self.addSubview(self.originIndicator)
		self.originIndicator.translatesAutoresizingMaskIntoConstraints = false
		self.originIndicator.widthAnchor.constraint(equalToConstant: indicatorSize * originIndicatorScale).isActive = true
		self.originIndicator.heightAnchor.constraint(equalToConstant: indicatorSize * originIndicatorScale).isActive = true
		originIndicator.layer.cornerRadius = indicatorSize * originIndicatorScale/2
		originIndicator.clipsToBounds = true
		
		self.dynamicXOrigin = originIndicator.leftAnchor.constraint(equalTo: self.leftAnchor)
		self.dynamicYOrigin = originIndicator.topAnchor.constraint(equalTo: self.topAnchor)
		
		
		
		
		setCentered(true)
	}
	
	func setCentered(_ b: Bool) {
		self.centerXDefault.isActive = b
		self.centerYDefault.isActive = b
		
		self.dynamicX.isActive = !b
		self.dynamicY.isActive = !b
		
		self.dynamicXOrigin.isActive = !b
		self.dynamicYOrigin.isActive = !b
		
		self.stickIndicator.alpha = b ? 0.6 : 1
		self.originIndicator.alpha = b ? 0 : 0.4
	}
	
	func setColor(_ c: UIColor) {
		stickIndicator.backgroundColor = c
		self.backgroundColor = c.withAlphaComponent(0.3)
		self.addBorder(colored: c, thickness: 0.5)
		self.originIndicator.backgroundColor = c
		self.originIndicator.addBorder(colored: c, thickness: 0.5)
		
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ControllerViewController: GCVC {
	
	// Data
	var playerID: Int!
	
	// System
	
	// UI Components
	var joyStick: GCStick!
	var cStick: GCStick!
	
	var aButton: GCButton!
	var bButton: GCButton!
	var xButton: GCButton!
	var yButton: GCButton!
	
	var sButton: GCButton!
	
	
	var lButton: GCButton!
	var rButton: GCButton!
	var zButton: GCButton!
	
	
	var left: GCButton!
	var right: GCButton!
	var up: GCButton!
	var down: GCButton!
	
	var settings: UIButton!
	var colorController: DefaultColorPickerViewController?
	var backgroundColor: UIColor? {
		didSet {
			guard let bg = self.backgroundColor else {
				self.view.backgroundColor = UIColor.systemBackground
				return
			}
			self.view.backgroundColor = bg
			
		}
	}
	
	
	override func viewDidLayoutSubviews() {
		let circleButtons: [GCButton] = [aButton, bButton, sButton]
		circleButtons.forEach { (b) in
			b.layer.cornerRadius = b.frame.height/2
			b.clipsToBounds = true
		}
		
		let roundedButtons: [GCButton] = [xButton, yButton]
		roundedButtons.forEach { (b) in
			b.layer.cornerRadius = min(b.frame.height, b.frame.width)/2
			b.clipsToBounds = true
		}
		
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if self.playerID == nil { self.playerID = 1 }
		
		// Do any additional setup after loading the view.
		aButton = GCButton(name: "A", delegate: self)
		bButton = GCButton(name: "B", delegate: self)
		xButton = GCButton(name: "X", delegate: self)
		yButton = GCButton(name: "Y", delegate: self)
		sButton = GCButton(name: "START", delegate: self)
		
		lButton = GCButton(name: "L", delegate: self)
		rButton = GCButton(name: "R", delegate: self)
		zButton = GCButton(name: "Z", delegate: self)
		
		left = GCButton(name: "dpadleft", delegate: self)
		right = GCButton(name: "dpadright", delegate: self)
		down = GCButton(name: "dpaddown", delegate: self)
		up = GCButton(name: "dpadup", delegate: self)
		
		joyStick 	= GCStick(name: "MAIN", delegate: self, size: 65)
		cStick 		= GCStick(name: "C", delegate: self, size: 40)
		
		initUI()
		
	}
	
	func initUI() {
		initCenter()
		initButtonArea()
		initSticks()
		initBumpers()
		initDPad()
		initSettings()
	}
	
	func initSettings() {
		settings = UIButton()
		view.addSubview(settings)
		settings.translatesAutoresizingMaskIntoConstraints = false
		settings.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
		settings.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
		settings.heightAnchor.constraint(equalToConstant: 30).isActive = true
		settings.widthAnchor.constraint(equalToConstant: 30).isActive = true
		
		let config = UIImage.SymbolConfiguration(pointSize: 30, weight: UIImage.SymbolWeight.heavy)
		
		settings.imageView?.contentMode = .scaleAspectFit
		settings.setImage(UIImage(systemName: "gear", withConfiguration: config), for: .normal)
		settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
		
	}
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		settings.tintColor = textAccent
	}
	
	
	@objc func openSettings() {
		var configs = [
			ActionConfig(title: "Disconnect", style: .destructive, callback: {
				
				self.alerts.startProgressHud(withTitle: "Disconnecting")
				ControllerAPI.shared.disconnectController(idx: self.playerID) { (err) in
					guard err == nil else {
						self.alerts.triggerHudFailure(withHeader: "Oops", andDetail: err)
						return
					}
					
					self.alerts.dismissHUD()
					self.dismiss(animated: true, completion: nil)
					
				}
			}),
			ActionConfig(title: "Change Controller Color", style: .default, callback: {
				self.colorController = DefaultColorPickerViewController()
				self.colorController?.view.backgroundColor = self.isDark ? .black : .white
				
				self.colorController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissColorPicker))
				let navigationController = UINavigationController(rootViewController: self.colorController!)
				navigationController.modalPresentationStyle = .fullScreen
				self.present(navigationController, animated: true, completion: nil)
				
			})
		]
		
		if self.backgroundColor != nil {
			configs.append(ActionConfig(title: "Clear Controller Color", style: .default) {
				self.backgroundColor = nil
			})
			
		}
		
		self.alerts.showActionSheet(withTitle: "Settings", andDetail: "Player \(self.playerID!)", configs: configs)
	}
	
	@objc func dismissColorPicker() {
		guard let ctrl = self.colorController else { return }
		ctrl.navigationController?.dismiss(animated: true, completion: nil)
		
		self.backgroundColor = ctrl.selectedColor
	}
	
	func initCenter() {
		view.addSubview(sButton)
		sButton.center(in: self.view)
		sButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
		sButton.heightAnchor.constraint(equalTo: sButton.widthAnchor).isActive = true
		sButton.setColor(.gcGray)
		sButton.setTitle("Start", for: .normal)
		
		let indicatorLightSize = CGSize(width: 10, height: 10)
		
		let playerIndicator = UIStackView(); view.addSubview(playerIndicator)
		playerIndicator.translatesAutoresizingMaskIntoConstraints = false
		playerIndicator.axis = .horizontal
		playerIndicator.distribution = .fillEqually
		playerIndicator.alignment = .fill
		
		playerIndicator.centerXAnchor.constraint(equalTo: sButton.centerXAnchor).isActive = true
		playerIndicator.topAnchor.constraint(equalTo: sButton.bottomAnchor, constant: 0.5 * .padding).isActive = true
		playerIndicator.widthAnchor.constraint(equalTo: sButton.widthAnchor, multiplier: 1.1).isActive = true
		playerIndicator.heightAnchor.constraint(equalToConstant: indicatorLightSize.height).isActive = true
		
		for i in (0..<4) {
			let v = UIView(frame: CGRect(origin: .zero, size: indicatorLightSize))
			v.backgroundColor = .gcGray
			if i < self.playerID {
				v.backgroundColor = .LED
			}
			
			playerIndicator.addArrangedSubview(v)
			playerIndicator.setCustomSpacing(5, after: v)
		}
		
		
	}
	
	func initButtonArea() {
		view.addSubview(xButton)
		xButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -.padding * 1.5).isActive = true
		xButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
		xButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.3).isActive = true
		xButton.widthAnchor.constraint(equalTo: xButton.heightAnchor, multiplier: 0.4).isActive = true
		xButton.setColor(.gcGray)
		xButton.setTitle("X", for: .normal)
		
		view.addSubview(aButton)
		aButton.rightAnchor.constraint(equalTo: xButton.leftAnchor, constant: -.padding).isActive = true
		aButton.centerYAnchor.constraint(equalTo: xButton.centerYAnchor, constant: 0 * .padding).isActive = true
		aButton.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.3).isActive = true
		aButton.widthAnchor.constraint(equalTo: aButton.heightAnchor, multiplier: 1).isActive = true
		aButton.setColor(.gcGreen)
		aButton.setTitle("A", for: .normal)
		
		view.addSubview(yButton)
		yButton.bottomAnchor.constraint(equalTo: aButton.topAnchor, constant: -0.5 * .padding).isActive = true
		yButton.widthAnchor.constraint(equalTo: aButton.widthAnchor).isActive = true
		yButton.leftAnchor.constraint(equalTo: aButton.leftAnchor, constant: -1 * .padding).isActive = true
		yButton.heightAnchor.constraint(equalTo: yButton.widthAnchor, multiplier: 0.4).isActive = true
		yButton.setColor(.gcGray)
		yButton.setTitle("Y", for: .normal)
		yButton.transform = CGAffineTransform(rotationAngle: -.pi/12)
		
		view.addSubview(bButton)
		bButton.topAnchor.constraint(equalTo: aButton.bottomAnchor, constant: -.padding).isActive = true
		bButton.rightAnchor.constraint(equalTo: aButton.leftAnchor, constant: -.padding * 0.5).isActive = true
		bButton.widthAnchor.constraint(equalTo: aButton.widthAnchor, multiplier: 0.5).isActive = true
		bButton.widthAnchor.constraint(equalTo: bButton.heightAnchor, multiplier: 1).isActive = true
		bButton.setColor(.gcRed)
		bButton.setTitle("B", for: .normal)
		
	}
	
	func initSticks() {
		view.addSubview(joyStick)
		joyStick.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: .padding * 0.5).isActive = true
		joyStick.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: .padding * 0.5).isActive = true
		joyStick.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.65).isActive = true
		joyStick.rightAnchor.constraint(equalTo: sButton.leftAnchor, constant: -.padding * 2).isActive = true
		joyStick.setColor(.gcGray)
		
		
		view.addSubview(cStick)
		cStick.leftAnchor.constraint(equalTo: bButton.rightAnchor, constant: .padding * 0.5).isActive = true
		cStick.topAnchor.constraint(equalTo: aButton.bottomAnchor, constant: .padding * 0.5).isActive = true
		cStick.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -.padding * 0.5).isActive = true
		cStick.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -.padding * 0.5).isActive = true
		
		cStick.setColor(.gcYellow)
		
		
	}
	
	func initBumpers() {
		view.addSubview(rButton)
		rButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -0.5 * .padding).isActive = true
		rButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.5 * .padding).isActive = true
		rButton.leftAnchor.constraint(equalTo: aButton.centerXAnchor).isActive = true
		rButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
		
		rButton.setColor(.gcGray)
		rButton.setTitle("R", for: .normal)
		
		view.addSubview(lButton)
		lButton.leftAnchor.constraint(equalTo: sButton.rightAnchor, constant: .padding * 0.5).isActive = true
		lButton.topAnchor.constraint(equalTo: rButton.topAnchor).isActive = true
		lButton.widthAnchor.constraint(equalTo: rButton.widthAnchor).isActive = true
		lButton.heightAnchor.constraint(equalTo: rButton.heightAnchor).isActive = true
		
		lButton.setColor(.gcGray)
		lButton.setTitle("L", for: .normal)
		
		view.addSubview(zButton)
		zButton.topAnchor.constraint(equalTo: rButton.bottomAnchor, constant: 0.5 * .padding).isActive = true
		zButton.rightAnchor.constraint(equalTo: rButton.rightAnchor).isActive = true
		zButton.leftAnchor.constraint(equalTo: yButton.rightAnchor).isActive = true
		zButton.heightAnchor.constraint(equalTo: rButton.heightAnchor).isActive = true
		
		zButton.setColor(.gcPurple)
		zButton.setTitle("Z", for: .normal)
	}
	
	
	func initDPad() {
		
		let dPadThick: CGFloat = 30
		let dPadAspect: CGFloat = 1.3
		
		view.addSubview(up)
		up.centerXAnchor.constraint(equalTo: joyStick.centerXAnchor).isActive = true
		up.topAnchor.constraint(equalTo: joyStick.bottomAnchor, constant: .padding * 0.5).isActive = true
		up.widthAnchor.constraint(equalToConstant: dPadThick).isActive = true
		up.heightAnchor.constraint(equalTo: up.widthAnchor, multiplier: dPadAspect).isActive = true
		up.setColor(.gcGray)
		up.setTitle("▲", for: .normal)
		
		
		view.addSubview(left)
		left.rightAnchor.constraint(equalTo: up.leftAnchor).isActive = true
		left.topAnchor.constraint(equalTo: up.bottomAnchor).isActive = true
		left.widthAnchor.constraint(equalTo: up.heightAnchor).isActive = true
		left.heightAnchor.constraint(equalTo: up.widthAnchor).isActive = true
		left.setColor(.gcGray)
		left.setTitle("◄", for: .normal)
		
		view.addSubview(right)
		right.leftAnchor.constraint(equalTo: up.rightAnchor).isActive = true
		right.topAnchor.constraint(equalTo: up.bottomAnchor).isActive = true
		right.widthAnchor.constraint(equalTo: up.heightAnchor).isActive = true
		right.heightAnchor.constraint(equalTo: up.widthAnchor).isActive = true
		right.setColor(.gcGray)
		right.setTitle("►", for: .normal)
		
		view.addSubview(down)
		down.topAnchor.constraint(equalTo: right.bottomAnchor).isActive = true
		down.centerXAnchor.constraint(equalTo: up.centerXAnchor).isActive = true
		down.widthAnchor.constraint(equalTo: up.widthAnchor).isActive = true
		down.heightAnchor.constraint(equalTo: up.heightAnchor).isActive = true
		down.setColor(.gcGray)
		down.setTitle("▼", for: .normal)
		
		up.titleLabel?.adjustsFontSizeToFitWidth = false
		left.titleLabel?.adjustsFontSizeToFitWidth = false
		down.titleLabel?.adjustsFontSizeToFitWidth = false
		right.titleLabel?.adjustsFontSizeToFitWidth = false
		
		
		
	}
	
	
	
}

extension ControllerViewController: GCButtonDelegate {
	func didPressGCButton(_ gcButton: GCButton) {
//		print("Press received for \(gcButton.dolphinName)")
		ControllerAPI.shared.sendCommand(player: self.playerID, action: "PRESS", control: gcButton.dolphinName, value: nil) { (err) in
//			print(err)
		}
	}
	
	func didReleaseGCButton(_ gcButton: GCButton) {
//		print("Release received for \(gcButton.dolphinName)")
		ControllerAPI.shared.sendCommand(player: self.playerID, action: "RELEASE", control: gcButton.dolphinName, value: nil) { (err) in
//			print(err)
		}
	}
	
	
}

extension ControllerViewController: GCStickDelegate {
	func gcStick(_ gcStick: GCStick, didMoveTo point: CGPoint) {
		ControllerAPI.shared.sendCommand(player: self.playerID, action: "SET", control: gcStick.dolphinName, value: "\((point.x + 1)/2) \((-point.y + 1)/2)") { (err) in
//			print("err")
		}
	}
	
	func didRelease(_ gcStick: GCStick) {
		self.gcStick(gcStick, didMoveTo: .zero)
	}
	
	
}
