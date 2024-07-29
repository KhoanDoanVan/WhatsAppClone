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
    let thumbnailUrl: String?
    var thumbnailHeight: CGFloat?
    var thumbnailWidth: CGFloat?
    var videoURL: String?
    var audioURL: String?
    var audioDuration: TimeInterval?
    
    var direction: MessageDirection {
        return ownerUid == Auth.auth().currentUser?.uid ? .sent : .received
    }
    
    static let sentPlaceholder = MessageItem(id: UUID().uuidString, isGroupChat: true, text: "Holy Shit", type: .text, ownerUid: "1", timeStamp: Date(), thumbnailUrl: nil)
    static let receivedPlaceholder = MessageItem(id: UUID().uuidString, isGroupChat: false, text: "Ok Shit", type: .text, ownerUid: "2", timeStamp: Date(), thumbnailUrl: nil)
    
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
    
    /// resize a image display
    var imageSize: CGSize {
        let photoWidth = thumbnailWidth ?? 0
        let photoHeight = thumbnailHeight ?? 0
        let imageHeight = CGFloat(photoHeight / photoWidth * imageWidth)
        return CGSize(width: imageWidth, height: imageHeight)
    }
    
    var imageWidth: CGFloat {
        let photoWidth = (UIWindowScene.current?.screenWidth ?? 0) / 1.5
        return photoWidth
    }
    
    var audioDurationInString: String {
        return audioDuration?.formatElaspedTime ?? "00:00"
    }
    
    var isSentByMe: Bool {
        return ownerUid == Auth.auth().currentUser?.uid ?? ""
    }
    
    func containsSameOwner(as message: MessageItem) -> Bool {
        if let userA = message.sender,
           let userB = self.sender {
            return userA == userB
        } else {
            return false
        }
    }
    
    static let stubMessages: [MessageItem] = [
        MessageItem(id: UUID().uuidString, isGroupChat: true, text: "Hi there", type: .text, ownerUid: "3", timeStamp: Date(), thumbnailUrl: nil),
        MessageItem(id: UUID().uuidString, isGroupChat: false, text: "Check out this Photo", type: .photo, ownerUid: "4", timeStamp: Date(), thumbnailUrl: nil),
        MessageItem(id: UUID().uuidString, isGroupChat: true, text: "Play out this Video", type: .video, ownerUid: "5", timeStamp: Date(), thumbnailUrl: nil),
        MessageItem(id: UUID().uuidString, isGroupChat: false, text: "", type: .audio, ownerUid: "6", timeStamp: Date(), thumbnailUrl: nil),
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
        self.thumbnailUrl = dict[.thumbnailUrl] as? String ?? ""
        self.thumbnailHeight = dict[.thumbnailHeight] as? CGFloat ?? nil
        self.thumbnailWidth = dict[.thumbnailWidth] as? CGFloat ?? nil
        self.videoURL = dict[.videoURL] as? String ?? nil
        self.audioURL = dict[.audioURL] as? String ?? nil
        self.audioDuration = dict[.audioDuration] as? TimeInterval ?? nil
    }
}


extension String {
    static let `type` = "type"
    static let timeStamp = "timeStamp"
    static let ownerUid = "ownerUid"
    static let text = "text"
    static let thumbnailWidth = "thumbnailWidth"
    static let thumbnailHeight = "thumbnailHeight"
    static let videoURL = "videoURL"
    static let audioDuration = "audioDuration"
    static let audioURL = "audioURL"
}
