//
//  EventStatusRibbon.swift
//  Kitapi
//
//  Created by Suneel Apprikart on 14/10/26.
//
import UIKit

class EventStatusRibbon: UILabel {
    private let ribbonMask = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .bottomRight], cornerRadii: CGSize(width: 18, height: 18))
        ribbonMask.frame = bounds
        ribbonMask.path = path.cgPath
        layer.mask = ribbonMask
    }
}
