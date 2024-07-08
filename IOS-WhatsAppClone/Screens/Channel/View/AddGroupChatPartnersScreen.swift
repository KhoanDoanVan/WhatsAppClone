//
//  AddGroupChatPartnersScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 8/7/24.
//

import SwiftUI

struct AddGroupChatPartnersScreen: View {
    @ObservedObject var viewModel: ChatPartnerPickerViewModel
    @State private var searchText = ""
    var body: some View {
        List {
            
            if viewModel.showSelectUsers {
                Image(systemName: "user")
            }
            
            Section {
                ForEach([UserItem.placeholder]) { item in
                    Button {
                        viewModel.handleItemSelection(item)
                    } label: {
                        chatPartnerRowView(.placeholder)
                    }
                }
            }
        }
        .animation(.easeInOut, value: viewModel.showSelectUsers)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search name or number"
        )
    }
    
    private func chatPartnerRowView(_ user: UserItem) -> some View {
        ChatPartnerRowView(user: .placeholder) {
            Spacer()
            let isSelected = viewModel.isUserSelected(user)
            let imageName = isSelected ? "checkmark.circle.fill" : "circle"
            let foregroundStyle = isSelected ? Color.blue : Color(.systemGray4)
            Image(systemName: imageName)
                .foregroundStyle(foregroundStyle)
                .imageScale(.large)
        }
    }
}

#Preview {
    NavigationStack {
        AddGroupChatPartnersScreen(viewModel: ChatPartnerPickerViewModel())
    }
}
