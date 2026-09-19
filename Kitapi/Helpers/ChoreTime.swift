//
//  ChoreTime.swift
//  Kitapi
//
//  Created by Suneel on 17/06/26.
//

import Foundation

struct ChoreTime {

    let hour12: Int
    let minute: Int
    let isAM: Bool

    var totalMinutes: Int {

        var hour24 = hour12

        if !isAM && hour12 != 12 {
            hour24 += 12  // PM (not 12) → add 12
        }

        if isAM && hour12 == 12 {
            hour24 = 0
        }

        return hour24 * 60 + minute
    }
    
    
    static func fromDate(_ date: Date) -> ChoreTime {

        let calendar = Calendar.current

        let hour24 = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        let isAM = hour24 < 12
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12

        return ChoreTime(
            hour12: hour12,
            minute: minute,
            isAM: isAM
        )
    }

    func adding(minutes: Int) -> ChoreTime {

        let total = (totalMinutes + minutes) % 1440

        let hour24 = total / 60
        let minute = total % 60

        let isAM = hour24 < 12
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12

        return ChoreTime(
            hour12: hour12,
            minute: minute,
            isAM: isAM
        )
    }

    var displayTextIn24HourFormat: String {
        
        var hour24 = hour12

           if !isAM && hour12 != 12 {
               hour24 += 12
           }

           if isAM && hour12 == 12 {
               hour24 = 0
           }

           return String(format: "%02d:%02d", hour24, minute)
    }
    
    var displayTextIn12HourFormat: String {

        String(
            format: "%02d:%02d %@",
            hour12,
            minute,
            isAM ? "AM" : "PM"
        )
    }
}
// 12 AM → hour24 = 0   → 0 * 60   = 0
//1 AM → hour24 = 1   → 1 * 60   = 60
//11 AM → hour24 = 11  → 11 * 60  = 660
//12 PM → hour24 = 12  → 12 * 60  = 720
//1 PM → hour24 = 13  → 13 * 60  = 780
//11 PM → hour24 = 23  → 23 * 60  = 1380

//11:50 PM + 15 mins:
//  totalMinutes = 1430
//  total = (1430 + 15) % 1440 = 5
//  hour24 = 0, minute = 5
//  isAM = true, hour12 = 12
//  → 12:05 AM ✅  (midnight wrap works)
//
//11:45 AM + 15 mins:
//  totalMinutes = 705
//  total = 720
//  hour24 = 12, minute = 0
//  isAM = false, hour12 = 12
//  → 12:00 PM ✅
//
//12:00 AM + 15 mins:
//  totalMinutes = 0
//  total = 15
//  hour24 = 0, minute = 15
//  isAM = true, hour12 = 12
//  → 12:15 AM ✅


//ChoreTime(hour12: 1,  minute: 5,  isAM: true)  → "01:05 AM" 
//ChoreTime(hour12: 12, minute: 0,  isAM: false) → "12:00 PM"
//ChoreTime(hour12: 11, minute: 30, isAM: false) → "11:30 PM"
