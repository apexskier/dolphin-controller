//
//  UIAttributeExtensions.swift
//  GameCubeController
//
//  Created by Ajay Merchia on 1/9/20.
//  Copyright © 2020 Mobile Developers of Berkeley. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
	static let logo = UIImage(named: "melee-logo")!
	static let qr = UIImage(named: "qr")!
	static let controller = UIImage(named: "controller")!
	
	static let x = UIImage(named: "x")!
	static let y = UIImage(named: "y")!
}

extension CGFloat {
	static let padding: CGFloat = 20
}

extension UIColor {
	static var gcGray: UIColor = UIColor.colorWithRGB(rgbValue: 0xADADAD)
	static var gcYellow: UIColor = UIColor.colorWithRGB(rgbValue: 0xF9E659)
	static var gcGreen: UIColor = UIColor.colorWithRGB(rgbValue: 0x74D3CF)
	static var gcRed: UIColor = UIColor.colorWithRGB(rgbValue: 0xE23637)
	static var gcPurple: UIColor = UIColor.colorWithRGB(rgbValue: 0x444C95)
	
	static var themeGray: UIColor = UIColor.colorWithRGB(rgbValue: 0xADADAD)
	static var themeYellow: UIColor = UIColor.colorWithRGB(rgbValue: 0xE1D89F)
	static var themeBrown: UIColor = UIColor.colorWithRGB(rgbValue: 0xCD8B76)
	static var themeFuschia: UIColor = UIColor.colorWithRGB(rgbValue: 0xC45BAA)
	static var themeMaroon: UIColor = UIColor.colorWithRGB(rgbValue: 0x7D387D)
	static var themeGreen: UIColor = UIColor.colorWithRGB(rgbValue: 0x008f6d)
	
	static var themeBlueDark: UIColor = UIColor.colorWithRGB(rgbValue: 0x006cd5)
	static var themeBlueMed: UIColor = UIColor.colorWithRGB(rgbValue: 0x2da0da)
	static var themeBlueLight: UIColor = UIColor.colorWithRGB(rgbValue: 0x67ccff)
	
	static var LED: UIColor = UIColor.colorWithRGB(rgbValue: 0x96fff1)
}

extension UIViewController {
	var isDark: Bool {
		return self.traitCollection.userInterfaceStyle == .dark
	}
	var text: UIColor {
		return isDark ? .themeBlueLight : .themeBlueDark
	}
	var textAccent: UIColor {
		return .themeFuschia
	}
	var placeholder: UIColor {
		return .themeGray
	}
	
	var stdBkgrnd: UIColor {
		return isDark ? .black : .white
	}
	
}
