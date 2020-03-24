//
//  PreferenceNumericCell.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/10/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import UIKit

struct PreferenceNumericConfig {
	var title: String
	var description: String
	var preference: Preferences.Preference<CGFloat>
	var defaultValue: CGFloat
	var integerOnly: Bool
	
	var min: Float
	var max: Float
}

class PreferenceNumericCell: UITableViewCell {
	static let id = "preference_numeric"
	
	var precisionDigits: Int = 2
	
	var titleLabel: UILabel!
	var detailLabel: UILabel!
	var slider: UISlider!
	var valueLabel: UILabel!
	var defaultResetButton: UIButton!
	
	var config: PreferenceNumericConfig!
	
	
	override func awakeFromNib() {
		config = nil
		self.contentView.subviews.forEach({$0.removeFromSuperview()})
		super.awakeFromNib()
		// Initialization code
		
		valueLabel = UILabel(); contentView.addSubview(valueLabel)
		valueLabel.translatesAutoresizingMaskIntoConstraints = false
		valueLabel.bottomAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
		valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.padding).isActive = true
		valueLabel.font = UIFont.boldSystemFont(ofSize: 20)
		valueLabel.textColor = GCVC.shared.text
		valueLabel.textAlignment = .center
		
		defaultResetButton = UIButton(); contentView.addSubview(defaultResetButton)
		defaultResetButton.translatesAutoresizingMaskIntoConstraints = false
		defaultResetButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -.padding).isActive = true
		defaultResetButton.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: .padding/2).isActive = true
		defaultResetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.padding/2).isActive = true
		defaultResetButton.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2).isActive = true
		defaultResetButton.widthAnchor.constraint(equalTo: valueLabel.widthAnchor).isActive = true
		defaultResetButton.setBackgroundColor(color: GCVC.shared.text, forState: .normal)
		defaultResetButton.setTitleColor(GCVC.shared.stdBkgrnd, for: .normal)
		defaultResetButton.titleLabel?.adjustsFontSizeToFitWidth = true
		defaultResetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
		
		let textContainer = UIView(); contentView.addSubview(textContainer)
		textContainer.translatesAutoresizingMaskIntoConstraints = false
		textContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .padding/2).isActive = true
		textContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .padding).isActive = true
		textContainer.trailingAnchor.constraint(equalTo: defaultResetButton.leadingAnchor, constant: -.padding).isActive = true
		
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
		
		slider = UISlider(); contentView.addSubview(slider)
		slider.translatesAutoresizingMaskIntoConstraints = false
		slider.topAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: .padding/2).isActive = true
		slider.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor).isActive = true
		slider.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor).isActive = true
		slider.minimumTrackTintColor = GCVC.shared.text.withAlphaComponent(0.5)
		slider.thumbTintColor = GCVC.shared.text
		slider.maximumTrackTintColor = .themeGray
		
		slider.addTarget(self, action: #selector(didSlide), for: .valueChanged)
		
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		// Configure the view for the selected state
	}
	
	func str(for val: CGFloat, isInteger: Bool) -> String {
		if config.integerOnly {
			return "\(Int(val))"
		} else {
			return String("\(val)".prefix(2 + self.precisionDigits))
		}
	}
	
	func initializeWith(config: PreferenceNumericConfig) {
		self.config = config
		titleLabel.text = config.title
		detailLabel.text = config.description
		valueLabel.text = str(for: config.preference.val, isInteger: config.integerOnly)
	
		defaultResetButton.setTitle("Restore (\(str(for: config.defaultValue, isInteger: config.integerOnly)))", for: .normal)
		
		slider.maximumValue = config.max
		slider.minimumValue = config.min
		slider.value = Float(config.preference.val)
		
		self.precisionDigits = config.integerOnly ? 0 : 2
		
	}
	
	@objc func didSlide() {
		var newVal = slider.value
		newVal = slider.value * pow(10, Float(self.precisionDigits))
		newVal = roundf(newVal)
		
		let val = Float(newVal)/Float(pow(10, Float(self.precisionDigits)))
		slider.value = val
		config.preference.val = CGFloat(val)
		valueLabel.text = str(for: config.preference.val, isInteger: config.integerOnly)
	}
	@objc func reset() {
		slider.value = Float(config.defaultValue)
		didSlide()
	}
	
}
