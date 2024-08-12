//
//  ChatPartnerPickerViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 8/7/24.
//

import Firebase
import Combine

enum ChannelCreateRoute {
    case groupPartnerPicker
    case setUpGroupChat
}

enum ChannelContants {
    static let maxGroupParticipants = 12
}

enum ChannelCreationError: Error {
    case noChatPartner
    case failedToCreateUniqueIds
}

@MainActor
final class ChatPartnerPickerViewModel: ObservableObject {
    @Published var navStack = [ChannelCreateRoute]()
    @Published var selectedChatPartners = [UserItem]()
    @Published private(set) var users = [UserItem]()
    @Published var errorState: (showError: Bool, errorMessage: String) = (false, "Uh oh")

    private var lastCursor: String?
    private var userCurrent: UserItem?
    private var subscription: AnyCancellable?
    
    var showSelectUsers: Bool {
        return !selectedChatPartners.isEmpty
    }
    
    var disableNextButton: Bool {
        return selectedChatPartners.isEmpty
    }
    
    var isPaginatable: Bool {
        return !users.isEmpty
    }
    
    var isDirectChannel: Bool {
        return selectedChatPartners.count == 1
    }
    
    init() {
        listenForAuthState()
    }
    
    deinit {
        subscription?.cancel()
        subscription = nil
    }
    
    // fetch user current
    private func listenForAuthState() {
        subscription = AuthManager.shared.authState.receive(on: DispatchQueue.main)
            .sink { [weak self] authState in
            switch authState {
            case .loggedIn(let loggedInUser):
                self?.userCurrent = loggedInUser
                Task {
                    await self?.fetchUsers()
                }
            default:
                break
            }
        }
    }
    
    
    // MARK: - Public Methods
    
    func fetchUsers() async {
        do {
            let userNode = try await UserService.paginateUsers(lastCursor: lastCursor, pageSize: 5)
            var fetchUsers = userNode.users
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            fetchUsers = fetchUsers.filter { $0.uid != currentUid }
            self.users.append(contentsOf: fetchUsers)
            self.lastCursor = userNode.currentCursor
        } catch {
            print("Failed to fetch users")
        }
    }
    
    func deSelectAllChatPartners() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.selectedChatPartners.removeAll()
        }
    }
    
    func handleItemSelection(_ item: UserItem) {
        if isUserSelected(item) {
            guard let index = selectedChatPartners.firstIndex(where: {
                $0.uid == item.uid
            }) else { return }
            selectedChatPartners.remove(at: index)
        } else {
            guard selectedChatPartners.count < ChannelContants.maxGroupParticipants else {
                let errorMessage = "Sorry, we only allow a Maximum of \(ChannelContants.maxGroupParticipants) participants in a group chat."
                showError(errorMessage)
                return
            }
            selectedChatPartners.append(item)
        }
    }
    
    func isUserSelected(_ user: UserItem) -> Bool {
        let isSelected = selectedChatPartners.contains {
            $0.uid == user.uid
        }
        return isSelected
    }
    
    func createDirectChannel(_ chatPartner: UserItem, completion: @escaping (_ newChannel: ChannelItem) -> Void ) {
        
        if selectedChatPartners.isEmpty {
            selectedChatPartners.append(chatPartner)
        }
        
        Task {
            // if exsisting DM, get the channel
            if let channelId = await verifyIfDirectChannelExist(with: chatPartner.uid) {
                let snapshot = try await FirebaseConstants.ChannelsRef.child(channelId).getData()
                let channelDict = snapshot.value as! [String: Any]
                var directChannel = ChannelItem(channelDict)
                directChannel.members = selectedChatPartners
                if let userCurrent {
                    directChannel.members.append(userCurrent)
                }
                completion(directChannel)
            } else {
                // create a new DM with the user
                let channelCreation = createChannel(nil)
                switch channelCreation {
                case .success(let channel):
                    completion(channel)
                case .failure(let error):
                    showError("Sorry! Something Went Wrong While We Were Trying to Setup Your Chat.")
                    print("failed to create a Direct channel: \(error.localizedDescription)")
                }
            }
        }
    }
    
    typealias ChannelId = String
    private func verifyIfDirectChannelExist(with chatPartnerId: String) async -> ChannelId? {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let snapshot = try? await FirebaseConstants.UserDirectChannels.child(currentUid).child(chatPartnerId).getData(),
              snapshot.exists()
        else { return nil }
        
        let directMessageDict = snapshot.value as! [String: Bool]
        let channelId = directMessageDict.compactMap{ $0.key }.first
        return channelId
    }
    
    func createGroupChannel(_ groupName: String?, completion: @escaping (_ newChannel: ChannelItem) -> Void) {
        let channelCreation = createChannel(groupName)
        switch channelCreation {
        case .success(let channel):
            completion(channel)
        case .failure(let error):
            showError("Sorry! Something Went Wrong While We Were Trying to Setup Your Group Chat.")
            print("failed to create a Group channel: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ errorMessage: String) {
        errorState.errorMessage = errorMessage
        errorState.showError = true
    }
    
    private func createChannel(_ channelName: String?) -> Result<ChannelItem, Error> {
        guard !selectedChatPartners.isEmpty else {
            return .failure(ChannelCreationError.noChatPartner)
        }
        
        guard let channelId = FirebaseConstants.ChannelsRef.childByAutoId().key,
              let currentUid = Auth.auth().currentUser?.uid,
              let messageId = FirebaseConstants.MessagesRef.childByAutoId().key
        else {
            return .failure(ChannelCreationError.failedToCreateUniqueIds)
        }
        
        let timeStamp = Date().timeIntervalSince1970
        var membersUids = selectedChatPartners.map { $0.uid }
        membersUids.append(currentUid)
        
        let newChannelBroadcast = AdminMessageType.channelCreation.rawValue
        
        var channelDict: [String: Any] = [
            .id: channelId,
            .lastMessage: newChannelBroadcast,
            .lastMessageType: newChannelBroadcast,
            .creationDate: timeStamp,
            .lastMessageTimeStamp: timeStamp,
            .membersUids: membersUids,
            .membersCount: membersUids.count,
            .adminUids: [currentUid],
            .createdBy: currentUid
        ]
        
        if let channelName = channelName, !channelName.isEmptyOrWhiteSpace {
            channelDict[.name] = channelName
        }
        
        let messageDict: [String: Any] = [
            .type: newChannelBroadcast,
            .timeStamp: timeStamp,
            .ownerUid: currentUid
        ]
        
        FirebaseConstants.ChannelsRef.child(channelId).setValue(channelDict)
        FirebaseConstants.MessagesRef.child(channelId).child(messageId).setValue(messageDict)
        
        membersUids.forEach { userId in
            // keeping an index of the channel that a specific user belongs to
            FirebaseConstants.UserChannelsRef.child(userId).child(channelId).setValue(true)
        }
        
        if isDirectChannel {
            let chatPartner = selectedChatPartners[0]
            FirebaseConstants.UserDirectChannels.child(currentUid).child(chatPartner.uid).setValue([channelId: true])
            FirebaseConstants.UserDirectChannels.child(chatPartner.uid).child(currentUid).setValue([channelId: true])
        }
        
        var newChannelItem = ChannelItem(channelDict)
        newChannelItem.members = selectedChatPartners
        if let userCurrent {
            newChannelItem.members.append(userCurrent)
        }
        return .success(newChannelItem)
    }
}
