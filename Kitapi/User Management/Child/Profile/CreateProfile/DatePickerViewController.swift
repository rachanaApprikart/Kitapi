//
//  DatePickerViewController.swift
//  Kitapi
//
//  Created by Suneel on 13/05/26.
//

import UIKit


class DatePickerViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    static var sbIdentifier: String {
        return String(describing: DatePickerViewController.self)
    }
    
    weak var delegate: DatePickerDelegate?
    let formatter = DateFormatter()
    
    let calendar = Calendar.current
    let now = Date()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setDobScreenUI()
        // Do any additional setup after loading the view.
    }
    

    @IBAction func cancelButtonAction(_ sender: Any) {
        self.delegate?.datePickerVCDidDismiss()
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        
        let date = datePicker.date
        
        self.formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)
        
        self.delegate?.didSelectDOB(date: dateString)
        self.delegate?.datePickerVCDidDismiss()
    }
    
    deinit {
        print("FloatingPanelController deallocated")
    }
}

extension DatePickerViewController {
    
    private func setDobScreenUI() {
        
        self.headerLabel.text = APPConstants.dobTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.saveButton.setTitle(APPConstants.saveTitle, for: .normal)
        self.saveButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.saveButton.setTitleColor(.white, for: .normal)
        self.saveButton.backgroundColor = .pinkPrimaryColor
        self.saveButton.layer.cornerRadius = 25
        
        self.cancelButton.setTitle(APPConstants.cancelTitle, for: .normal)
        self.cancelButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.cancelButton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.cancelButton.backgroundColor = .white
        self.cancelButton.layer.cornerRadius = 25
        self.cancelButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.cancelButton.layer.borderWidth = 1
        
        self.datePicker.datePickerMode = .date
       
        self.datePicker.locale = .current
        self.datePicker.timeZone = .current
        
        if #available(iOS 13.4, *) {
            self.datePicker.preferredDatePickerStyle = .wheels
        }
       
        self.datePicker.maximumDate = calendar.date(byAdding: .year, value: -5, to: now)
        self.datePicker.minimumDate = calendar.date(byAdding: .year, value: -18, to: now)

    }
}

protocol DatePickerDelegate: AnyObject {
    func didSelectDOB( date: String)
    func datePickerVCDidDismiss()
}
