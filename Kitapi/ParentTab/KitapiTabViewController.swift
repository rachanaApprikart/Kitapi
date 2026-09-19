//
//  KitapiTabViewController.swift
//  Kitapi
//
//  Created by Suneel on 30/04/26.
//

import UIKit

class KitapiTabViewController: UITabBarController {
    
    static var sbIdentifier: String {
        return String(describing: KitapiTabViewController.self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.tintColor = .pinkPrimaryColor
        self.tabBar.backgroundColor = .white
        
    }
}
