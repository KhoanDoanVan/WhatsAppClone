//
//  ChannelItem.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 11/7/24.
//

import Foundation


struct ChannelItem: Identifiable {
    var id: String
    var name: String?
    var lastMessage: String
    var creationDate: Date
    var lastMessageTimestamp: Date
    var membersCount: UInt
    var adminUids: [String]
    var membersUids: [String]
    var members: [UserItem]
    var thumbnailUrl: String?
    
    var isGroupChat: Bool {
        return membersCount > 2
    }
    
    static let placeholder = ChannelItem.init(id: "1", lastMessage: "Hello world", creationDate: Date(), lastMessageTimestamp: Date(), membersCount: 2, adminUids: [], membersUids: [], members: [])
}
