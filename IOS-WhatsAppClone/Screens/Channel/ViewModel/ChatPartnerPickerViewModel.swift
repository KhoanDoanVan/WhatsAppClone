//
//  ChatPartnerPickerViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 8/7/24.
//

import Foundation

enum ChannelCreateRoute {
    case addGroupChatMembers
    case setUpGroupChat
}

final class ChatPartnerPickerViewModel: ObservableObject {
    @Published var navStack = [ChannelCreateRoute]()
    @Published var selectedChatPartners = [UserItem]()
    
    var showSelectUsers: Bool {
        return !selectedChatPartners.isEmpty
    }
    
    
    // MARK: - Public Methods
    func handleItemSelection(_ item: UserItem) {
        if isUserSelected(item) {
            guard let index = selectedChatPartners.firstIndex(where: {
                $0.uid == item.uid
            }) else { return }
            selectedChatPartners.remove(at: index)
        } else {
            selectedChatPartners.append(item)
        }
    }
    
    func isUserSelected(_ user: UserItem) -> Bool {
        let isSelected = selectedChatPartners.contains {
            $0.uid == user.uid
        }
        return isSelected
    }
}
