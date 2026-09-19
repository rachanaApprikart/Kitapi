//
//  TimePickerViewController.swift
//  Kitapi
//
//  Created by Suneel on 16/06/26.
// 17-06 Complete time logic

import UIKit
import FloatingPanel

class TimePickerViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!

    @IBOutlet weak var hourPickerView: UIPickerView!
    @IBOutlet weak var hourLabel: UILabel!
    
    @IBOutlet weak var timePickerCardView: UIView!
    @IBOutlet weak var minutePickerView: UIPickerView!
    @IBOutlet weak var minuteLabel: UILabel!
    
    @IBOutlet weak var amPmView: UIStackView!
    @IBOutlet weak var amButton: UIButton!
    @IBOutlet weak var pmButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    static var sbIdentifier: String {
        return String(describing: TimePickerViewController.self)
    }
    weak var delegate: TimePickerDelegate?
    var context: TimePickerContext = .fromTime
    
    private let hours   = Array(1...12)
    private let minutes = Array(0...59)
    
    //Config (set by parent before presenting)
    var initialTime: ChoreTime?           // what time to show in picker
    var minimumTime: ChoreTime?           // nil = no restriction or min 15 mins for ToTime
    
    //Internal State
    private var selectedHour   = 1
    private var selectedMinute = 0
    private var isAMSelected: Bool = true { didSet {
        self.updateAppearance()
    }}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setTimerScreenUI()
        self.loadInitialTime()
    }

    @IBAction func cancelAction(_ sender: UIButton) {
        self.delegate?.timePickerScreenDidDismiss()
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        
        var selected = ChoreTime(hour12: selectedHour, minute: selectedMinute, isAM: self.isAMSelected)
        
        // Safety net: snap to minimum if still below
        if let minimum = minimumTime,
           selected.totalMinutes < minimum.totalMinutes {
            selected = minimum
        }
        // Send time back to parent
        self.delegate?.timePickerDidSave(selected, context: context)
    }
    
    @IBAction func pmAction(_ sender: UIButton) {
        self.isAMSelected = false
    }
    
    @IBAction func amAction(_ sender: UIButton) {
        self.isAMSelected = true
    }
    
    // Load Initial Time into Pickers
    private func loadInitialTime() {
        guard let time = initialTime else { return }
        
        // Sync state
        self.selectedHour   = time.hour12
        self.selectedMinute = time.minute
        self.isAMSelected = time.isAM
        
        // Scroll pickers to correct position
        // hour12 is 1–12, array index is 0–11, so row = hour12 - 1
        self.hourPickerView.selectRow(time.hour12 - 1, inComponent: 0, animated: false)
        self.minutePickerView.selectRow(time.minute, inComponent: 0, animated: false)
        
        // Sync AM/PM toggle
        self.isAMSelected = time.isAM
    }
}

//MARK: ----- PICKER VIEW DELEGATES

extension TimePickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView.tag == 0 ? hours.count : minutes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: Fonts.urbanistMedium, size: 20)
        label.textColor = .textColor
        label.backgroundColor = .clear  // picker itself is beige, row is clear
        
        if pickerView.tag == 0 {
            label.text = String(format: "%02d", hours[row])
        } else {
            label.text = String(format: "%02d", minutes[row])
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Update state
        if pickerView.tag == 0 { selectedHour   = hours[row]   }
        if pickerView.tag == 1 { selectedMinute = minutes[row] }
    }
}

extension TimePickerViewController {
    
    private func setTimerScreenUI() {
        self.appBGView.setGradientBackground()
        self.updateAppearance()
        
        self.headerLabel.text = APPConstants.timeTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.timePickerCardView.layer.cornerRadius = 10
        self.timePickerCardView.layer.borderColor = UIColor.borderColor.cgColor
        self.timePickerCardView.layer.borderWidth = 0.5
        
        self.hourPickerView.backgroundColor = .gradientColor1
        self.hourPickerView.layer.cornerRadius = 15
        self.hourPickerView.tag = 0
        
        self.minutePickerView.backgroundColor = .gradientColor1
        self.minutePickerView.layer.cornerRadius = 15
        self.minutePickerView.tag = 1
        
        self.hourLabel.text = "Hour"
        self.hourLabel.textAlignment = .left
        self.hourLabel.font = UIFont(name: Fonts.urbanistMedium, size: 14)
        self.headerLabel.textColor = .labelPlaceholderColor
        self.headerLabel.numberOfLines = 1
        
        self.minuteLabel.text = "Minute"
        self.minuteLabel.textAlignment = .left
        self.minuteLabel.font = UIFont(name: Fonts.urbanistMedium, size: 14)
        self.minuteLabel.textColor = .labelPlaceholderColor
        self.minuteLabel.numberOfLines = 1
        
        self.cancelButton.setTitle(APPConstants.cancelTitle, for: .normal)
        self.cancelButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.cancelButton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.cancelButton.backgroundColor = .white
        self.cancelButton.layer.cornerRadius = 25
        self.cancelButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.cancelButton.layer.borderWidth = 1
        
        self.saveButton.setTitle(APPConstants.saveTitle, for: .normal)
        self.saveButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.saveButton.setTitleColor(.white, for: .normal)
        self.saveButton.backgroundColor = .pinkPrimaryColor
        self.saveButton.layer.cornerRadius = 25
        
        self.amPmView.layer.cornerRadius = 5
        self.amPmView.layer.borderWidth = 0.5
        self.amPmView.layer.borderColor = UIColor.labelPlaceholderColor.cgColor
        
        self.amButton.layer.cornerRadius = 5
        self.amButton.layer.borderWidth = 0.5
        self.amButton.layer.borderColor = UIColor.labelPlaceholderColor.cgColor
        
        self.pmButton.layer.cornerRadius = 5
        self.pmButton.layer.borderWidth = 0.5
        self.pmButton.layer.borderColor = UIColor.labelPlaceholderColor.cgColor
        
        self.amButton.titleLabel?.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.pmButton.titleLabel?.font = UIFont(name: Fonts.urbanistMedium, size: 16)
        self.setupPickers()
    }
    
    private func setupPickers() {
        [self.hourPickerView, self.minutePickerView].forEach { picker in
            guard let picker else { return }

            picker.delegate   = self
            picker.dataSource = self
        }
    }
    
    private func updateAppearance() {
        self.amButton.backgroundColor = isAMSelected  ? .labelPlaceholderColor : .white
        self.pmButton.backgroundColor = !isAMSelected ? .labelPlaceholderColor : .white
        self.amButton.setTitleColor(isAMSelected ? .white : .labelPlaceholderColor, for: .normal)
        self.pmButton.setTitleColor(!isAMSelected ? .white : .labelPlaceholderColor, for: .normal)
    }
}

protocol TimePickerDelegate: AnyObject {
    func timePickerScreenDidDismiss()
    func timePickerDidSave(_ time: ChoreTime, context: TimePickerContext)
}

enum TimePickerContext {
    case fromTime
    case toTime
}


// MARK: - Validate Against Minimum
//private func validateAgainstMinimum() {
//    guard let minimum = minimumTime else {
//        // No minimum set (fromTime picker)
//        // Always valid, no warning needed
//        saveButton.alpha      = 1.0
//        warningLabel.isHidden = true
//        return
//    }
//
//    let current = ChoreTime(
//        hour12: selectedHour,
//        minute: selectedMinute,
//        isAM:   isAM
//    )
//
//    let isBelowMinimum = current.totalMinutes < minimum.totalMinutes
//
//    // Dim save + show warning if below minimum
//    saveButton.alpha      = isBelowMinimum ? 0.4 : 1.0
//    warningLabel.isHidden = !isBelowMinimum
//    warningLabel.text     = "Must be at least 15 mins after start time"
//}
 


