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
    @Published var messages = [MessageItem]()
    
    private(set) var channel: ChannelItem // get set the propertise has been private in this class
    private var currentUser: UserItem?
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
            .sink { [weak self] authState in
                guard let self = self else { return }
                    switch authState {
                        case .loggedIn(let currentUser):
                            self.currentUser = currentUser
                        
                            if self.channel.allMembersFetched {
                                self.getMessages()
                            } else {
                                self.getAllChannelMembers()
                                print("here")
                            }
                        
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

    private func getMessages() {
        MessageService.getMessages(for: channel) {[weak self] messages in
            self?.messages = messages
            print("messages: \(messages.map { $0.text })")
        }
    }
    
    private func getAllChannelMembers() {
        /// I already have current user, and potentially 2 others members so no need to refetch those
        guard let currentUser = currentUser else { return }
        let membersAlreadyFetched = channel.members.compactMap{ $0.uid }
        let memberUIDSToFetch = channel.membersUids.filter{ !membersAlreadyFetched.contains($0) }

        UserService.getUsers(with: memberUIDSToFetch) { [weak self] userNode in
            guard let self = self else { return }
            self.channel.members.append(contentsOf: userNode.users)
            self.getMessages()
            print("getAllChannelMembers: \(channel.members.map{ $0.username } )")
        }
    }
}
