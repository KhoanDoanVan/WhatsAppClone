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
}
