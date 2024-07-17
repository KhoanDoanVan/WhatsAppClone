//
//  MessageItem.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 4/7/24.
//

import SwiftUI
import Firebase

struct MessageItem: Identifiable {
    let id: String
    let isGroupChat: Bool
    let text: String
    let type: MessageType
    let ownerUid: String
    let timeStamp: Date
    var sender: UserItem?
    
    var direction: MessageDirection {
        return ownerUid == Auth.auth().currentUser?.uid ? .sent : .received
    }
    
    static let sentPlaceholder = MessageItem(id: UUID().uuidString, isGroupChat: true, text: "Holy Shit", type: .text, ownerUid: "1", timeStamp: Date())
    static let receivedPlaceholder = MessageItem(id: UUID().uuidString, isGroupChat: false, text: "Ok Shit", type: .text, ownerUid: "2", timeStamp: Date())
    
    var alignment: Alignment { // the text will set to left or right screen
        return direction == .received ? .leading : .trailing
    }
    
    var horizontalAlignment: HorizontalAlignment { // the vstack alignment with timestamp
        return direction == .received ? .leading : .trailing
    }
    
    var backgroundColor: Color { // background color of the text
        return direction == .sent ? .bubbleGreen : .bubbleWhite
    }
    
    var showGroupPartnerInfo: Bool {
        return isGroupChat && direction == .received 
    }
    
    var leadingPadding: CGFloat {
        return direction == .received ? 0 : horizontalPadding
    }
    
    var trailingPadding: CGFloat {
        return direction == .received ? horizontalPadding : 0
    }
    
    private let horizontalPadding: CGFloat = 25
    
    static let stubMessages: [MessageItem] = [
        MessageItem(id: UUID().uuidString, isGroupChat: true, text: "Hi there", type: .text, ownerUid: "3", timeStamp: Date()),
        MessageItem(id: UUID().uuidString, isGroupChat: false, text: "Check out this Photo", type: .photo, ownerUid: "4", timeStamp: Date()),
        MessageItem(id: UUID().uuidString, isGroupChat: true, text: "Play out this Video", type: .video, ownerUid: "5", timeStamp: Date()),
        MessageItem(id: UUID().uuidString, isGroupChat: false, text: "", type: .audio, ownerUid: "6", timeStamp: Date()),
    ]
}

extension MessageItem {
    init(id: String, isGroupChat: Bool, dict: [String: Any]) {
        self.id = id
        self.isGroupChat = isGroupChat
        self.text = dict[.text] as? String ?? ""
        let type = dict[.type] as? String ?? "text"
        self.type = MessageType(type) ?? .text
        self.ownerUid = dict[.ownerUid] as? String ?? ""
        let timeInterval = dict[.timeStamp] as? TimeInterval ?? 0
        self.timeStamp = Date(timeIntervalSince1970: timeInterval)
    }
}


extension String {
    static let `type` = "type"
    static let timeStamp = "timeStamp"
    static let ownerUid = "ownerUid"
    static let text = "text"
}
