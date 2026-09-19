//
//  SetTimerViewController.swift
//  Kitapi
//
//  Created by Suneel on 05/08/26.
//

import UIKit
import FloatingPanel


class SetTimerViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var hourView: UIView!
    @IBOutlet weak var houeLabel: UILabel!

    @IBOutlet weak var minuteView: UIView!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var minutesPickerView: UIPickerView!
    
    @IBOutlet weak var skipTimerButton: UIButton!

    @IBOutlet weak var setTimerButton: UIButton!
    @IBOutlet weak var orLabel: UILabel!
    
    private let minuteOptions = ["5", "10", "15"]
    private var selectedMinute: String = "5"
    private var floatingPanel: FloatingPanelController?

    var onSkip: (() -> Void)?
    
    static var sbIdentifier: String {
        return String(describing: SetTimerViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setTimerScreenUI()
    }

    @IBAction func setTimerAction(_ sender: UIButton) {
        self.showVerifyMPINPanel()
    }
    
    @IBAction func skipTimerAction(_ sender: UIButton) {
        self.onSkip?()
    }
}

// MARK: - UIPickerViewDataSource & Delegate

extension SetTimerViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.minuteOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.minuteOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedMinute = self.minuteOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int,forComponent component: Int) -> NSAttributedString? {

        return NSAttributedString(string: self.minuteOptions[row],
            attributes: [
                .font: UIFont(name: Fonts.urbanistSemiBold, size: 10) as Any,
                .foregroundColor: UIColor.buttonTitleColor
            ]
        )
    }
}

//5-8

extension SetTimerViewController {
    
    private func setTimerScreenUI() {

        self.minutesPickerView.delegate = self
        self.minutesPickerView.dataSource = self
        
        self.headerLabel.text = APPConstants.setTimerTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.subtitleLabel.text = APPConstants.setTimerSubTitle
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.subtitleLabel.textColor = .labelPlaceholderColor
        self.subtitleLabel.numberOfLines = 2
        
        self.orLabel.textAlignment = .center
        self.orLabel.font = UIFont(name: Fonts.urbanistSemiBold, size: 14)
        self.orLabel.textColor = .buttonTitleColor
        self.orLabel.numberOfLines = 1
        
        self.houeLabel.textColor = .buttonTitleColor
        self.minLabel.textColor = .buttonTitleColor
        
        self.setTimerButton.setTitle(APPConstants.setTimerTitle, for: .normal)
        self.setTimerButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.setTimerButton.setTitleColor(.white, for: .normal)
        self.setTimerButton.backgroundColor = .pinkPrimaryColor
        self.setTimerButton.layer.cornerRadius = 25
        
        self.skipTimerButton.setTitle(APPConstants.skipTimerTitle, for: .normal)
        self.skipTimerButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.skipTimerButton.setTitleColor(UIColor.buttonTitleColor, for: .normal)
        self.skipTimerButton.backgroundColor = .white
        self.skipTimerButton.layer.cornerRadius = 25
        self.skipTimerButton.layer.borderWidth = 1
        self.skipTimerButton.layer.borderColor = UIColor.buttonBorderColor.cgColor
        
        self.hourView.layer.cornerRadius = 12
        self.hourView.backgroundColor = .gradientColor1
        
        self.minuteView.layer.cornerRadius = 12
        self.minuteView.backgroundColor = .gradientColor1
        
    }
    
    private func showVerifyMPINPanel() {
        guard let contentVC = VCManager.openMPINVC() else { return }
        contentVC.mode = .enable
        contentVC.selectedMinute = self.selectedMinute
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.52)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    private func presentFloatingPanel(with contentVC: UIViewController, layout: FloatingPanelLayout) {
        guard floatingPanel == nil else { return }
        
        let fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.set(contentViewController: contentVC)
        
        fpc.surfaceView.appearance.cornerRadius = 25
        fpc.surfaceView.grabberHandle.isHidden = false
        fpc.layout = layout
        fpc.isRemovalInteractionEnabled = true
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        fpc.contentMode = .fitToBounds
        
        self.floatingPanel = fpc
        self.present(fpc, animated: true)
    }
}

extension SetTimerViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}
