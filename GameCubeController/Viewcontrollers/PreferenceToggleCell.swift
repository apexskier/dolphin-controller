//
//  PreferenceToggleCell.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/10/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import UIKit

struct PreferenceToggleConfig {
	var title: String
	var description: String
	var preference: Preferences.Preference<Bool>
}

class PreferenceToggleCell: UITableViewCell {
	static let id = "preference_toggle"
	
	var titleLabel: UILabel!
	var detailLabel: UILabel!
	var toggler: UISwitch!
	
	var config: PreferenceToggleConfig!
	
	
	override func awakeFromNib() {
		config = nil
		self.contentView.subviews.forEach({$0.removeFromSuperview()})
		super.awakeFromNib()
		// Initialization code
		
		toggler = UISwitch(); contentView.addSubview(toggler)
		toggler.center(in: self.contentView, direction: .vertical)
		toggler.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.padding).isActive = true
		toggler.widthAnchor.constraint(equalToConstant: 70).isActive = true
		toggler.addTarget(self, action: #selector(didToggle), for: .valueChanged)
		
		let textContainer = UIView(); contentView.addSubview(textContainer)
		textContainer.translatesAutoresizingMaskIntoConstraints = false
		textContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
		textContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .padding).isActive = true
		textContainer.trailingAnchor.constraint(equalTo: toggler.leadingAnchor, constant: -.padding).isActive = true
		
		
		titleLabel = UILabel(); contentView.addSubview(titleLabel)
		titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
		titleLabel.textColor = GCVC.shared.text
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.topAnchor.constraint(equalTo: textContainer.topAnchor).isActive = true
		titleLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor).isActive = true
		titleLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor).isActive = true
		
		titleLabel.numberOfLines = 0
		titleLabel.lineBreakMode = .byWordWrapping
		
		
		detailLabel = UILabel(); contentView.addSubview(detailLabel)
		detailLabel.textColor = .themeGray
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
		detailLabel.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor).isActive = true
		detailLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor).isActive = true
		detailLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor).isActive = true
		
		detailLabel.numberOfLines = 0
		detailLabel.lineBreakMode = .byWordWrapping
		
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		// Configure the view for the selected state
	}
	
	func initializeWith(config: PreferenceToggleConfig) {
		self.config = config
		titleLabel.text = config.title
		detailLabel.text = config.description
		
		toggler.isOn = config.preference.val
		
	}
	
	@objc func didToggle() {
		
		config.preference.val = toggler.isOn
		print(Preferences.shared.soundOn)
	}
	
}
