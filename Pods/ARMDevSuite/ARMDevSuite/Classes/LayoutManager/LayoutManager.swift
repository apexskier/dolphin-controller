//
//  LayoutManager.swift
//
//  Created by Ajay Raj Merchia on 10/10/18.
//  Copyright © 2018 Ajay Raj Merchia. All rights reserved.
//

import Foundation
import UIKit

// Constraint Manager
public extension UIView {
    func pinTo(_ other: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: other.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: other.centerYAnchor).isActive = true
        self.widthAnchor.constraint(equalTo: other.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: other.heightAnchor).isActive = true
        
    }
    
    enum CenteringDirection {
        case both
        case vertical
        case horizontal
    }
    
    func center(in other: UIView, direction: CenteringDirection = .both) {
        self.translatesAutoresizingMaskIntoConstraints = false
        if direction == .both || direction == .horizontal  {
            self.centerXAnchor.constraint(equalTo: other.centerXAnchor).isActive = true
        }
        if direction == .both || direction == .vertical  {
            self.centerYAnchor.constraint(equalTo: other.centerYAnchor).isActive = true
        }
        
    }
}







public class LayoutManager {
    // Below
    
    /// Returns a CGRect that is below ELEMENTABOVE with PADDING between them, horizontally aligned to the left side of that view with WIDTH & HEIGHT
    public static func belowLeft(elementAbove: UIView, padding: CGFloat, width:CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementAbove.frame.minX, y: elementAbove.frame.maxY + padding, width: width, height: height)
    }
    /// Returns a CGRect that is below ELEMENTABOVE with PADDING between them, horizontally aligned center with that view with WIDTH & HEIGHT
    public static func belowCentered(elementAbove: UIView, padding: CGFloat, width:CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementAbove.frame.midX - width/2, y: elementAbove.frame.maxY + padding, width: width, height: height)
    }
    /// Returns a CGRect that is below ELEMENTABOVE with PADDING between them, horizontally aligned to the right side of that view with WIDTH & HEIGHT
    public static func belowRight(elementAbove: UIView, padding: CGFloat, width:CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementAbove.frame.maxX - width, y: elementAbove.frame.maxY + padding, width: width, height: height)
    }
    
    // Above
    /// Returns a CGRect that is above ELEMENTBELOW with PADDING between them, horizontally aligned to the left side of that view with WIDTH & HEIGHT
    public static func aboveLeft(elementBelow: UIView, padding: CGFloat, width:CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementBelow.frame.minX, y: elementBelow.frame.minY - (padding+height), width: width, height: height)
    }
    /// Returns a CGRect that is above ELEMENTBELOW with PADDING between them, horizontally aligned center with that view with WIDTH & HEIGHT
    public static func aboveCentered(elementBelow: UIView, padding: CGFloat, width:CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementBelow.frame.midX - width/2, y: elementBelow.frame.minY - (padding+height), width: width, height: height)
    }
    /// Returns a CGRect that is above ELEMENTBELOW with PADDING between them, horizontally aligned to the right side of that view with WIDTH & HEIGHT
    public static func aboveRight(elementBelow: UIView, padding: CGFloat, width:CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementBelow.frame.maxX - width, y: elementBelow.frame.minY - (padding+height), width: width, height: height)
    }
    
    // Right
    /// Returns a CGRect that is right of ELEMENTLEFT with PADDING between them, vertically aligned to the top of that view with WIDTH & HEIGHT
    public static func toRightTop(elementLeft: UIView, padding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementLeft.frame.maxX + padding, y: elementLeft.frame.minY, width: width, height: height)
    }
    /// Returns a CGRect that is right of ELEMENTLEFT with PADDING between them, vertically aligned center with that view with WIDTH & HEIGHT
    public static func toRightMiddle(elementLeft: UIView, padding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementLeft.frame.maxX + padding, y: elementLeft.frame.midY - height/2, width: width, height: height)
    }
    /// Returns a CGRect that is right of ELEMENTLEFT with PADDING between them, vertically aligned to the bottom of that view with WIDTH & HEIGHT
    public static func toRightBottom(elementLeft: UIView, padding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementLeft.frame.maxX + padding, y: elementLeft.frame.maxY - height, width: width, height: height)
    }
    
    // Left
    /// Returns a CGRect that is left of ELEMENTRIGHT with PADDING between them, vertically aligned to the top of that view with WIDTH & HEIGHT
    public static func toLeftTop(elementRight: UIView, padding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementRight.frame.minX - (padding + width), y: elementRight.frame.minY, width: width, height: height)
    }
    /// Returns a CGRect that is left of ELEMENTRIGHT with PADDING between them, vertically aligned center with that view with WIDTH & HEIGHT
    public static func toLeftMiddle(elementRight: UIView, padding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementRight.frame.minX - (padding + width), y: elementRight.frame.midY - height/2, width: width, height: height)
    }
    /// Returns a CGRect that is left of ELEMENTRIGHT with PADDING between them, vertically aligned to the bottom of that view with WIDTH & HEIGHT
    public static func toLeftBottom(elementRight: UIView, padding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: elementRight.frame.minX - (padding + width), y: elementRight.frame.maxY - height, width: width, height: height)
    }
    
    /// Returns a CGRect that is vertically between ELEMENTABOVE & ELEMENTBELOW (with TOPPADDING & BOTTOMPADDING between them respectively).
    public static func between(elementAbove: UIView, elementBelow: UIView, width:CGFloat, topPadding: CGFloat, bottomPadding: CGFloat) -> CGRect {
        return CGRect(x: elementAbove.frame.midX - width/2, y: elementAbove.frame.maxY + topPadding, width: width, height: elementBelow.frame.minY - (elementAbove.frame.maxY + topPadding + bottomPadding))
    }
    /// Returns a CGRect that is horizontally between ELEMENTLEFT & ELEMENTRIGHT (with LEFTPADDING & RIGHTPADDING between them respectively).
    public static func between(elementLeft: UIView, elementRight: UIView, height: CGFloat, leftPadding: CGFloat, rightPadding: CGFloat) -> CGRect {
        return CGRect(x: elementLeft.frame.maxX + leftPadding, y: elementLeft.frame.midY - height/2, width: elementRight.frame.minX - (elementLeft.frame.maxX + leftPadding + rightPadding), height: height)
    }
    
    public enum InternalJustification {
        case TopLeft
        case TopCenter
        case TopRight
        case MidLeft
        case MidCenter
        case MidRight
        case BottomLeft
        case BottomCenter
        case BottomRight
    }
    
    /// Returns a CGRect that is inside the given view justified and padded accordingly.
    ///
    /// - Parameters:
    ///   - view: enclosing view for the new CGRect
    ///   - justified: vertical and horizontal justification based on 9 point system
    ///   - verticalPadding: vertical padding relative to the bounds of the enclosing view. Not applicable for MID types.
    ///   - horizontalPadding: horizontal padding relative to the boudns of the enclosing view. Not applicable for CENTER types.
    ///   - width: widht of the new CGRect
    ///   - height: height of the new CGRect
    /// - Returns: CGRect that satisfies constraints of the parameters
    public static func inside(inside view: UIView, justified: InternalJustification, verticalPadding: CGFloat, horizontalPadding: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        
        switch justified {
        case .TopLeft:
            return CGRect(x: view.frame.minX + horizontalPadding, y: view.frame.minY + verticalPadding, width: width, height: height)
        case .TopCenter:
            return CGRect(x: view.frame.midX - (width/2), y: view.frame.minY + verticalPadding, width: width, height: height)
        case .TopRight:
            return CGRect(x: view.frame.maxX - (width + horizontalPadding), y: view.frame.minY + verticalPadding, width: width, height: height)
        case .MidLeft:
            return CGRect(x: view.frame.minX + horizontalPadding, y: view.frame.midY - (height/2), width: width, height: height)
        case .MidCenter:
            return CGRect(x: view.frame.midX - (width/2), y: view.frame.midY - (height/2), width: width, height: height)
        case .MidRight:
            return CGRect(x: view.frame.maxX - (width + horizontalPadding), y: view.frame.midY - (height/2), width: width, height: height)
        case .BottomLeft:
            return CGRect(x: view.frame.minX + horizontalPadding, y: view.frame.maxY - (height + verticalPadding), width: width, height: height)
        case .BottomCenter:
            return CGRect(x: view.frame.midX - (width/2), y: view.frame.maxY - (height + verticalPadding), width: width, height: height)
        case .BottomRight:
            return CGRect(x: view.frame.maxX - (width + horizontalPadding), y: view.frame.maxY - (height + verticalPadding), width: width, height: height)
        }
        
        
        
    }
    
    
    
    
}
