//
//  Date+Extensions.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 15/7/24.
//

import Foundation

extension Date {
    
    /// if today: 3:30 PM
    /// if yesterday returns Yesterday
    /// else 02/15/24
    
    var dayOrTimeRepresentation: String {
        
        let calender = Calendar.current
        let dateFormmater = DateFormatter()
        
        if calender.isDateInToday(self) {
            
            dateFormmater.dateFormat = "h:mm a"
            let formmattedDate = dateFormmater.string(from: self)
            return formmattedDate
            
        } else if calender.isDateInYesterday(self) {
            
            return "Yesterday"
            
        } else {
            
            dateFormmater.dateFormat = "MM/dd/yy"
            return dateFormmater.string(from: self)
            
        }
    }
    
    /// 3:30 PM
    var formatToTime: String {
        let dateFormmater = DateFormatter()
        dateFormmater.dateFormat = "h:mm a"
        let formattedTime = dateFormmater.string(from: self)
        return formattedTime
    }
    
    
    func toString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    
    /// Relative time of message
    var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if isCurrentWeek {
            return toString(format: "EEEE") // Monday, Tuesday
        } else if isCurrentYear {
            return toString(format: "E, MMM d") // Mon, Feb 19
        } else {
            return toString(format: "MMM dd, YYYY") // Mon, Feb 19, 2020
        }
    }
    
    private var isCurrentWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekday)
    }
    
    private var isCurrentYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: otherDate)
    }
}
