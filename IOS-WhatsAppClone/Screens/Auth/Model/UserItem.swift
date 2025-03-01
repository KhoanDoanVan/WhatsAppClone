//
//  UserItem.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 7/7/24.
//

import Foundation

struct UserItem: Identifiable, Hashable, Decodable {
    let uid: String
    var username: String
    let email: String
    var bio: String? = nil
    var profileImageUrl: String? = nil
    
    var id: String {
        return uid
    }
    
    var bioUnwrapped: String {
        return bio ?? "Hey there! I am using WhatsApp."
    }
    
    static let placeholder = UserItem(uid: "1", username: "ad", email: "ad@gmail.com")
    
    static let placeholders: [UserItem] = [
        UserItem(uid: "1", username: "Osas", email: "osas@gmail.com"),
        UserItem(uid: "2", username: "JohnDoe", email: "johndoe@gmail.com", bio: "Hello, I'm John."),
        UserItem(uid: "3", username: "JaneSmith", email: "janesmith@gmail.com", bio: "Passionate about coding."),
        UserItem(uid: "4", username: "Alice", email: "alice@gmail.com", bio: "Tech enthusiast."),
        UserItem(uid: "5", username: "Bob", email: "bob@gmail.com", bio: "Lover of nature."),
        UserItem(uid: "6", username: "Ella", email: "ella@gmail.com", bio: "Dreamer"),
        UserItem(uid: "7", username: "michael", email: "michael@gmail.com"),
        UserItem(uid: "8", username: "Sophie", email: "sophie@gmail.com", bio: "Coffee addict ☕️."),
        UserItem(uid: "9", username: "David", email: "david@gmail.com", bio: "Music lover."),
        UserItem(uid: "10", username: "Emily", email: "emily@gmail.com", bio: "Travel enthusiast."),
    ]
}

extension UserItem {
    init(dictionary: [String: Any]) {
        self.uid = dictionary[.uid] as? String ?? ""
        self.username = dictionary[.username] as? String ?? ""
        self.email = dictionary[.email] as? String ?? ""
        self.bio = dictionary[.bio] as? String? ?? nil
        self.profileImageUrl = dictionary[.profileImageUrl] as? String? ?? nil
    }
}


extension String {
    static let uid = "uid"
    static let username = "username"
    static let email = "email"
    static let bio = "bio"
    static let profileImageUrl = "profileImageUrl"
}
