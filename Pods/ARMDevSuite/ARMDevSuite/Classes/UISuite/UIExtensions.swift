//
//  UIExtensions.swift
//  ARMDevSuite
//
//  Created by Ajay Merchia on 2/7/19.
//

import Foundation
import UIKit

public extension UIImage {
    func resizeTo(_ sizeChange:CGSize) -> UIImage {
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: .zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}

public extension UIButton {
    
    /// Sets the background color of the button for a UIControl.State
    ///
    /// - Parameters:
    ///   - color: background color
    ///   - forState: state for which the color should show
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
    
    /// Sets the background gradient of the button for a UIControl.State, can not be used with backgroundColor or backgroundImagee
    ///
    /// - Parameters:
    ///   - gradient: Colors that compose this gradient
    ///   - direction: direction in which the gradient should flow
    ///   - forState: state for which this gradient should show
    ///   - reverseDirection: Reverse the direction of the gradient
    func setBackgroundGradient(gradient: Gradient, in direction: GradientOrientation, forState: UIControl.State, reverseDirection: Bool = false) {
        
        var colors: [UIColor]! = [gradient.color1, gradient.color2]
        if reverseDirection {
            colors.reverse()
        }
        
        
        let resolution: CGFloat = 20
        let contextSize = CGSize(width: resolution, height: resolution)
        let contextFrame = CGRect(origin: .zero, size: contextSize)
        
        UIGraphicsBeginImageContext(contextSize)
        UIGraphicsGetCurrentContext()!.fill(contextFrame)
        let gradLayer = CAGradientLayer()
        gradLayer.frame = contextFrame
        gradLayer.colors = colors.map { $0.cgColor }
        gradLayer.startPoint = direction.startPoint
        gradLayer.endPoint = direction.endPoint
        gradLayer.type = .axial
        gradLayer.setNeedsDisplay()
        gradLayer.render(in: UIGraphicsGetCurrentContext()!)
        
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(gradientImage, for: forState)
    }
}

public extension UIColor {
    /// Access the rgba values of this color
    var rgba: [CGFloat] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return [red, green, blue, alpha]
    }
    
    
    /// Initialize a color from an array of rgba
    ///
    /// - Parameter rgba: rgba values on scale of 0 to 1
    convenience init(_ rgba: [CGFloat]) {
        self.init(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
    }
    
    /// Gets a random color
    ///
    /// - Returns: random color
    static func randomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    /// Creates a color from a UInt as a hexvalue with the given alpha.
    ///
    /// - Parameters:
    ///   - rgbValue: color given as hexvalue
    ///   - alpha: alpha of the new color
    /// - Returns: new color
    class func colorWithRGB(rgbValue : UInt, alpha : CGFloat = 1.0) -> UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255
        let green = CGFloat((rgbValue & 0xFF00) >> 8) / 255
        let blue = CGFloat(rgbValue & 0xFF) / 255
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    
    /// Modulates the current UIColor and returns a new instance with modified values.
    ///
    /// - Parameters:
    ///   - hue: additional hue to provide
    ///   - additionalSaturation: additional saturation to provide
    ///   - additionalBrightness: additional brightness to provide
    /// - Returns: new Color
    func modified(withAdditionalHue hue: CGFloat, additionalSaturation: CGFloat, additionalBrightness: CGFloat) -> UIColor {
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrigthness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0
        
        if self.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentAlpha){
            return UIColor(hue: currentHue + hue,
                           saturation: currentSaturation + additionalSaturation,
                           brightness: currentBrigthness + additionalBrightness,
                           alpha: currentAlpha)
        } else {
            return self
        }
    }
    
    /// Converts this `UIColor` instance to a 1x1 `UIImage` instance and returns it.
    ///
    /// - Returns: `self` as a 1x1 `UIImage`.
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

/// A Simple class to assist with UI Color theme
public class rgba: UIColor {
    
    /// Creates a new UIColor using rgba values on a scale of 0 to 255
    ///
    /// - Parameters:
    ///   - r: red on a scale from 0 to 255
    ///   - g: green on a scale from 0 to 255
    ///   - b: blue on a scale from 0 to 255
    ///   - a: alpha coeffiecient from 0 to 1
    /// - Returns: UIColor with the given rgba attributes
    public convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) {
        self.init(red: r/255.00, green: g/255.00, blue: b/255.00, alpha: a)
    }
}
public class rgb: UIColor {
    
    /// Creates a new UIColor using rgb values on a scale of 0 to 255
    ///
    /// - Parameters:
    ///   - r: red on a scale from 0 to 255
    ///   - g: green on a scale from 0 to 255
    ///   - b: blue on a scale from 0 to 255
    public convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        self.init(red: r/255.00, green: g/255.00, blue: b/255.00, alpha: 1)
    }
}


public extension NSMutableAttributedString {
    
    /// Sets the color of a substring within an NSMutableAttributedString
    ///
    /// - Parameters:
    ///   - color: color to set the substring to
    ///   - stringValue: substring to change
    func setColor(color: UIColor, forText stringValue: String) {
        let range: NSRange = self.mutableString.range(of: stringValue, options: .caseInsensitive)
        self.addAttribute(.foregroundColor, value: color, range: range)
    }
    
}

public extension UILabel {
    
    /// Sets a UILabel's text and colorizes a part of it.
    ///
    /// - Parameters:
    ///   - text: new text for the label
    ///   - color: color for the substring
    ///   - substring: substring to colorize
    func setText(to text: String, with color: UIColor, for substring: String) {
        let attString = NSMutableAttributedString(string: text)
        attString.setColor(color: color, forText: substring)
        
        self.attributedText = attString
    }
}

public extension UIView {
    
    /// Shakes the UIView given the parameters
    ///
    /// - Parameters:
    ///   - count: number of movements
    ///   - duration: duration of the shaking animation
    ///   - translation: how much the uiview should move when shaking
    func shake(count : Float = 1, duration : TimeInterval = 0.125, withTranslation translation : Float = 7.5) {
        
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = count
        animation.duration = duration/TimeInterval(animation.repeatCount)
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: CGFloat(-translation), y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: CGFloat(translation), y: self.center.y))
        layer.add(animation, forKey: "shake")
        
        
    }
    
    @available(iOS 9.0, *)
    func border(with color: UIColor, thickness: CGFloat, on side: CGRectEdge, outside: Bool = true) {
        let border = UIView()
        
        if outside {
            guard let parent = self.superview else {
                fatalError("Can't add a border outside a view if parent superview doesn't exist")
            }
            parent.addSubview(border)
        } else {
            self.addSubview(border)
        }
        
        border.translatesAutoresizingMaskIntoConstraints = false
        border.backgroundColor = color
        
        switch side {
        case .minYEdge:
            border.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            if outside {
                border.bottomAnchor.constraint(equalTo: self.topAnchor).isActive = true
            } else {
                border.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            }
            border.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            border.heightAnchor.constraint(equalToConstant: thickness).isActive = true
        case .minXEdge:
            if outside {
                border.trailingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            } else {
                border.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            }
            border.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            border.widthAnchor.constraint(equalToConstant: thickness).isActive = true
            border.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        case .maxYEdge:
            border.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            if outside {
                border.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            } else {
                border.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            }
            border.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            border.heightAnchor.constraint(equalToConstant: thickness).isActive = true
        case .maxXEdge:
            if outside {
                border.leadingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            } else {
                border.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            }
            border.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            border.widthAnchor.constraint(equalToConstant: thickness).isActive = true
            border.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        }
    }
    
    private static let kRotationAnimationKey = "rotationanimationkey"
    
    func rotate(duration: Double = 1) {
        if layer.animation(forKey: UIView.kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float.pi * 2.0
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity
            
            layer.add(rotationAnimation, forKey: UIView.kRotationAnimationKey)
        }
    }
    
    func stopRotating() {
        if layer.animation(forKey: UIView.kRotationAnimationKey) != nil {
            layer.removeAnimation(forKey: UIView.kRotationAnimationKey)
        }
    }
    
    
}




extension CGFloat {
    static let padding: CGFloat = 20
    static let marginalPadding: CGFloat = 5
}



// Gradients
public class Gradient {
    public static var layerName = "kGradientLayer"
    
    var color1: UIColor!
    var color2: UIColor!
    
    public init(_ c1: UIColor, _ c2: UIColor) {
        self.color1 = c1
        self.color2 = c2
    }
    
    var colors: [UIColor] {
        return [color1, color2]
    }
    
}

typealias GradientPoints = (startPoint: CGPoint, endPoint: CGPoint)
public enum GradientOrientation {
    case topRightBottomLeft
    case topLeftBottomRight
    case horizontal
    case vertical
    
    var startPoint : CGPoint {
        return points.startPoint
    }
    
    var endPoint : CGPoint {
        return points.endPoint
    }
    
    var points : GradientPoints {
        switch self {
        case .topRightBottomLeft:
            return (CGPoint(x: 0.0,y: 1.0), CGPoint(x: 1.0,y: 0.0))
        case .topLeftBottomRight:
            return (CGPoint(x: 0.0,y: 0.0), CGPoint(x: 1,y: 1))
        case .horizontal:
            return (CGPoint(x: 0.0,y: 0.5), CGPoint(x: 1.0,y: 0.5))
        case .vertical:
            return (CGPoint(x: 0.0,y: 0.0), CGPoint(x: 0.0,y: 1.0))
        }
    }
}

public extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

public extension UIView {
    func applyGradient(with colors: [UIColor], locations: [NSNumber]? = nil) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func applyGradient(with colors: [UIColor], gradient orientation: GradientOrientation) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = orientation.startPoint
        gradient.endPoint = orientation.endPoint
        self.layer.insertSublayer(gradient, at: 0)
    }
    
    func addBorder(gradient: Gradient, in direction: GradientOrientation, thickness: CGFloat, reverse: Bool = false,  name: String = Gradient.layerName) {
        let grad = CAGradientLayer()
        grad.frame =  CGRect(origin: .zero, size: self.frame.size)
        grad.colors = gradient.colors.map { $0.cgColor }
        grad.startPoint = direction.startPoint
        grad.endPoint = direction.endPoint
        
        let shape = CAShapeLayer()
        shape.lineWidth = thickness
        shape.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        grad.mask = shape
        grad.name = name
        
        self.layer.addSublayer(grad)
    }
    
    
    /// DEPRECATED -- DO NOT USE
    func addFill(gradient: Gradient, in direction: GradientOrientation, reverse: Bool = false) {
        var colors: [UIColor]! = [gradient.color1, gradient.color2]
        if reverse {
            colors.reverse()
        }
        self.applyGradient(with: colors, gradient: direction)
    }
    
    func addBorder(colored color: UIColor, thickness: CGFloat) {
        self.layer.borderWidth = thickness
        self.layer.borderColor = color.cgColor
    }
}

