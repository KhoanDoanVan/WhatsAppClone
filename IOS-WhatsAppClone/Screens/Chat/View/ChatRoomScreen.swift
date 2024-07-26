//
//  ChatRoomScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 3/7/24.
//

import SwiftUI
import PhotosUI

struct ChatRoomScreen: View {
    let channel: ChannelItem
    @StateObject private var viewModel: ChatRoomViewModel
    @StateObject private var voiceMessagePlayer = VoiceMessagePlayer()
    
    init(channel: ChannelItem) {
        self.channel = channel
        _viewModel = StateObject(wrappedValue: ChatRoomViewModel(channel))
    }
    
    var body: some View {
        MessageListView(viewModel)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                leadingNavItems()
                trailingNavItems()
            }
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $viewModel.photoPickerItems,
                maxSelectionCount: 6,
                photoLibrary: .shared() /// need properties for get id for each of the photopicker library
            )
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                bottomSafeAreaView()
                    .background(Color.whatsAppWhite)
            }
            .animation(.easeInOut, value: viewModel.showPhotoPickerPreview)
            .fullScreenCover(isPresented: $viewModel.videoPlayerState.show) {
                if let player = viewModel.videoPlayerState.player {
                    MediaPlayerView(player: player) {
                        viewModel.dismissMediaPlayer()
                    }
                }
            }
            .environmentObject(voiceMessagePlayer) /// shared data object that can be accessed by any child view
    }
    
    private func bottomSafeAreaView() -> some View {
        VStack(spacing: 0) {
            Divider()
            if viewModel.showPhotoPickerPreview {
                MediaAttachmentPreview(mediaAttachment: viewModel.mediaAttachments) { actionUser in
                    viewModel.handleMediaAttachmentPreview(actionUser)
                }
                Divider()
            }
            
            TextInputArea(
                textMessage: $viewModel.textMessage,
                isRecording: $viewModel.isRecordingVoiceMessage,
                elapsedTime: $viewModel.elaspedVoiceMessageTime,
                disableSendButton: viewModel.disableSendButton
            ) { action in
                viewModel.handleTextInputArea(action)
            }
        }
    }
}

extension ChatRoomScreen {
    
    private var channelTitle: String {
        let maxChar = 20
        let trailingChars = channel.title.count > maxChar ? "..." : ""
        let title = String(channel.title.prefix(maxChar) + trailingChars)
        return title
    }
    
    @ToolbarContentBuilder
    private func leadingNavItems() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                CircularProfileImageView(channel, size: .mini)
                
                Text(channelTitle)
                    .bold()
            }
        }
    }
    
    @ToolbarContentBuilder
    private func trailingNavItems() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Image(systemName: "video")
            }
            
            Button {
                
            } label: {
                Image(systemName: "phone")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomScreen(channel: .placeholder)
    }
}
