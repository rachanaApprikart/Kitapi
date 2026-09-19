//
//  FloatingPanelLayout.swift
//  Kitapi
//
//  Created by Suneel on 13/05/26.
//

import Foundation
import FloatingPanel


class FloatingPanelCustomLayout: FloatingPanelLayout {

    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState

    private let inset: CGFloat

    init(state: FloatingPanelState, inset: CGFloat) {
        self.initialState = state
        self.inset = inset
    }

    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        [
            initialState: FloatingPanelLayoutAnchor(
                fractionalInset: inset,
                edge: .bottom,
                referenceGuide: .safeArea
            )
        ]
    }

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.3
    }
}
