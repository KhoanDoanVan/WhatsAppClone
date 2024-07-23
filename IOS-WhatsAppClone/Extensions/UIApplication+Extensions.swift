//
//  UIApplication+Extensions.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 23/7/24.
//

import UIKit

extension UIApplication {
    
    /// Disappear the keyboard
    static func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIApplication.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        
    }
}
