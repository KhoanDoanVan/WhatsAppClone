//
//  FirebaseConstants.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 7/7/24.
//

import Foundation
import Firebase

enum FirebaseConstants {
    private static let DatabaseRef = Database.database().reference()
    static let UserRef = DatabaseRef.child("users")
}
