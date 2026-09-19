//
//  CalenderViewController.swift
//  Kitapi
//
//  Created by Suneel on 11/07/26.
// 13-07

import UIKit

class CalenderViewController: UIViewController {

    @IBOutlet weak var appBGView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var previousMonthButton: UIButton!
    @IBOutlet weak var nextMonthButton: UIButton!
    
    @IBOutlet weak var sunLabel: UILabel!
    @IBOutlet weak var monLabel: UILabel!
    @IBOutlet weak var tuesLabel: UILabel!
    @IBOutlet weak var wednesLabel: UILabel!
    @IBOutlet weak var thursLabel: UILabel!
    @IBOutlet weak var friLabel: UILabel!
    @IBOutlet weak var satLabel: UILabel!
    
    @IBOutlet weak var datesCV: UICollectionView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    private let calendar = Calendar.current

    private var calendarMonths: [CalendarMonth] = []
    private var currentMonthIndex = 0 //integer that tracks which month is currently visible in the calendar.
    var selectedDates: [Date] = []
    
    var repeatType: RepeatType = .once
    weak var delegate: CalendarVCDelegate?
    
    static var sbIdentifier: String {
        return String(describing: CalenderViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setCalenderScreenUI()
        self.generateCalendarMonths()
        self.updateCalendarUI()
        self.markSelectedDates()
    }
    
    @IBAction func previousMonthAction(_ sender: UIButton) {
        guard currentMonthIndex > 0 else { return }
        self.currentMonthIndex -= 1
        self.updateCalendarUI()
    }
    
    @IBAction func nextMonthAction(_ sender: UIButton) {
        guard currentMonthIndex < calendarMonths.count - 1 else { return }
        self.currentMonthIndex += 1
        self.updateCalendarUI()
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.delegate?.calendarVCDidDismiss()
    }

    @IBAction func saveAction(_ sender: UIButton) {
        self.delegate?.didSelectDates(selectedDates)
    }
    
    private func markSelectedDates() {

        guard !self.selectedDates.isEmpty else { return }

        for monthIndex in self.calendarMonths.indices {

            for dayIndex in self.calendarMonths[monthIndex].days.indices {

                guard let date = self.calendarMonths[monthIndex].days[dayIndex].date else {
                    continue
                }

                if self.selectedDates.contains(where: {
                    Calendar.current.isDate($0, inSameDayAs: date)
                }) {
                    self.calendarMonths[monthIndex].days[dayIndex].isSelected = true
                }
            }
        }
    }
    
    private func generateCalendarMonths() {
        
        self.calendarMonths.removeAll()
        let today = calendar.startOfDay(for: Date()) //2026-07-12 18:30:00 +0000
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        
        for index in 0..<18 {
            
            guard let monthDate = calendar.date(byAdding: .month, value: index, to: today) else {
                continue
            }
            //monthDate------------- 2026-07-12 18:30:00 +0000
            //monthDate------------- 2026-08-12 18:30:00 +0000
            //monthDate------------- 2026-09-12 18:30:00 +0000
            
            let month = CalendarMonth(monthDate: monthDate, monthName: monthFormatter.string(from: monthDate), days: generateDays(for: monthDate)
            )
            self.calendarMonths.append(month)
        }
    }
    private func generateDays(for monthDate: Date) -> [CalendarDay] {

        var days: [CalendarDay] = []
        let today = self.calendar.startOfDay(for: Date())

        guard
            let monthInterval = self.calendar.dateInterval(of: .month, for: monthDate),
            let firstWeekday = self.calendar.dateComponents([.weekday], from: monthInterval.start).weekday,
            let numberOfDays = self.calendar.range(of: .day, in: .month, for: monthDate)?.count else {
            return days
        }
        // monthInterval.start = 2026-07-01 00:00:00
        // monthInterval.end   = 2026-08-01 00:00:00
        
        // July 1 2026 is a Wednesday
        // firstWeekday = 4  (Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7)
        
        // July has 31 days
        // numberOfDays = 31
        
        // Empty cells before first day
        let emptyCells = firstWeekday - 1
        // = 4 - 1 = 3
        
        for _ in 0..<emptyCells { days.append(
                CalendarDay(date: nil, day: nil, isSelected: false, isEnabled: false)
            )
        }
     //SUN    MON    TUE    WED    THU    FRI    SAT //  [nil]  [nil]  [nil]  [1]    [2]    [3]    [4]

        // Actual dates

        for day in 1...numberOfDays {

            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else {
                continue
            }
            let isEnabled = calendar.compare(date, to: today, toGranularity: .day) != .orderedAscending
            // day=1: date = monthInterval.start + 0 days = 2026-07-01
            // day=2: date = monthInterval.start + 1 day  = 2026-07-02
            // ...
            // day=31: date = 2026-07-31
            
            days.append(
                CalendarDay(
                    date: date,
                    day: day,
                  //  isCurrentMonth: true, //Because generateDays(for:) only ever generates days for that specific month.
                    isSelected: false,
                    isEnabled: isEnabled
                )
            )
        }
//        Index 0  → nil  (empty - Sun)
//        Index 1  → nil  (empty - Mon)
//        Index 2  → nil  (empty - Tue)
//        Index 3  → day=1,  isEnabled=false  (past)
//        Index 4  → day=2,  isEnabled=false  (past)
//        ...
//        Index 15 → day=13, isEnabled=true   (today)
//        Index 16 → day=14, isEnabled=true
//        ...
//        Index 33 → day=31, isEnabled=true
        return days
    }
}
//MARK: -----

extension CalenderViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // currentMonthIndex = 2 → returns September's days count
        return self.calendarMonths[currentMonthIndex].days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // currentMonthIndex = 2 → reads from September's days array
    
        guard let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: DaysCVCell.reUseIdentifier, for: indexPath) as? DaysCVCell else { return UICollectionViewCell() }
      
        let item = self.calendarMonths[currentMonthIndex].days[indexPath.item]

           if let day = item.day {
               dayCell.bgView.isHidden = false
               dayCell.configure( title: "\(day)", isSelected: item.isSelected, isEnabled: item.isEnabled)
           } else {
               dayCell.bgView.isHidden = true
               dayCell.daysLabel.text = nil
           }
        return dayCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = self.calendarMonths[currentMonthIndex].days[indexPath.item]
        //        currentMonthIndex = 0  (July 2026)
        //        User taps day 15
        //        indexPath.item = 17    (3 empty cells + 14 days before it)
        
        guard let selectedDate = item.date, item.isEnabled else {
            return
        }
        
        switch repeatType {
            
        case .once:
            
            // Remove previous selection
            for monthIndex in calendarMonths.indices {
                for dayIndex in calendarMonths[monthIndex].days.indices {
                    calendarMonths[monthIndex].days[dayIndex].isSelected = false
                }
            }
            self.selectedDates.removeAll()
            
            //Append current selection
            self.selectedDates.append(selectedDate)
            self.calendarMonths[currentMonthIndex].days[indexPath.item].isSelected = true
            
        case .monthly:
            
            if let index = self.selectedDates.firstIndex(of: selectedDate) {
                
                // Deselect, remove that date from array if already exists
                self.selectedDates.remove(at: index)
                self.calendarMonths[currentMonthIndex].days[indexPath.item].isSelected = false
                
            } else {
                
                // Select
                self.selectedDates.append(selectedDate)
                self.calendarMonths[currentMonthIndex].days[indexPath.item].isSelected = true
            }
            // Keep dates sorted
            self.selectedDates.sort()
            
        default:
            break
        }
        collectionView.reloadData()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let sectionInset: CGFloat = 5
         let totalInsets = collectionView.contentInset.left + collectionView.contentInset.right + (sectionInset * 2)
         let availableWidth = collectionView.bounds.width - totalInsets
         let width = floor(availableWidth / 7.0)
         return CGSize(width: width - 4, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}

extension CalenderViewController {
    
    private func setCalenderScreenUI() {
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.dateTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.sunLabel.text = APPConstants.sunTitle
        self.sunLabel.textColor = .textPlaceholderColor
        
        self.monLabel.text = APPConstants.monTitle
        self.monLabel.textColor = .textPlaceholderColor
        
        self.tuesLabel.text = APPConstants.tueTitle
        self.tuesLabel.textColor = .textPlaceholderColor
        
        self.wednesLabel.text = APPConstants.wedTitle
        self.wednesLabel.textColor = .textPlaceholderColor
        
        self.thursLabel.text = APPConstants.thuTitle
        self.thursLabel.textColor = .textPlaceholderColor
        
        self.friLabel.text = APPConstants.friTitle
        self.friLabel.textColor = .textPlaceholderColor
        
        self.satLabel.text = APPConstants.satTitle
        self.satLabel.textColor = .textPlaceholderColor
       
        self.monthLabel.textColor = .labelPlaceholderColor
        
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
        
        self.datesCV.delegate = self
        self.datesCV.dataSource = self
        self.datesCV.register(DaysCVCell.nibFile, forCellWithReuseIdentifier: DaysCVCell.reUseIdentifier)
    }
    
    private func updateCalendarUI() {

        guard !self.calendarMonths.isEmpty else { return }

        self.monthLabel.text = self.calendarMonths[currentMonthIndex].monthName

        self.previousMonthButton.isEnabled = self.currentMonthIndex > 0
        self.previousMonthButton.alpha = self.currentMonthIndex > 0 ? 1 : 0.4

        self.nextMonthButton.isEnabled = self.currentMonthIndex < calendarMonths.count - 1
        self.nextMonthButton.alpha = self.currentMonthIndex < calendarMonths.count - 1 ? 1 : 0.4

        self.datesCV.reloadData()
        
//        App opens
//        currentMonthIndex = 0 → shows July 2026
//
//        User taps >
//        currentMonthIndex = 1 → shows August 2026
//
//        User taps >
//        currentMonthIndex = 2 → shows September 2026
//
//        User taps day 15
//        calendarMonths[2].days[...].isSelected = true
//        → September 15 is selected
//
//        User taps
//        currentMonthIndex = 1 → shows August 2026
//        → September 15 selection is preserved in calendarMonths[2]
//          because we never cleared it, just changed the index
    }
}

protocol CalendarVCDelegate: AnyObject {
    func calendarVCDidDismiss()
    func didSelectDates(_ date: [Date])
}

struct CalendarMonth {
    let monthDate: Date
    let monthName: String
    var days: [CalendarDay]
}
struct CalendarDay {
    let date: Date?
    let day: Int?
  //  let isCurrentMonth: Bool
    var isSelected: Bool
    var isEnabled: Bool
}
