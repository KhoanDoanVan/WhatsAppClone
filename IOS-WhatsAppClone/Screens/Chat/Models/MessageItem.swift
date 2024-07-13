//
//  MessageItem.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 4/7/24.
//

import SwiftUI

struct MessageItem: Identifiable {
    let id: String = UUID().uuidString
    let text: String
    let type: MessageType
    let direction: MessageDirection
    
    static let sentPlaceholder = MessageItem(text: "Holy Shit", type: .text, direction: .sent)
    static let receivedPlaceholder = MessageItem(text: "Ok Shit", type: .text, direction: .received)
    
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
        MessageItem(text: "Hi there", type: .text, direction: .sent),
        MessageItem(text: "Check out this Photo", type: .photo, direction: .received),
        MessageItem(text: "Check out this video", type: .video, direction: .sent),
        MessageItem(text: "", type: .audio, direction: .received)
    ]
}


extension String {
    static let `type` = "type"
    static let timeStamp = "timeStamp"
    static let ownerUid = "ownerUid"
    static let text = "text"
}
