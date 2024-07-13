//
//  ChatRoomViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 13/7/24.
//

import Foundation
import Combine


final class ChatRoomViewModel : ObservableObject {
    @Published var textMessage = ""
    private let channel: ChannelItem
    @Published var currentUser: UserItem?
    private var subscriptions = Set<AnyCancellable>()
    
    init(_ channel: ChannelItem) {
        self.channel = channel
        listenToAuthState()
    }
    
    deinit {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
        currentUser = nil
    }
    
    // fetch current user
    private func listenToAuthState() {
        AuthManager.shared.authState
            .receive(on: DispatchQueue.main)
            .sink { authState in
                    switch authState {
                        case .loggedIn(let currentUser):
                            self.currentUser = currentUser
                        default:
                            break
                    }
            }.store(in: &subscriptions)
    }
    
    func sendMessage() {
        guard let currentUser else { return }
        MessageService.sendTextMessages(to: channel, from: currentUser, textMessage) { [weak self] in
            self?.textMessage = ""
        }
    }

}
