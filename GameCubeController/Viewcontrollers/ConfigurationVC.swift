//
//  ConfigurationVC.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/10/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import UIKit
import ARMDevSuite

class ConfigurationVC: GCVC {
	
	var table: UITableView!
	var onComplete: BlankClosure?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		initUI()
	}
	
	func initUI() {
		self.title = "Configure Controller"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(close))
		
		table = UITableView(); view.addSubview(table)
		table.translatesAutoresizingMaskIntoConstraints = false
		table.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
		table.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor).isActive = true
		table.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor).isActive = true
		table.heightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.heightAnchor).isActive = true
		
		table.dataSource = self
		table.delegate = self
		table.allowsSelection = false
		
		table.register(PreferenceToggleCell.self, forCellReuseIdentifier: PreferenceToggleCell.id)
		table.register(PreferenceNumericCell.self, forCellReuseIdentifier: PreferenceNumericCell.id)
	}
	
	@objc func close() {
		self.onComplete?()
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
}

extension ConfigurationVC: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 {
			return 60
		} else {
			return 100
		}
		
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let container = UIView()
		container.backgroundColor = self.text
		
		
		let label = UILabel(); container.addSubview(label)
		label.center(in: container, direction: .vertical)
		label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: .padding).isActive = true
		
		label.textColor = self.stdBkgrnd
		label.text = self.tableView(tableView, titleForHeaderInSection: section)
		label.font = UIFont.boldSystemFont(ofSize: 18)
		
		return container
		
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Input Feedback"
		case 1:
			return "Controller Behavior"
		default:
			return nil
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 2
		case 1:
			return 3
		default:
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: PreferenceToggleCell.id) as! PreferenceToggleCell
			cell.awakeFromNib()
			var config: PreferenceToggleConfig!
			switch indexPath.row {
			case 0:
				config = PreferenceToggleConfig(title: "Haptic Feedback", description: "Vibrate when buttons are pressed", preference: Preferences.shared.hapticFeedback)
			case 1:
				config = PreferenceToggleConfig(title: "Sound", description: "Play sound effect when buttons are pressed", preference: Preferences.shared.soundOn)
			default:
				return UITableViewCell()
			}
			
			cell.initializeWith(config: config)
			return cell
		} else if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: PreferenceNumericCell.id) as! PreferenceNumericCell
			cell.awakeFromNib()
			var config: PreferenceNumericConfig!
			switch indexPath.row {
			case 0:
				config = PreferenceNumericConfig(
					title: "Stick Sensitivity",
					description: "Lower sensitivities have lower thresholds for flicks",
					preference: Preferences.shared.sensitivity,
					defaultValue: 0.34,
					integerOnly: false,
					min: 0.05,
					max: 0.5
				)
			case 1:
				config = PreferenceNumericConfig(
					title: "Stick Lag",
					description: "More stick lag reduces the likelihood of lost inputs",
					preference: Preferences.shared.stickBroadcastFrequency,
					defaultValue: 7,
					integerOnly: true,
					min: 1,
					max: 10
				)
			case 2:
				config = PreferenceNumericConfig(
					title: "B Button Size",
					description: "Larger Size increases the area occupied by the B Button",
					preference: Preferences.shared.bButtonScale,
					defaultValue: 2.24,
					integerOnly: false,
					min: 0.5,
					max: 3
				)
			default:
				return UITableViewCell()
			}
			
			cell.initializeWith(config: config)
			return cell
		}
		return UITableViewCell()
	}
	
	
}
