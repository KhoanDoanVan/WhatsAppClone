//
//  ChannelTabViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 11/7/24.
//

import Foundation
import Firebase

final class ChannelTabViewModel: ObservableObject {
    @Published var navigateToChatRoom: Bool = false
    @Published var showChatPartnerPickerView = false
    @Published var newChannel: ChannelItem?
    @Published var channels = [ChannelItem]()
    typealias ChannelId = String
    @Published var channelDictionary: [ChannelId: ChannelItem] = [:]
    
    init() {
        fetchCurrentUserChannels()
    }
    
    func onNewChannelCreation(_ channel: ChannelItem) {
        showChatPartnerPickerView = false
        newChannel = channel
        navigateToChatRoom = true
    }
    
    private func fetchCurrentUserChannels() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        FirebaseConstants.UserChannelsRef.child(currentUid).observe(.value) { [weak self] snapshot in // use for closure
            guard let dict = snapshot.value as? [String: Any] else { return }
            dict.forEach { key, value in
                let channelId = key // channelID
                self?.getChannel(with: channelId)
            }
        } withCancel: { error in
            print("Failed to get the current user's channelIds: \(error.localizedDescription)")
        }

    }
    
    private func getChannel(with channelId: String) {
        FirebaseConstants.ChannelsRef.child(channelId).observe(.value) {[weak self] snapshot in
            guard let dict = snapshot.value as? [String: Any] else { return }
            var channel = ChannelItem(dict)
            self?.getChannelMembers(channel) { members in
                channel.members = members
                self?.channelDictionary[channelId] = channel
                self?.reloadData()
//                self?.channels.append(channel)
            }
        } withCancel: { error in
            print("Failed to get the channel for id \(channelId): \(error.localizedDescription)")
        }

    }
    
    private func getChannelMembers(_ channel: ChannelItem, completion: @escaping (_ members: [UserItem]) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let channelMemberUids = Array(channel.membersUids.filter{ $0 != currentUid })
        UserService.getUsers(with: channel.membersUids) { userNode in
            completion(userNode.users)
        }
    }
    
    // this function for avoid duplication the channelitem
    private func reloadData() {
        self.channels = Array(channelDictionary.values)
        
        // sort channel by message lasted
        self.channels.sort {
            $0.lastMessageTimestamp > $1.lastMessageTimestamp
        }
    }
}
