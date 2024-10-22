//
//  ChatRoomViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 13/7/24.
//

import Foundation
import Combine
import PhotosUI
import SwiftUI


final class ChatRoomViewModel : ObservableObject {
    @Published var textMessage = ""
    @Published var messages = [MessageItem]()
    @Published var showPhotoPicker = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var mediaAttachments: [MediaAttachment] = []
    @Published var videoPlayerState: (show: Bool, player: AVPlayer?) = (false, nil)
    @Published var isRecordingVoiceMessage = false
    @Published var elaspedVoiceMessageTime: TimeInterval = 0
    @Published var scrollToBottomRequest: (scroll: Bool, isAnimate: Bool) = (false, false)
    @Published var isPaginating = false
    
    private var currentPage: String?
    private var firstMessage: MessageItem?
    
    
    private(set) var channel: ChannelItem // get set the propertise has been private in this class
    private var currentUser: UserItem?
    private var subscriptions = Set<AnyCancellable>()
    
    /// Voice recorder Service
    private let voiceRecorderService = VoiceRecorderService()
    
    var showPhotoPickerPreview: Bool {
        return !mediaAttachments.isEmpty || !photoPickerItems.isEmpty
    }

    var disableSendButton: Bool {
        return mediaAttachments.isEmpty && textMessage.isEmptyOrWhiteSpace
    }
    
    // is checking whether the current environment is running within Xcode’s SwiftUI preview.
    private var isPreviewMode: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    init(_ channel: ChannelItem) {
        self.channel = channel
        listenToAuthState()
        onPhotoPickerSelection()
        setUpVoiceRecorderListeners()
        
        // Check current environment is running within Xcode's SwiftUI preview or not, if true is the messages is stub messages
        if isPreviewMode {
            messages = MessageItem.stubMessages
        }
    }
    
    deinit {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
        currentUser = nil
        
        // if u back that view while using recording, it will be removed that file recording
        voiceRecorderService.tearDown()
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
                                self.getHistoricalMessages()
                            } else {
                                self.getAllChannelMembers()
                                print("here")
                            }
                        
                        default:
                            break
                    }
            }.store(in: &subscriptions)
    }
    
    private func setUpVoiceRecorderListeners() {
        voiceRecorderService.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecordingVoiceMessage = isRecording
            }
            .store(in: &subscriptions)
        
        voiceRecorderService.$elaspedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] elaspedTime in
                self?.elaspedVoiceMessageTime = elaspedTime
            }
            .store(in: &subscriptions)
    }
    
    func sendMessage() {
        if mediaAttachments.isEmpty {
            sendTextMessage(textMessage)
        } else {
            sendMultipleMediaMessages(textMessage, attachments: mediaAttachments)
            clearInputArea()
        }
    }
    
    private func sendTextMessage(_ text: String) {
        guard let currentUser else { return }
        MessageService.sendTextMessages(to: channel, from: currentUser, text) { [weak self] in
            self?.textMessage = ""
        }
    }
    
    func clearInputArea() {
        textMessage = ""
        mediaAttachments.removeAll()
        photoPickerItems.removeAll()
        UIApplication.dismissKeyboard()
    }
    
    private func sendMultipleMediaMessages(_ text: String, attachments: [MediaAttachment]) {
        
        for (index, attachment) in attachments.enumerated() {
            
            let textMessage = index == 0 ? text : ""
            
            switch attachment.type {
            case .photo:
                sendPhotoMessage(text: textMessage, attachment)
            case .video:
                sendVideoMessage(text: textMessage, attachment)
            case .audio:
                sendVoiceMessage(text: textMessage, attachment)
            }
        }
    }
    
    private func sendPhotoMessage(text: String, _ attachment: MediaAttachment) {
        /// upload the image to storage bucket
        uploadImageToStorage(attachment) {[weak self] imageURL in
            
            guard let self = self, let currentUser else { return }
            
            let uploadParams = MessageUploadParams(
                channel: channel,
                text: text,
                type: .photo,
                attachment: attachment,
                thumbnailURL: imageURL.absoluteString,
                sender: currentUser
            )
            
            MessageService.sendMediaMessage(to: channel, params: uploadParams) { [weak self] in
                self?.scrollToBottom(isAnimated: true)
            }
        }
    }
    
    private func sendVideoMessage(text: String, _ attachment: MediaAttachment) {
        uploadFileToStorage(for: .videoMessage, attachment) { [weak self] videoURL in
            // Upload the video thumbnail
            self?.uploadImageToStorage(attachment, completion: { [weak self] imageURL in
                guard let self = self, let currentUser else { return }
                
                let uploadParams = MessageUploadParams(
                    channel: self.channel,
                    text: text,
                    type: .video,
                    attachment: attachment,
                    thumbnailURL: imageURL.absoluteString,
                    videoURL: videoURL.absoluteString,
                    sender: currentUser
                )
                
                MessageService.sendMediaMessage(to: self.channel, params: uploadParams) { [weak self] in
                    self?.scrollToBottom(isAnimated: true)
                }
            })
        }
    }
    
    private func sendVoiceMessage(text: String, _ attachment: MediaAttachment) {
        
        guard let duration = attachment.duration, let currentUser else { return }
        
        uploadFileToStorage(for: .voiceMessage, attachment) { [weak self] fileURL in
            guard let self else { return }
            
            let uploadParams = MessageUploadParams(
                channel: self.channel,
                text: text,
                type: .audio,
                attachment: attachment,
                sender: currentUser, 
                audioURL: fileURL.absoluteString,
                audioDuration: duration
            )
            
            MessageService.sendMediaMessage(to: self.channel, params: uploadParams) { [weak self] in
                self? .scrollToBottom(isAnimated: true)
            }
            
            if !text.isEmptyOrWhiteSpace {
                sendTextMessage(text)
            }
        }
    }
    
    private func scrollToBottom(isAnimated: Bool) {
        scrollToBottomRequest.scroll = true
        scrollToBottomRequest.isAnimate = isAnimated
    }
    
    // UPLOAD IMAGE
    private func uploadImageToStorage(_ attachment: MediaAttachment, completion: @escaping(_ imageURL: URL) -> Void) {
        FirebaseHelper.uploadImage(attachment.thumbnail, for: .photoMessage) { result in
            switch result {
                
            case .success(let imageURL):
                completion(imageURL)
            case .failure(let error):
                print("Failed to upload Image to Storage: \(error.localizedDescription)")
            }
        } progressHandler: { progress in
            print("UPLOAD IMAGE PROGRESS: \(progress)")
        }
    }
    
    // FILE UPLOAD
    private func uploadFileToStorage(
        for uploadType: FirebaseHelper.UploadType,
        _ attachment: MediaAttachment,
        completion: @escaping(_ fileURL: URL) -> Void
    ) {
        guard let fileURLToUpload = attachment.fileURL else { return }
        FirebaseHelper.uploadFile(for: uploadType, fileURL: fileURLToUpload) { result  in
            switch result {
                
            case .success(let fileURL):
                completion(fileURL)
            case .failure(let error):
                print("Failed to upload file to Storage: \(error.localizedDescription)")
            }
        } progressHandler: { progress in
            print("UPLOAD FILE PROGRESS: \(progress)")
        }

    }
    
    var isPaginatable: Bool {
        return currentPage != firstMessage?.id
    }

    private func getHistoricalMessages() {
        isPaginating = currentPage != nil
        MessageService.getHistoricalMessages(for: channel, lastCursor: currentPage, pageSize: 12) { [weak self] messageNode in
            // Fetch first message when start display the chatroomscreen
            if self?.currentPage == nil {
                self?.getFirstMessage()
                self?.listenForNewMessages()
            }
            self?.messages.insert(contentsOf: messageNode.messages, at: 0)
            self?.currentPage = messageNode.currentCursor
            self?.scrollToBottom(isAnimated: false)
            self?.isPaginating = false
        }
    }
    
    func paginationMoreMessages() {
        guard isPaginatable else {
            isPaginating = false
            return
        }
        getHistoricalMessages()
    }
    
    private func getFirstMessage() {
        MessageService.getFirstMessage(in: channel) { [weak self] firstMessage in
            self?.firstMessage = firstMessage
        }
    }
    
    private func listenForNewMessages() {
        MessageService.listenForNewMessages(in: channel) { [weak self] newMessage in
            self?.messages.append(newMessage)
            self?.scrollToBottom(isAnimated: false)
        }
    }
    
    private func getAllChannelMembers() {
        /// I already have current user, and potentially 2 others members so no need to refetch those
        guard let _ = currentUser else { return }
        let membersAlreadyFetched = channel.members.compactMap{ $0.uid }
        let memberUIDSToFetch = channel.membersUids.filter{ !membersAlreadyFetched.contains($0) }

        UserService.getUsers(with: memberUIDSToFetch) { [weak self] userNode in
            guard let self = self else { return }
            self.channel.members.append(contentsOf: userNode.users)
            self.getHistoricalMessages()
            print("getAllChannelMembers: \(channel.members.map{ $0.username } )")
        }
    }
    
    func handleTextInputArea(_ action: TextInputArea.UserAction) {
        switch action {
        case .presentPhotoPicker:
            showPhotoPicker = true
        case .sendMessage:
            sendMessage()
        case .recordAudio:
            toggleAudioRecorder()
        }
    }
    
    /// Toggle Audio Record
    private func toggleAudioRecorder() {
        if voiceRecorderService.isRecording {
            /// stop record
            voiceRecorderService.stopRecording { [weak self] audioURL, audioDuration in
                self?.createAudioAttachment(from: audioURL, audioDuration)
            }
        } else {
            /// start record
            voiceRecorderService.startRecording()
        }
    }
    
    private func createAudioAttachment(from audioURL: URL?, _ audioDuration: TimeInterval) {
        guard let audioURL = audioURL else { return }
        let id = UUID().uuidString
        let audioAttachment = MediaAttachment(id: id, type: .audio(audioURL, audioDuration))
        mediaAttachments.insert(audioAttachment, at: 0)
    }
    
    private func onPhotoPickerSelection() {
        $photoPickerItems.sink { [weak self] photoItems in
            guard let self = self else { return }
            // self.mediaAttachments.removeAll()
            let audioRecordings = mediaAttachments.filter({ $0.type == .audio(.stubURL, .stubTimeInterval) })
            self.mediaAttachments = audioRecordings
            Task {
                await self.parsePhotoPickerItem(photoItems)
            }
        }.store(in: &subscriptions)
    }
    
    @MainActor
    private func parsePhotoPickerItem(_ photoPickerItems: [PhotosPickerItem]) async {
        for photoItem in photoPickerItems {
            
            if photoItem.isVideo {
                
                if let movie = try? await photoItem.loadTransferable(type: VideoPickerTransferable.self),
                   let thumbnailImage = try? await movie.url.generateVideoThumbnail() ,
                   let itemIdentifier = photoItem.itemIdentifier /// need photoLibrary properties is a part of photoPicker in ChatRoomScreen
                {
                    let videoAttachment = MediaAttachment(id: itemIdentifier, type: .video(thumbnailImage, movie.url))
                    self.mediaAttachments.insert(videoAttachment, at: 0)
                }
                    
            } else {
                guard let data = try? await photoItem.loadTransferable(type: Data.self),
                      let thumbnail = UIImage(data: data),
                      let itemIdentifier = photoItem.itemIdentifier
                else { return }
    
                let photoAttachment = MediaAttachment(id: itemIdentifier, type: .photo(thumbnail))
                self.mediaAttachments.insert(photoAttachment, at: 0)
            }

        }
    }
    
    func dismissMediaPlayer() {
        videoPlayerState.player?.replaceCurrentItem(with: nil)
        videoPlayerState.player = nil
        videoPlayerState.show = false
    }
    
    func showMediaPlayer(_ fileURL: URL) {
        videoPlayerState.show = true
        videoPlayerState.player = AVPlayer(url: fileURL)
    }
    
    func handleMediaAttachmentPreview(_ action: MediaAttachmentPreview.UserAction) {
        switch action {
        case .play(let attachmemt):
            guard let fileURL = attachmemt.fileURL else { return }
            showMediaPlayer(fileURL)
        case .remove(let attachment):
            remove(attachment)
            guard let fileURL = attachment.fileURL else { return }
            if attachment.type == .audio(.stubURL, .stubTimeInterval) {
                voiceRecorderService.deleteRecording(at: fileURL)
            }
        }
    }
    
    private func remove(_ attachment: MediaAttachment) {
        guard let attachmentIndex = mediaAttachments.firstIndex(where: { $0.id == attachment.id }) else { return }
        mediaAttachments.remove(at: attachmentIndex)
        
        guard let photoPickerIndex = photoPickerItems.firstIndex(where: { $0.itemIdentifier == attachment.id }) else { return }
        photoPickerItems.remove(at: photoPickerIndex)
    }
    
    // Check the newDay display or not
    func isNewDay(for message: MessageItem, at index: Int) -> Bool {
        let priorIndex = max(0, (index - 1))
        let priorMessage = messages[priorIndex]
        return !message.timeStamp.isSameDay(as: priorMessage.timeStamp)
    }
    
    func showSenderName(for message: MessageItem, at index: Int) -> Bool {
        guard channel.isGroupChat else { return false }
        
        /// Show only when it's a group chat && when it's not sent by current user
        let isNewDay = isNewDay(for: message, at: index)
        let priorIndex = max(0, (index - 1))
        let priorMessage = messages[priorIndex]
        
        if isNewDay {
            /// If is not sent by current user && is a group chat
            return !message.isSentByMe
        } else {
            /// If is not sent by current user && is a group chat && the message before this one is not sent by the same sender
            return !message.isSentByMe && !message.containsSameOwner(as: priorMessage)
        }
    }
}
