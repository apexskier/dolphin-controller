//
//  ARMBubbleProgressHud.swift
//  ARMDevSuite
//
//  Created by Ajay Merchia on 3/9/19.
//  Copyright © 2019 Ajay Merchia. All rights reserved.
//

import Foundation
import UIKit

public enum ARMBubbleProgressHudStyle {
    case light
    case dark
}

public enum ARMBubbleProgressHudAnimation {
    case rotating
    case blinking
    case rotateContinuous
}

public enum ARMBubbleProgressHudBubbleStyle {
    case filled
    case border
}

public struct ARMBubbleProgressHudDefaultConfiguration {
    // Overlay Appearance
    public var backgroundAlpha: CGFloat = 0.5
    public var overlayStyle: ARMBubbleProgressHudStyle = .light
    
    // Bubble Appearance
    public var colorPrimary = UIColor.colorWithRGB(rgbValue: 0xEB592E)
    public var colorSecondary = UIColor.colorWithRGB(rgbValue: 0xEA38A7)
    public var colors: [UIColor] {
        return [colorPrimary, colorSecondary]
    }
    
    public var bubbleBorderWidth: CGFloat = 4
    public var bubbleShadowRadius: CGFloat = 10
    public var bubbleShadowOpacity: Float = 0.4
    public var bubbleStyle: ARMBubbleProgressHudBubbleStyle = .filled
    // Bubble Layout
    public var bubbleGap = true
    public var initialDegreeOffset: CGFloat = 100
    public var numBubbles = 7
    
    
    // Text Control
    public var titleFont: UIFont = UIFont(name: "Avenir-Heavy", size: 18)!
    public var detailFont: UIFont = UIFont(name: "Avenir-Book", size: 14)!
    
    // Animation Control
    public var animationStyle: ARMBubbleProgressHudAnimation = .rotateContinuous
    public var animationSpeed: Double = 1
    public var fadeDuration: TimeInterval = 0.75
    public var fadeDelay: TimeInterval = 1.5
    
    public init() {
        
    }
}

@available(iOS 9.0, *)
public class ARMBubbleProgressHud: UIView {
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(for view: UIView) {
        super.init(frame: view.frame)
        parentView = view
        titleLabel.textAlignment = .center
        detailLabel.textAlignment = .center
        resetHUD()
        
        self.addSubview(contentView)
    }
    
    private func resetHUD() {
        createBubbleViews()
        addBubbles()
        formatBubbles()
        positionContentView()
        updateAppearance()
    }
    
    
    /// Defines the way the ProgressHud will appear. Configure this in your AppDelegate.
    public static var defaultStyle: ARMBubbleProgressHudDefaultConfiguration = ARMBubbleProgressHudDefaultConfiguration()
    
    public var bubbleGap: Bool = ARMBubbleProgressHud.defaultStyle.bubbleGap
    public var initialDegreeOffset: CGFloat = ARMBubbleProgressHud.defaultStyle.initialDegreeOffset
    public var numBubbles = ARMBubbleProgressHud.defaultStyle.numBubbles {
        didSet {
            createBubbleViews()
        }
    }
    public var backgroundAlpha: CGFloat = ARMBubbleProgressHud.defaultStyle.backgroundAlpha
    public var bubbleBorderWidth: CGFloat = ARMBubbleProgressHud.defaultStyle.bubbleBorderWidth
    public var bubbleShadowRadius: CGFloat = ARMBubbleProgressHud.defaultStyle.bubbleShadowRadius
    public var bubbleShadowOpacity: Float = ARMBubbleProgressHud.defaultStyle.bubbleShadowOpacity
    
    public var overlayStyle: ARMBubbleProgressHudStyle = ARMBubbleProgressHud.defaultStyle.overlayStyle
    public var animationStyle: ARMBubbleProgressHudAnimation = ARMBubbleProgressHud.defaultStyle.animationStyle
    public var bubbleStyle: ARMBubbleProgressHudBubbleStyle = ARMBubbleProgressHud.defaultStyle.bubbleStyle
    
    public var fadeDuration: TimeInterval = ARMBubbleProgressHud.defaultStyle.fadeDuration
    public var fadeDelay: TimeInterval = ARMBubbleProgressHud.defaultStyle.fadeDelay
    public var animationSpeed: Double = ARMBubbleProgressHud.defaultStyle.animationSpeed
    
    private(set) public var title: String? {
        didSet {
            positionContentView()
        }
    }
    private(set) public var detail: String? {
        didSet {
            positionContentView()
        }
    }
    public var titleFont: UIFont = ARMBubbleProgressHud.defaultStyle.titleFont {
        didSet {
            positionContentView()
        }
    }
    public var detailFont: UIFont = ARMBubbleProgressHud.defaultStyle.detailFont {
        didSet {
            positionContentView()
        }
    }
    public var titleColor: UIColor = ARMBubbleProgressHud.defaultStyle.colorPrimary {
        didSet {
            positionContentView()
        }
    }
    public var detailColor: UIColor = ARMBubbleProgressHud.defaultStyle.colorSecondary {
        didSet {
            positionContentView()
        }
    }
    
    private(set) public var colors: [UIColor] = ARMBubbleProgressHud.defaultStyle.colors
    
    private var parentView: UIView!
    private var indicatorView: UIView!
    private var contentView = UIView()
    private var titleLabel = UILabel(frame: .zero)
    private var detailLabel = UILabel(frame: .zero)
    
    private var bubbles = [UIView]()
    
    private var bubbleCenters = [CGPoint]()
    private var showing = false
    private var animating = false
    private var indicatorDiameter: CGFloat {
        return self.frame.width/4
    }
    private var interruptReposition = false
    
    private static let rotateXKey = "xmove"
    private static let rotateYKey = "ymove"
    private static let scalingKey = "scaling"
    private static let borderScalingKey = "borderScaling"
    private static let shadowKey = "shadow"
    private static let colorKey = "color"
    
    private static let frameworkBundle = Bundle(for: ARMBubbleProgressHud.self)
    private static let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("ProgressHudBundle.bundle")
    private static let resourceBundle = Bundle(url: bundleURL!)
    private static let success = UIImage(named: "check", in: resourceBundle, compatibleWith: nil)!
    private static let failure = UIImage(named: "cancel", in: resourceBundle, compatibleWith: nil)!
    
    
    
    public func set(color: UIColor) {
        self.colors = [color]
    }
    public func set(color1: UIColor, color2: UIColor) {
        self.colors = [color1, color2]
    }
    public func show() {
        updateAppearance()
        
        switch self.animationStyle {
        case .blinking:
            self.blinkAnimation()
        case .rotating:
            self.rotateAnimation()
        case .rotateContinuous:
            indicatorView.rotate(duration: 2 * self.animationSpeed)
        }
        
        self.alpha = 0
        
        parentView.addSubview(self)
        
        UIView.animate(withDuration: self.fadeDuration) {
            self.alpha = 1
        }
        self.showing = true
    }
    public func dismiss(_ complete: @escaping ()->() = {}) {
        UIView.animate(withDuration: self.fadeDuration, animations: {
            self.alpha = 0
        }) { (b) in
            self.removeFromSuperview()
            self.showing = false
            self.resetHUD()
            complete()
        }
        
    }
    
    public func setMessage(title: String?, detail: String?, animated: Bool = true, complete: @escaping (()->()) = {} ) {
        guard animated && showing else {
            self.title = title ?? ""
            self.detail = detail ?? ""
            return
        }
        
        UIView.animate(withDuration: self.fadeDuration/2, animations: {
            self.titleLabel.alpha = 0
            self.detailLabel.alpha = 0
        }) { (_) in
            self.interruptReposition = true
            self.title = title
            self.detail = detail
            self.interruptReposition = false
            UIView.animate(withDuration: self.fadeDuration/2, animations: {
                self.titleLabel.alpha = 1
                self.detailLabel.alpha = 1
            }, completion: { (_) in
                complete()
            })
            
        }
        
        
        
        
    }
    
    @available(iOS 10.0, *)
    public func showResult(success: Bool, title: String?, detail: String?) {
        
        let targetColor = UIColor(zip(colors.first!.rgba, colors.last!.rgba).map(+).map({ (agg) -> CGFloat in
            return agg/2
        }))
        
        self.stopAnimation()
        self.setMessage(title: title, detail: detail, animated: true, complete: {})
        
        let imageSize = self.indicatorDiameter * 0.5
        
        let resultView = UIImageView()
        self.addSubview(resultView)
        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.centerXAnchor.constraint(equalTo: self.indicatorView.centerXAnchor).isActive = true
        resultView.centerYAnchor.constraint(equalTo: self.indicatorView.centerYAnchor).isActive = true
        resultView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
        resultView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
        
        resultView.contentMode = .scaleAspectFit
        resultView.image = (success ? ARMBubbleProgressHud.success : ARMBubbleProgressHud.failure).withRenderingMode(.alwaysTemplate)
        switch self.bubbleStyle {
        case .border:
            resultView.tintColor = targetColor
        case .filled:
            resultView.tintColor = .white
        }
        
        resultView.clipsToBounds = true
        resultView.alpha = 0
        
        UIView.animate(withDuration: self.fadeDuration, animations: {
            resultView.alpha = 1
        }) { (_) in
            
            Timer.scheduledTimer(withTimeInterval: self.fadeDelay, repeats: false, block: { (t) in
                self.dismiss {
                    resultView.removeFromSuperview()
                }
                
            })
            
        }
        
        
        
        
        
    }
    public func stopAnimation() {
        let targetFrame = LayoutManager.inside(inside: indicatorView, justified: .MidCenter, verticalPadding: 0, horizontalPadding: 0, width: indicatorDiameter, height: indicatorDiameter)
        
        let targetColor = UIColor(zip(colors.first!.rgba, colors.last!.rgba).map(+).map({ (agg) -> CGFloat in
            return agg/2
        }))
        
        
        for bubble in bubbles {
            bubble.layer.shadowRadius = 0
            switch bubbleStyle {
            case .filled:
                let coloring: CABasicAnimation = CABasicAnimation(keyPath: "backgroundColor")
                coloring.fromValue = bubble.layer.backgroundColor
                coloring.toValue = targetColor.cgColor
                coloring.duration = self.fadeDuration
                coloring.fillMode = .forwards
                coloring.isRemovedOnCompletion = false
                bubble.layer.removeAnimation(forKey: ARMBubbleProgressHud.colorKey)
                bubble.layer.add(coloring, forKey: ARMBubbleProgressHud.colorKey)
            case .border:
                let coloring: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
                coloring.fromValue = bubble.layer.borderColor
                coloring.toValue = targetColor.cgColor
                coloring.duration = self.fadeDuration
                coloring.fillMode = .forwards
                coloring.isRemovedOnCompletion = false
                bubble.layer.removeAnimation(forKey: ARMBubbleProgressHud.colorKey)
                bubble.layer.add(coloring, forKey: ARMBubbleProgressHud.colorKey)
                
                let widthCorrection: CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
                widthCorrection.fromValue = bubble.layer.borderWidth
                widthCorrection.toValue = bubbleBorderWidth/CGFloat(numBubbles)
                widthCorrection.duration = self.fadeDuration
                widthCorrection.fillMode = .forwards
                widthCorrection.isRemovedOnCompletion = false
                bubble.layer.removeAnimation(forKey: ARMBubbleProgressHud.borderScalingKey)
                bubble.layer.add(widthCorrection, forKey: ARMBubbleProgressHud.borderScalingKey)
            }
            
            let configs = [
                ("position.x", targetFrame.midX, ARMBubbleProgressHud.rotateXKey),
                ("position.y", targetFrame.midY, ARMBubbleProgressHud.rotateYKey)
            ]
            
            let removeShadow: CABasicAnimation = CABasicAnimation(keyPath: "shadowColor")
            removeShadow.fromValue = bubble.layer.shadowColor
            removeShadow.toValue = UIColor.clear.cgColor
            removeShadow.duration = self.fadeDuration
            removeShadow.fillMode = .forwards
            removeShadow.isRemovedOnCompletion = false
            bubble.layer.removeAnimation(forKey: ARMBubbleProgressHud.shadowKey)
            bubble.layer.add(removeShadow, forKey: ARMBubbleProgressHud.shadowKey)
            
            
            for (coord, targetVal, targetKey) in configs {
                let pos = bubble.layer.presentation()?.value(forKeyPath: coord)
                
                let translate : CABasicAnimation = CABasicAnimation(keyPath: coord)
                translate.fromValue = pos
                translate.toValue = targetVal
                translate.duration = self.fadeDuration
                translate.fillMode = .forwards;
                translate.isRemovedOnCompletion = false;
                
                bubble.layer.removeAnimation(forKey: targetKey)
                bubble.layer.add(translate, forKey: targetKey)
            }
            let rescale: CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
            rescale.fromValue = 1
            rescale.toValue = targetFrame.width/bubble.frame.width
            rescale.duration = self.fadeDuration
            rescale.fillMode = .forwards
            rescale.isRemovedOnCompletion = false
            bubble.layer.removeAnimation(forKey: ARMBubbleProgressHud.scalingKey)
            bubble.layer.add(rescale, forKey: ARMBubbleProgressHud.scalingKey)
            
            
        }
        if animationStyle == .rotateContinuous {
            indicatorView.stopRotating()
        }
        
    }
    
    
    private func rotateAnimation() {
        for i in 0..<self.bubbles.count {
            let bubble = self.bubbles[i]
            let xanimation = CAKeyframeAnimation()
            let yanimation = CAKeyframeAnimation()
            
            xanimation.keyPath = "position.x"
            yanimation.keyPath = "position.y"
            
            let numPositions = self.bubbleCenters.count + 1
            
            let positions = (0..<numPositions).map { (j) -> CGPoint in
                return self.bubbleCenters[(i + j) % (numPositions - 1)]
            }
            
            xanimation.values = positions.map({ (point) -> CGFloat in
                return point.x
            })
            yanimation.values = positions.map({ (point) -> CGFloat in
                return point.y
            })
            
            
            let keytimes = (0..<numPositions).map { (val) -> CGFloat in
                
                return CGFloat(val)/CGFloat(numPositions)
            }
            
            xanimation.keyTimes = keytimes as [NSNumber]
            xanimation.duration = 2 * self.animationSpeed
            yanimation.keyTimes = keytimes as [NSNumber]
            yanimation.duration = 2 * self.animationSpeed
            
            
            xanimation.isAdditive = false
            yanimation.isAdditive = false
            
            xanimation.repeatCount = Float.infinity
            yanimation.repeatCount = Float.infinity
            
            xanimation.fillMode = .forwards
            yanimation.fillMode = .forwards
            
            let animationStyle = CAMediaTimingFunction(name: .easeInEaseOut)
            xanimation.timingFunction = animationStyle
            yanimation.timingFunction = animationStyle
            
            bubble.layer.add(xanimation, forKey: ARMBubbleProgressHud.rotateXKey)
            bubble.layer.add(yanimation, forKey: ARMBubbleProgressHud.rotateYKey)
            
        }
        
    }
    private func blinkAnimation() {
        let sizes = self.bubbles.map ({ (bubble) -> CGFloat in return bubble.frame.width })
        var colors = self.bubbles.map ({ (bubble) -> CGColor in return bubble.layer.shadowColor!})
        
        for i in 0..<self.bubbles.count {
            let bubble = self.bubbles[i]
            
            let size = CAKeyframeAnimation()
            let color = CAKeyframeAnimation()
            let shadow = CAKeyframeAnimation()
            let border = CAKeyframeAnimation()
            
            var sizeProportions = sizes.map { (size) -> CGFloat in
                return size/bubble.frame.width
            }
            sizeProportions = sizeProportions + sizeProportions.reversed()
            let keytimes = (0..<sizeProportions.count).map { (val) -> CGFloat in
                
                return CGFloat(val)/CGFloat(sizeProportions.count)
            }
            let sizeValues = (0..<sizeProportions.count).map { (j) -> CGFloat in
                return sizeProportions[(i + j) % (sizeProportions.count)]
            }
            
            size.keyPath = "transform.scale"
            size.values = sizeValues
            size.keyTimes = keytimes as [NSNumber]
            size.duration = 1.5 * self.animationSpeed
            size.repeatCount = Float.infinity
            size.calculationMode = .paced
            size.timingFunction = CAMediaTimingFunction(name: .linear)
            size.fillMode = .both
            bubble.layer.add(size, forKey: ARMBubbleProgressHud.scalingKey)
            
            if self.bubbleStyle == .border {
                border.keyPath = "borderWidth"
                border.values = sizeValues.map({ (scale) -> CGFloat in
                    return 1/scale * self.bubbleBorderWidth
                })
                border.keyTimes = keytimes as [NSNumber]
                border.duration = 1.5 * self.animationSpeed
                border.repeatCount = Float.infinity
                border.calculationMode = .paced
                border.timingFunction = CAMediaTimingFunction(name: .linear)
                border.fillMode = .both
                
                bubble.layer.add(border, forKey: ARMBubbleProgressHud.borderScalingKey)
            }
            
            
            let colorVals = (0..<colors.count).map { (j) -> CGColor in
                return colors[(i + j) % (colors.count)]
            }
            
            
            shadow.keyPath = "shadowColor"
            shadow.values = colorVals + colorVals.reversed()
            shadow.keyTimes = keytimes as [NSNumber]
            shadow.duration = 1 * self.animationSpeed
            shadow.repeatCount = Float.infinity
            shadow.calculationMode = .paced
            shadow.timingFunction = CAMediaTimingFunction(name: .linear)
            shadow.fillMode = .both
            bubble.layer.add(shadow, forKey: ARMBubbleProgressHud.shadowKey)
            
            
            if self.bubbleStyle == .filled {
                color.keyPath = "backgroundColor"
            } else {
                color.keyPath = "borderColor"
                
            }
            
            color.values = colorVals + colorVals.reversed()
            color.keyTimes = keytimes as [NSNumber]
            color.duration = 1.5 * self.animationSpeed
            color.repeatCount = Float.infinity
            color.calculationMode = .paced
            color.timingFunction = CAMediaTimingFunction(name: .linear)
            color.fillMode = .both
            bubble.layer.add(color, forKey: ARMBubbleProgressHud.colorKey)
            
            
            
            
            
            
        }
    }
    private func updateAppearance() {
        switch overlayStyle {
        case .dark:
            self.backgroundColor = UIColor.black.withAlphaComponent(self.backgroundAlpha)
        case .light:
            self.backgroundColor = UIColor.white.withAlphaComponent(self.backgroundAlpha)
        }
        
        addBubbles()
        formatBubbles()
        
        
    }
    private func createBubbleViews() {
        for view in bubbles {
            view.removeFromSuperview()
        }
        bubbles = (0..<numBubbles).map({ (int) -> UIView in
            return UIView()
        })
    }
    private func addBubbles() {
        
        let maxDiameter:CGFloat = indicatorDiameter/2
        let minDiameter:CGFloat = maxDiameter/2.5
        
        if indicatorView == nil {
            indicatorView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: indicatorDiameter + 2 * maxDiameter))
            contentView.addSubview(indicatorView)
            contentView.addSubview(titleLabel)
            contentView.addSubview(detailLabel)
            
            titleLabel.removeConstraints(titleLabel.constraints)
            detailLabel.removeConstraints(detailLabel.constraints)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.topAnchor.constraint(equalTo: indicatorView.bottomAnchor).isActive = true
            titleLabel.centerXAnchor.constraint(equalTo: indicatorView.centerXAnchor).isActive = true
            titleLabel.widthAnchor.constraint(equalToConstant: self.frame.width - 6 * .padding).isActive = true
            
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            detailLabel.centerXAnchor.constraint(equalTo: indicatorView.centerXAnchor).isActive = true
            detailLabel.widthAnchor.constraint(equalToConstant: self.frame.width - 6 * .padding).isActive = true
        }
        
        let numSlots = (bubbleGap ? 1 : 0) + numBubbles
        
        let diameters = (0..<numSlots).map({ (i) -> CGFloat in
            return minDiameter + CGFloat(i) * (maxDiameter - minDiameter)/CGFloat(numSlots)
        })
        
        let onPathInscribedArcs = diameters.map({ (d) -> CGFloat in
            let r = d/2
            let R = indicatorDiameter/2
            return (atan(r/(R*2)) * 2) * 180/CGFloat.pi
        })
        
        let residualDegrees = 360 - onPathInscribedArcs.reduce(0, +)
        let originalDegrees = initialDegreeOffset
        
        self.bubbleCenters = []
        
        for i in 0..<(numSlots) {
            let bubble = i < numBubbles ? bubbles[i] : UIView()
            let bubbleDiameter = diameters[i]
            
            let bubbleX = indicatorView.center.x + indicatorDiameter/2 * cos(initialDegreeOffset * CGFloat.pi/180)
            let bubbleY = indicatorView.center.y + indicatorDiameter/2 * sin(initialDegreeOffset * CGFloat.pi/180)
            bubble.frame = CGRect(x: 0, y: 0, width: bubbleDiameter/2, height: bubbleDiameter/2)
            bubble.center = CGPoint(x: bubbleX, y: bubbleY)
            
            
            bubble.layer.cornerRadius = bubble.frame.width/2
            
            if i < numSlots {
                indicatorView.addSubview(bubble)
                initialDegreeOffset += onPathInscribedArcs[i]
            }
            
            initialDegreeOffset += residualDegrees/CGFloat(numSlots)
            
            
            
            self.bubbleCenters.append(bubble.center)
        }
        
        initialDegreeOffset = originalDegrees
        
        
    }
    private func formatBubbles() {
        guard let c1 = self.colors.first, let c2 = self.colors.last else { return }
        
        let start = c1.rgba
        let end = c2.rgba
        
        let stepsize = (0..<start.count).map { (i) -> CGFloat in
            return (end[i]-start[i])/CGFloat(numBubbles-1)
        }
        
        for i in 0..<numBubbles {
            let bubble = bubbles[i]
            let step = stepsize.map { (val) -> CGFloat in return CGFloat(i) * val}
            let thisColor = UIColor(zip(start, step).map(+))
            bubble.backgroundColor = nil
            
            switch self.bubbleStyle {
            case .filled:
                bubble.layer.backgroundColor = thisColor.cgColor
                bubble.layer.borderWidth = 0
            case .border:
                bubble.layer.backgroundColor = UIColor.clear.cgColor
                bubble.frame = bubble.frame.inset(by: UIEdgeInsets(top: -bubbleBorderWidth/2, left: -bubbleBorderWidth/2, bottom: -bubbleBorderWidth/2, right: -bubbleBorderWidth/2))
                bubble.layer.cornerRadius = bubble.frame.width/2
                bubble.layer.borderWidth = bubbleBorderWidth
                bubble.layer.borderColor = thisColor.cgColor
                
            }
            bubble.layer.shadowColor = thisColor.cgColor
            bubble.layer.shadowRadius = bubbleShadowRadius
            bubble.layer.shadowOpacity = bubbleShadowOpacity
            
            
            
        }
    }
    private func updateLabels () {
        titleLabel.text = title
        detailLabel.text = detail
        
        titleLabel.font = titleFont
        detailLabel.font = detailFont
        titleLabel.textColor = titleColor
        detailLabel.textColor = detailColor
        titleLabel.textAlignment = .center
        detailLabel.textAlignment = .center
        
        detailLabel.numberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping
    }
    private func positionContentView() {
        // Label updates
        updateLabels()
        
        if interruptReposition {
            return
        }
        
        
        
        
        
        titleLabel.sizeToFit()
        titleLabel.frame.size = CGSize(width: self.frame.width, height: max(UISuite.getLineHeight(for: titleFont), titleLabel.frame.height))
        detailLabel.sizeToFit()
        detailLabel.frame.size = CGSize(width: self.frame.width, height: max(UISuite.getLineHeight(for: detailFont), detailLabel.frame.height))
        
        contentView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: indicatorView.frame.height + titleLabel.frame.height + detailLabel.frame.height + 2 * .padding)
        contentView.clipsToBounds = false
        
        titleLabel.frame = LayoutManager.belowCentered(elementAbove: indicatorView, padding: 0, width: self.frame.width - 6 * .padding, height: titleLabel.frame.height)
        detailLabel.frame = LayoutManager.belowCentered(elementAbove: titleLabel, padding: 0, width: self.frame.width - 6 * .padding, height: detailLabel.frame.height)
        
        contentView.center = self.center
        
        
    }
    
}
