//
//  ChannelTabViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 11/7/24.
//

import Foundation

final class ChannelTabViewModel: ObservableObject {
    @Published var navigateToChatRoom: Bool = false
    @Published var showChatPartnerPickerView = false
    @Published var newChannel: ChannelItem?
    
    func onNewChannelCreation(_ channel: ChannelItem) {
        showChatPartnerPickerView = false
        newChannel = channel
        navigateToChatRoom = true
    }
}
