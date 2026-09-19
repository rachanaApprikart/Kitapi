//
//  VerifyOTPViewController.swift
//  Kitapi
//
//  Created by Suneel on 06/04/26.
//


import UIKit

class VerifyOTPViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    //07-04
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var otpInputView: OTPInputView!
    @IBOutlet weak var countdownTimerLabel: UILabel!
    @IBOutlet weak var verifyEmailButton: UIButton!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var countdownTimer: Timer?
    private var remainingSeconds = 30
    private let viewModel = VerifyOTPViewModel()
    
    var emailOfTheUser: String = ""
    
    static var sbIdentifier: String {
        return String(describing: VerifyOTPViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setVerifyOTPScreenUI()
        self.startCountdown()
        self.bindViewModel()
        self.sendOtp(userEmail: self.emailOfTheUser)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func verifyOTPAction(_ sender: UIButton) {
        self.verifyOTP()
    }
    
    private func sendOtp(userEmail: String) {
        Task {
            await self.viewModel.submitOTPToUser(email: userEmail)
        }
    }
    
    private func verifyOTP() {
        
        let email = self.emailOfTheUser
        let otp = self.otpInputView.getOTP()
        let version = UIDevice.current.systemVersion
        
        Task {
            await self.viewModel.verifyOTP(email: email, otp: otp, version: version)
        }
    }
    
    //MARK: Countdown
    
    private func startCountdown() {
        remainingSeconds = 10
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        self.remainingSeconds -= 1
        self.updateResendLabel()
        
        if remainingSeconds <= 0 {
            self.countdownTimer?.invalidate()
            self.countdownTimer = nil
        }
    }
    
    
    private func bindViewModel() {
        
        // Bind loading state
        self.viewModel.onLoadingChanged = { [weak self] isApiLoading in
            guard let self = self else { return }
            isApiLoading ? self.showActivityIndicator() : self.hideActivityIndicator()
        }
        
        // Bind API error
        self.viewModel.onOTPError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        // Bind success
        self.viewModel.onSendOTPSuccess = { [weak self] sendOTPResponse in
            MessageManager.shared.show(message: sendOTPResponse.message, type: .success)
        }
        
        //Bind Verification success
        self.viewModel.onVerifyOTPSuccess = { [weak self] verifyOTPSuccess in
            guard let self = self else { return }
            AppUserDefaults.authorizationToken = verifyOTPSuccess.token
            self.retrieveParentDetails()
        }
        
        self.viewModel.onGetVerifiedParentDetailsSuccess = { [weak self] verifiedParent in
            guard let self = self else { return }
            AppUserDefaults.customerDetails = verifiedParent.user
            MessageManager.shared.show(message: verifiedParent.message, type: .success)
            self.navigateToTabBar()
        }
    }
    
    private func retrieveParentDetails() {
        Task {
            await self.viewModel.getVerifiedParentDetails()
        }
    }
    
    fileprivate func navigateToTabBar() {
        guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
              let vc = VCManager.openTabBarVC() else {
            return
        }
        sceneDelegate.window?.rootViewController = vc
    }
    
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        
        let signUpTitleRange =  NSRange(location: 27, length: "Resend".count)
        if gesture.didTapAttributedTextInLabel(label: self.countdownTimerLabel, inRange: signUpTitleRange) {
            self.sendOtp(userEmail: self.emailOfTheUser)
        }
    }
}

//MARK: UI

extension VerifyOTPViewController {
    
    private func setVerifyOTPScreenUI() {
        
        self.appBGView.setGradientBackground()
        
        //7-4-26
        
        self.headerLabel.text = APPConstants.emailVerifuTitle 
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 28)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.subtitleLabel.text = APPConstants.emailVerifySubtitle
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 16)
        self.subtitleLabel.textColor = .labelPlaceholderColor
        self.subtitleLabel.numberOfLines = 2
        
        self.countdownTimerLabel.textAlignment = .center
        self.countdownTimerLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.countdownTimerLabel.numberOfLines = 2
        
        self.backButton.setTitleColor(.headerLabekColor, for: .normal)
        
        self.verifyEmailButton.setTitle(APPConstants.emailVerifyBtnTitle, for: .normal)
        self.verifyEmailButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.verifyEmailButton.setTitleColor(.white, for: .normal)
        self.verifyEmailButton.backgroundColor = .pinkPrimaryColor
        self.verifyEmailButton.layer.cornerRadius = 25
        
        //Keeps button blurred initially
        self.updateVerifyButtonState()
        
        //Keeps button blurred while editing
        self.otpInputView.onOTPComplete = { [weak self] otp in
            self?.updateVerifyButtonState()
        }
        
        //Button loks clear on completing
        self.otpInputView.onOTPChanged = { [weak self] code in
            self?.updateVerifyButtonState()
        }
    }
    
    private func updateVerifyButtonState() {
        let otp = otpInputView.getOTP()
        let isComplete = otp.count == 6
        
        UIView.animate(withDuration: 0.3) {
            self.verifyEmailButton.isEnabled = isComplete
            self.verifyEmailButton.alpha = isComplete ? 1.0 : 0.5
        }
    }
    
    private func updateResendLabel() {
        if remainingSeconds > 0 {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            let timeString = String(format: "%02d:%02d", minutes, seconds)
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(
                string: APPConstants.resendCodeTitle,
                attributes: [.foregroundColor: UIColor.textPlaceholderColor]
            ))
            attributedString.append(NSAttributedString(
                string: timeString,
                attributes: [.foregroundColor: UIColor.pinkPrimaryColor]
            ))
            self.countdownTimerLabel.attributedText = attributedString
            self.countdownTimerLabel.isUserInteractionEnabled = false
        } else {
            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(
                string: APPConstants.dintRecieveCodeTitle,
                attributes: [.foregroundColor: UIColor.textPlaceholderColor]
            ))
            attributedString.append(NSAttributedString(
                string: "Resend",
                attributes: [
                    .foregroundColor: UIColor.pinkPrimaryColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            ))
            self.countdownTimerLabel.attributedText = attributedString
            self.countdownTimerLabel.isUserInteractionEnabled = true
            
            let tapgesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnLabel(_ :)))
            tapgesture.numberOfTapsRequired = 1
            tapgesture.numberOfTouchesRequired = 1
            self.countdownTimerLabel.addGestureRecognizer(tapgesture)
        }
    }
    private func showActivityIndicator() {
        self.activityView.isHidden = false
        self.activityIndicator.startAnimating()
        self.view.bringSubviewToFront(self.activityView)
    }
    
    private func hideActivityIndicator() {
        self.activityView.isHidden = true
        self.view.sendSubviewToBack(self.activityView)
        self.activityIndicator.stopAnimating()
    }

    //09-04
    
    private func openNewPasswordVC() {
        guard let vc = VCManager.openNewPasswordVC() else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
