//
//  ChannelTabScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 2/7/24.
//

import SwiftUI

struct ChannelTabScreen: View {
    @State private var searchText = ""
    @StateObject private var viewModel = ChannelTabViewModel()
    var body: some View {
        NavigationStack {
            List {
                archivedButton()
                
                ForEach(0..<12) { _ in
                    NavigationLink {
                        ChatRoomScreen()
                    } label: {
                        ChannelItemView()
                    }
                }
                
                inboxFooterView()
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .searchable(text: $searchText)
            .toolbar {
                leadingNavItems()
                trailingNavItems()
            }
            .sheet(isPresented: $viewModel.showChatPartnerPickerView, content: {
                ChatPartnerPickerScreen(onCreate: viewModel.onNewChannelCreation)
            })
            .navigationDestination(isPresented: $viewModel.navigateToChatRoom) {
                if let newChannel = viewModel.newChannel {
                    ChatRoomScreen()
                }
            }
        }
    }
}

extension ChannelTabScreen {
    @ToolbarContentBuilder
    private func leadingNavItems() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    
                } label: {
                    Label("Select Chats", systemImage: "checkmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    @ToolbarContentBuilder
    private func  trailingNavItems() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            aiButton()
            cameraButton()
            newChatButton()
        }
    }
    
    private func aiButton() -> some View {
        Button {
            
        } label: {
            Image(.circle)
        }
    }
    
    private func newChatButton() -> some View {
        Button {
            viewModel.showChatPartnerPickerView.toggle()
        } label: {
            Image(.plus)
        }
    }
    
    private func cameraButton() -> some View {
        Button {
            
        } label: {
            Image(systemName: "camera")
        }
    }
    
    private func archivedButton() -> some View {
        Button {
            
        } label: {
            Label("Archived", systemImage: "archivebox.fill")
                .body
                .padding()
                .foregroundStyle(.gray)
        }
    }
    
    private func inboxFooterView() -> some View {
        HStack {
            Image(systemName: "lock.fill")
            
            (
            Text("Your personal message are ")
            +
            Text("end-to-end encrypted")
                .foregroundStyle(.blue)
            )
        }
        .foregroundStyle(.gray)
        .font(.caption)
        .padding(.horizontal)
    }
}


#Preview {
    ChannelTabScreen()
}
