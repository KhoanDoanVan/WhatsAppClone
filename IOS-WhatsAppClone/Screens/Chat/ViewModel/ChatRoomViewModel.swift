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
    
    
    private(set) var channel: ChannelItem // get set the propertise has been private in this class
    private var currentUser: UserItem?
    private var subscriptions = Set<AnyCancellable>()
    
    /// Voice recorder Service
    private let voiceRecorderSerice = VoiceRecorderService()
    
    var showPhotoPickerPreview: Bool {
        return !mediaAttachments.isEmpty || !photoPickerItems.isEmpty
    }
    
    init(_ channel: ChannelItem) {
        self.channel = channel
        listenToAuthState()
        onPhotoPickerSelection()
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
        guard let _ = currentUser else { return }
        let membersAlreadyFetched = channel.members.compactMap{ $0.uid }
        let memberUIDSToFetch = channel.membersUids.filter{ !membersAlreadyFetched.contains($0) }

        UserService.getUsers(with: memberUIDSToFetch) { [weak self] userNode in
            guard let self = self else { return }
            self.channel.members.append(contentsOf: userNode.users)
            self.getMessages()
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
        if voiceRecorderSerice.isRecording {
            /// stop record
            voiceRecorderSerice.stopRecording { [weak self] audioURL, audioDuration in
                self?.createAudioAttachment(from: audioURL, audioDuration)
            }
        } else {
            /// start record
            voiceRecorderSerice.startRecording()
        }
    }
    
    private func createAudioAttachment(from audioURL: URL?, _ audioDuration: TimeInterval) {
        guard let audioURL = audioURL else { return }
        let id = UUID().uuidString
        let audioAttachment = MediaAttachment(id: id, type: .audio)
        mediaAttachments.insert(audioAttachment, at: 0)
    }
    
    private func onPhotoPickerSelection() {
        $photoPickerItems.sink { [weak self] photoItems in
            guard let self = self else { return }
            self.mediaAttachments.removeAll()
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
        }
    }
    
    private func remove(_ attachment: MediaAttachment) {
        guard let attachmentIndex = mediaAttachments.firstIndex(where: { $0.id == attachment.id }) else { return }
        mediaAttachments.remove(at: attachmentIndex)
        
        guard let photoPickerIndex = photoPickerItems.firstIndex(where: { $0.itemIdentifier == attachment.id }) else { return }
        photoPickerItems.remove(at: photoPickerIndex)
    }
}
