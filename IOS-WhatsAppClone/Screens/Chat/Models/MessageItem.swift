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
    let text: String
    let type: MessageType
    let ownerUid: String
    
    var direction: MessageDirection {
        return ownerUid == Auth.auth().currentUser?.uid ? .sent : .received
    }
    
    static let sentPlaceholder = MessageItem(id: UUID().uuidString, text: "Holy Shit", type: .text, ownerUid: "1")
    static let receivedPlaceholder = MessageItem(id: UUID().uuidString, text: "Ok Shit", type: .text, ownerUid: "2")
    
    var alignment: Alignment { // the text will set to left or right screen
        return direction == .received ? .leading : .trailing
    }
    
    var horizontalAlignment: HorizontalAlignment { // the vstack alignment with timestamp
        return direction == .received ? .leading : .trailing
    }
    
    var backgroundColor: Color { // background color of the text
        return direction == .sent ? .bubbleGreen : .bubbleWhite
    }
    
    static let stubMessages: [MessageItem] = [
        MessageItem(id: UUID().uuidString, text: "Hi there", type: .text, ownerUid: "3"),
        MessageItem(id: UUID().uuidString, text: "Check out this Photo", type: .photo, ownerUid: "4"),
        MessageItem(id: UUID().uuidString, text: "Play out this Video", type: .video, ownerUid: "5"),
        MessageItem(id: UUID().uuidString, text: "", type: .audio, ownerUid: "6"),
    ]
}

extension MessageItem {
    init(id: String, dict: [String: Any]) {
        self.id = id
        self.text = dict[.text] as? String ?? ""
        let type = dict[.type] as? String ?? "text"
        self.type = MessageType(type)
        self.ownerUid = dict[.ownerUid] as? String ?? ""
    }
}


extension String {
    static let `type` = "type"
    static let timeStamp = "timeStamp"
    static let ownerUid = "ownerUid"
    static let text = "text"
}
