//
//  SwiftMessages.swift
//  Kitapi
//
//  Created by Suneel on 16/04/26.
//

import Foundation
import SwiftMessages

final class MessageManager {
    
    static let shared = MessageManager()
    private init() {}
    
    func show(message: String,
              type: Theme = .error,
              duration: SwiftMessages.Duration = .automatic) {
        
        let view = MessageView.viewFromNib(layout: .cardView)
        view.titleLabel?.text = "Kitapi"
        view.bodyLabel?.text = message
        view.button?.isHidden = true
        
        switch type {
        case .success:
            view.configureTheme(.success)
            
        case .error:
            view.configureTheme(.error)
            
        case .warning:
            view.configureTheme(.warning)
            
        case .info:
            view.configureTheme(.info)
        }
        
        view.configureDropShadow()
    //    view.configureContentView(backgroundColor: view.backgroundView.backgroundColor ?? .white)
        
        var config = SwiftMessages.Config()
        config.presentationStyle = .top
        config.duration = duration
        config.presentationContext = .window(windowLevel: .normal)
        config.interactiveHide = true
        
        DispatchQueue.main.async {
            SwiftMessages.show(config: config, view: view)
        }
    }
}
