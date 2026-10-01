//
//  UIView extension.swift
//  Kitapi
//
//  Created by Suneel on 30/03/26.
//

import Foundation
import UIKit

extension UIView {
    
    
     func setGradientBackground() {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.gradientColor1.cgColor,UIColor.gradientColor2.cgColor, UIColor.gradientColor3.cgColor]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        self.layer.addSublayer(gradientLayer)
    }
    
    func setGradientBackgroundForHeader() {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.pinkPrimaryColor.cgColor, UIColor(red: 255/255.0, green: 204/255.0, blue: 129/255.0, alpha: 1).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.layer.addSublayer(gradientLayer)
    }
   
    func createDashedCircle(
        center: CGPoint,
        radius: CGFloat,
        color: UIColor,
        strokeLength: NSNumber,
        gapLength: NSNumber,
        lineWidth: CGFloat
    ) {
        let shapeLayer = CAShapeLayer()

        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineDashPattern = [strokeLength, gapLength]
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [4, 5]
        
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )

        shapeLayer.path = circularPath.cgPath
        layer.addSublayer(shapeLayer)
    }
    func removeDashedCircle() {
        layer.sublayers?
            .filter { $0.name == "DashedCircleLayer" }
            .forEach { $0.removeFromSuperlayer() }
    }
}
