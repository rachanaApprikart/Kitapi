//
//  CreateChoreViewController.swift
//  Kitapi
//
//  Created by Suneel on 10/06/26.
//

import UIKit
import FloatingPanel


class CreateChoreViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var activityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var choreTextField: CustomTextField!
    @IBOutlet weak var choreDescpTextField: CustomTextField!
    @IBOutlet weak var fromTimeTextField: CustomTextField!
    @IBOutlet weak var toTimeTextField: CustomTextField!
    @IBOutlet weak var oftenTitleLabel: UILabel!
    
    @IBOutlet weak var frequencySegmentedControl: UISegmentedControl!
    @IBOutlet weak var frequencyCV: UICollectionView!
    
    @IBOutlet weak var createChoreButton: UIButton!
    
    private var floatingPanel: FloatingPanelController?
    
    private var choreTemplate: TemplateData?
    private var fromTime: ChoreTime!
    private var toTime:   ChoreTime!
    private var weekDays: [WeekDay] = []
    private var recurrenceType: RepeatType = .once 
    private var recurrenceDates: [Date] = []
    
    private let viewModel = CreateChoreViewModel()
    
    weak var delegate: ChoreUpdateDelegate?

    static var sbIdentifier: String {
        return String(describing: CreateChoreViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setCreateChoreScreenUI()
        // 1. Set fromTime to now
        self.fromTime = ChoreTime.fromDate(Date())
        
        // 2. Set toTime exactly 15 mins after fromTime
        //    (NOT from a second Date() call)
        self.toTime = self.fromTime.adding(minutes: 15)
        self.updateTimers()
        self.bindViewModel()
    }
    
    @IBAction func changeRecurranceAction(_ sender: UISegmentedControl) {
        self.recurrenceDates.removeAll()
        self.recurrenceType = RepeatType(rawValue: sender.selectedSegmentIndex) ?? .once

        switch self.recurrenceType {
            case .weekly:
                self.generateCurrentWeek()
            case .daily:
                self.recurrenceDates = [Calendar.current.startOfDay(for: Date())]
            default:
                break
            }
        print(self.recurrenceDates)
        self.frequencyCV.reloadData()
    }
    
    @IBAction func createChoreAction(_ sender: UIButton) {
        self.clearAllErrors()
        self.view.endEditing(true)
        
        self.viewModel.choreTemplateId = self.choreTemplate?.id ?? ""
        self.viewModel.choreDescription = self.choreDescpTextField.customTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        self.viewModel.childId = ChildManager.shared.selectedChild?.id ?? ""
        self.viewModel.startTime = self.fromTime.displayTextIn24HourFormat
        self.viewModel.endTime = self.toTime.displayTextIn24HourFormat
        self.viewModel.recurrence = self.recurrenceType.recurrence.rawValue
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        
        self.viewModel.recurrenceDates = self.recurrenceDates.map {
            formatter.string(from: $0)
        }
        
        Task {
            await self.viewModel.register()
        }
    }
    
    private func bindViewModel() {
        
        self.viewModel.onValidationError = { [weak self] error in
            guard let self = self else { return }
            
            self.clearAllErrors()
            
            switch error.field {
                
            case .choreTitle:
                self.choreTextField.showError(message: error.message)
                
            case .choreDescription:
                self.choreDescpTextField.showError(message: error.message)
           
            default:
                break
            }
        }
        
        // Bind loading state
        self.viewModel.onLoadingChanged = { [weak self] isLoding in
            guard let self = self else { return }
            isLoding ? self.showActivityIndicator() : self.hideActivityIndicator()
        
            self.createChoreButton.isEnabled = !isLoding
            self.createChoreButton.alpha = isLoding ? 0.6 : 1.0
        }
        
        self.viewModel.onCreateChoreError = { [weak self] errorMessage in
            MessageManager.shared.show(message: errorMessage)
        }
        
        self.viewModel.onCreateChoreSuccess = { [weak self] chore in
            guard let self = self else { return }
            MessageManager.shared.show(message: chore.message, type: .success)
            self.delegate?.choreUpdatedSuccessfully()
        }
    }
    
    private func updateTimers() {
        self.fromTimeTextField.customTextField.text = self.fromTime.displayTextIn12HourFormat
        self.toTimeTextField.customTextField.text = self.toTime.displayTextIn12HourFormat
    }
    
   
    
    private func generateCurrentWeek() {
        
        self.weekDays.removeAll()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        print("today-------------", today)
        
        // Sunday of current week
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return
        }
       
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE"
        
        for index in 0..<7 {
            
            guard let date = calendar.date(byAdding: .day, value: index, to: startOfWeek) else {
                continue
            }
            let isEnabled = calendar.compare(date, to: today, toGranularity: .day) != .orderedAscending
            
            self.weekDays.append(
                WeekDay(
                    name: formatter.string(from: date), date: date,
                    isSelected: false, isEnabled: isEnabled
                )
            )
        }
    }
}
    

//MARK: -- PROTOCOLS AND DELEGATES ---

extension CreateChoreViewController: RecordVoiceNoteDelegate, TimePickerDelegate, CalendarVCDelegate {
    
    func calendarVCDidDismiss() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
    }
    
    func didSelectDates(_ date: [Date]) {
        self.recurrenceDates = date
        print(self.recurrenceDates)
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
        self.frequencyCV.reloadData()
    }
    
    func timePickerScreenDidDismiss() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
    }
    
    func timePickerDidSave(_ time: ChoreTime, context: TimePickerContext) {
        switch context {
            
        case .fromTime:
            self.fromTime = time
            self.toTime = time.adding(minutes: 15)
            
        case .toTime:
            self.toTime = time
        }
        self.updateTimers()
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
    }
    
    func recordVoiceScreenDidDismiss() {
        self.floatingPanel?.dismiss(animated: true)
        self.floatingPanel = nil
    }
}

//MARK: --- collection view delegates

extension CreateChoreViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch self.recurrenceType {
            
        case .once, .monthly:
            
            if self.recurrenceDates.isEmpty {
                return 1
            } else {
                return self.recurrenceDates.count + 1
            }
            
        case .daily:
            return 1
            
        case .weekly:
            return self.weekDays.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch self.recurrenceType {
        
        case .once, .monthly:
            
            if self.recurrenceDates.isEmpty {
                
                guard let selectDateCell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectDateCVCell.reUseIdentifier, for: indexPath) as? SelectDateCVCell else { return UICollectionViewCell() }
                
                selectDateCell.onSelectDateAction = {
                    self.openCalendar(for: self.recurrenceType)
                }
                return selectDateCell
                
            } else {
                // Edit button is the last cell
                if indexPath.item == self.recurrenceDates.count {
                    
                    guard let editDateCell = collectionView.dequeueReusableCell(withReuseIdentifier: EditDatesCVCell.reUseIdentifier, for: indexPath) as? EditDatesCVCell else { return UICollectionViewCell() }
                    
                    editDateCell.onEditDateAction = { [weak self] in
                        guard let self else { return }
                        self.openCalendar(for: self.recurrenceType)
                    }
                    return editDateCell
                } else {
                    // Date cell
                    guard let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: DaysCVCell.reUseIdentifier, for: indexPath) as? DaysCVCell else { return UICollectionViewCell() }
                    
                    let date = self.recurrenceDates[indexPath.item]
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMM"
                    let day = formatter.string(from: date)
                    
                    dayCell.configure(title: day, isSelected: false, isEnabled: true)
                    return dayCell
                }
            }
            
        case .daily:
            
            guard let infoCell = collectionView.dequeueReusableCell(withReuseIdentifier: ChoreTemplateCVCell.reUseIdentifier, for: indexPath) as? ChoreTemplateCVCell else { return UICollectionViewCell() }
            infoCell.populateDailyRecurranceCell()
            return infoCell
            
            
        case .weekly:
            
            guard let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: DaysCVCell.reUseIdentifier, for: indexPath) as? DaysCVCell else { return UICollectionViewCell() }
            
            let item = weekDays[indexPath.item]
            dayCell.configure(with: item)
            return dayCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        switch self.recurrenceType {
            
        case .once, .daily, .monthly:
            break
            
        case .weekly:
            
            guard self.weekDays[indexPath.item].isEnabled else { return }
            self.weekDays[indexPath.item].isSelected.toggle()

            self.recurrenceDates = self.weekDays.filter { $0.isSelected }.map {$0.date}
            collectionView.reloadItems(at: [indexPath])
            print(self.recurrenceDates)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch self.recurrenceType {

           case .weekly:

               let spacing: CGFloat = 3
               let totalSpacing = spacing * 6
               let width = (collectionView.frame.width - totalSpacing) / 7

               return CGSize(width: width, height: 50)
            
        case .once, .monthly:
            
            if self.recurrenceDates.isEmpty {
                return CGSize(width: collectionView.frame.width-30, height: 50)

            } else {
                if indexPath.item == self.recurrenceDates.count {
                    
                    return CGSize(width: 25, height: 50)

                } else {
                    return CGSize(width: 70, height: 50)
                }
            }
           default:
                return CGSize(width: collectionView.frame.width-30, height: 50)
           }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch self.recurrenceType {
            
        case .weekly:
            return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            
        default:
            return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        }
       
    }
    
    private func openCalendar(for repeatType: RepeatType) {

        guard let calendarVC = VCManager.openCalenderVC() else {
            return
        }
        calendarVC.repeatType = repeatType
        calendarVC.selectedDates = recurrenceDates
        calendarVC.delegate = self

        let layout = FloatingPanelCustomLayout(state: .full, inset: 0.75)
        self.presentFloatingPanel(with: calendarVC, layout: layout)
    }
}

//MARK: ------------- UI
extension CreateChoreViewController {
        
    private func setCreateChoreScreenUI() {
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.createChoreTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.createChoreButton.setTitle(APPConstants.createChoreTitle, for: .normal)
        self.createChoreButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.createChoreButton.setTitleColor(.white, for: .normal)
        self.createChoreButton.backgroundColor = .pinkPrimaryColor
        self.createChoreButton.layer.cornerRadius = 25
        
        self.oftenTitleLabel.textAlignment = .left
        self.oftenTitleLabel.font = UIFont(name: Fonts.urbanistRegular, size: 14)
        self.oftenTitleLabel.textColor = .labelPlaceholderColor
        self.oftenTitleLabel.numberOfLines = 1
        
        self.choreTextField.customTextField.delegate = self
        self.choreTextField.customTextField.setPlaceholder(text: APPConstants.chorePlaceholder)
        self.choreTextField.placeHolderLabel.text = APPConstants.choreTitle
        self.choreTextField.customTextField.tag = 0
        self.choreTextField.showRightView()
        
        self.choreDescpTextField.customTextField.delegate = self
        self.choreDescpTextField.customTextField.setPlaceholder(text: APPConstants.choreDescpPlaceholder)
        self.choreDescpTextField.placeHolderLabel.text = APPConstants.choreDescpTitle
        self.choreDescpTextField.customTextField.tag = 1
        self.choreDescpTextField.showRightMicView()
        
        self.fromTimeTextField.customTextField.delegate = self
        self.fromTimeTextField.customTextField.setPlaceholder(text: APPConstants.timePlaceholder)
        self.fromTimeTextField.placeHolderLabel.text = APPConstants.timeTitle
        self.fromTimeTextField.showLeftView()
        
        self.toTimeTextField.customTextField.delegate = self
        self.toTimeTextField.customTextField.setPlaceholder(text: APPConstants.timePlaceholder)
        self.toTimeTextField.showLeftView()
        
        self.choreDescpTextField.dropDownBtn.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        
        self.recurrenceType = .once
        self.frequencySegmentedControl.backgroundColor = .white
        self.frequencySegmentedControl.setTitle(RepeatType.once.title, forSegmentAt: 0)
        self.frequencySegmentedControl.setTitle(RepeatType.daily.title, forSegmentAt: 1)
        self.frequencySegmentedControl.setTitle(RepeatType.weekly.title, forSegmentAt: 2)
        self.frequencySegmentedControl.setTitle(RepeatType.monthly.title, forSegmentAt: 3)
        self.frequencySegmentedControl.selectedSegmentIndex = RepeatType.once.rawValue
        self.frequencySegmentedControl.selectedSegmentTintColor = .black
        
        self.frequencySegmentedControl.layer.borderWidth = 1
        self.frequencySegmentedControl.layer.borderColor = UIColor.borderColor.cgColor
        self.frequencySegmentedControl.layer.cornerRadius = 15
        
        self.frequencySegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.textPlaceholderColor, NSAttributedString.Key.font: UIFont(name: Fonts.urbanistRegular, size: 16)!], for: .normal)
        
        self.frequencySegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: Fonts.urbanistBold, size: 16)!], for: .selected)
        
        [self.choreTextField.customTextField, self.choreDescpTextField.customTextField].forEach { textField in
            textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        
        let fromTimeTap = UITapGestureRecognizer(target: self, action: #selector(setFromTime))
        self.fromTimeTextField.customTextField.addGestureRecognizer(fromTimeTap)
        self.fromTimeTextField.customTextField.isUserInteractionEnabled = true
        
        let toTimeTap = UITapGestureRecognizer(target: self, action: #selector(setToTime))
        self.toTimeTextField.customTextField.addGestureRecognizer(toTimeTap)
        self.toTimeTextField.customTextField.isUserInteractionEnabled = true
        
        let choreTap = UITapGestureRecognizer(target: self, action: #selector(searchChore))
        self.choreTextField.customTextField.addGestureRecognizer(choreTap)
        self.choreTextField.customTextField.isUserInteractionEnabled = true
        
        self.frequencyCV.delegate = self
        self.frequencyCV.dataSource = self
        self.frequencyCV.register(ChoreTemplateCVCell.nibFile, forCellWithReuseIdentifier: ChoreTemplateCVCell.reUseIdentifier)
        self.frequencyCV.register(SelectDateCVCell.nibFile, forCellWithReuseIdentifier: SelectDateCVCell.reUseIdentifier)
        self.frequencyCV.register(EditDatesCVCell.nibFile, forCellWithReuseIdentifier: EditDatesCVCell.reUseIdentifier)
        self.frequencyCV.register(DaysCVCell.nibFile, forCellWithReuseIdentifier: DaysCVCell.reUseIdentifier)
        self.frequencyCV.showsHorizontalScrollIndicator = false
    }
    
    @objc func searchChore() {
        self.view.endEditing(true)
        
        guard let contentVC = VCManager.openChoreTemplateVC() else { return }
        contentVC.onTemplateSelected = { [weak self] cTemplate in
            guard let self = self else { return }
            self.choreTemplate = cTemplate
            self.choreTextField.customTextField.text = cTemplate.title
            self.floatingPanel?.dismiss(animated: true)
            self.floatingPanel = nil
            self.choreTextField.hideErrorMessage()
        }
        let layout = FloatingPanelCustomLayout(state: .full, inset: 1.0)
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    @objc private func micTapped() {
        guard let contentVC = VCManager.openRecordVoiceNoteVC() else { return }
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.5)
        contentVC.delegate = self
        self.presentFloatingPanel(with: contentVC, layout: layout)
    }
    
    @objc func setFromTime() {
        self.view.endEditing(true)
        self.openTimePicker(selectedTime: fromTime, minimumTime: nil, context: .fromTime)
    }
    
    @objc func setToTime() {
        self.view.endEditing(true)
        self.openTimePicker(selectedTime: toTime, minimumTime: fromTime.adding(minutes: 15), context: .toTime)
    }
    
    private func openTimePicker(selectedTime: ChoreTime, minimumTime: ChoreTime?, context: TimePickerContext) {
        guard let timerVC = VCManager.openTimePickerVC() else { return }
        let layout = FloatingPanelCustomLayout(state: .half, inset: 0.5)
        timerVC.initialTime  = selectedTime
        timerVC.minimumTime  = minimumTime
        timerVC.delegate = self
        timerVC.context = context
        self.presentFloatingPanel(with: timerVC, layout: layout)
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
    
        self.floatingPanel = fpc
        self.present(fpc, animated: true)
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
    

    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        switch textField.tag {
          case 0:
            self.choreTextField.hideErrorMessage()
              
          case 1:
            self.choreDescpTextField.hideError()
        
          default:
              break
          }
    }
    
    private func clearAllErrors() {
        self.choreTextField.hideErrorMessage()
        self.choreDescpTextField.hideError()
    }
}

extension CreateChoreViewController: FloatingPanelControllerDelegate {
    
    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
    func floatingPanelDidDismiss(_ fpc: FloatingPanelController) {
        self.floatingPanel = nil
    }
}

enum RepeatType: Int {
    case once = 0
    case daily
    case weekly
    case monthly
    
    var title: String {
        switch self {
        case .once:
            return "Once"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
    
    var recurrence: Recurrence {
        switch self {
        case .once: return .once
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }
}

struct WeekDay {
    let name: String
    let date: Date
    var isSelected: Bool
    var isEnabled: Bool
}

protocol ChoreUpdateDelegate: AnyObject {
    func choreUpdatedSuccessfully()
}

extension CreateChoreViewController: UITextFieldDelegate {
    
}
