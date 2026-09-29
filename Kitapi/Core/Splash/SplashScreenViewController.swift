//
//  ViewController.swift
//  Kitapi
//
//  Created by Suneel on 21/12/25.
//  Modified on 28-3-2026

import UIKit

class SplashScreenViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    
    
    static var sbIdentifier: String {
        return String(describing: SplashScreenViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setSplashScreenUI()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
                  let vc = self.setUpRootVC() else {
                return
            }
            let navVC = UINavigationController(rootViewController: vc)
            navVC.setNavigationBarHidden(true, animated: true)
            sceneDelegate.window?.rootViewController = navVC
        }

    }

    private func setUpRootVC() -> UIViewController? {

        guard
            let onBoardingVC = VCManager.openOnboardingScreenVC(),
            let loginVC = VCManager.openLoginVC(),
            let parentTabBarVC = VCManager.openTabBarVC(),
            let childTabBarVC = VCManager.openChildTabBarVC()
        else {
            return nil
        }

        guard AppUserDefaults.IS_ON_BOARDING_SCREEN_VIEWED else {
            return onBoardingVC
        }

        guard
            AppUserDefaults.authorizationToken != nil,
            AppUserDefaults.customerDetails != nil
        else {
            return loginVC
        }

        let childSessionManager = ChildSessionManager.shared

        if ChildManager.shared.isChildMode ||
            childSessionManager.hasChildModeSession {

            print(
                "ChildManager.shared.isChildMode:",
                ChildManager.shared.isChildMode
            )

            print(
                "ChildSessionManager.shared.hasChildModeSession:",
                childSessionManager.hasChildModeSession
            )

            print(
                "ChildSessionManager.shared.isChildModeExpired:",
                childSessionManager.isChildModeExpired
            )

            return childTabBarVC
        }

        return parentTabBarVC
    }
    
    deinit {
        LogFile.debugMessage(debug: "Splash screen invalidated")
    }
    
//    ChildManager.shared.isChildMode → tells you whether the app is currently in Child Mode.
//    ChildSessionManager.shared.isChildModeExpired → tells you whether the Child Mode session has expired and therefore requires parent MPIN.
}

//MARK: ---------- ui --------

extension SplashScreenViewController {
    
    private func setSplashScreenUI() {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.milkyWhiteColor.cgColor, UIColor.yellowPrimaryColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        
        self.appBGView.layer.addSublayer(gradientLayer)
    }
}
//
//ChildManager.isChildMode
//        ↓
//     maybe false
//
//ChildSessionManager.hasChildModeSession
//        ↓
//       true
//        ↓
//ChildTabBarVC
//        ↓
//isChildModeExpired == true
//        ↓
//Re-auth MPIN
