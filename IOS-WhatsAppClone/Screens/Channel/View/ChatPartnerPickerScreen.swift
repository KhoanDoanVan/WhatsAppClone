//
//  ChatPartnerPickerScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 7/7/24.
//

import SwiftUI

struct ChatPartnerPickerScreen: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(ChatPartnerPickerOption.allCases) { item in
                    HeaderItemView(item: item)
                }
                
                Section {
                    ForEach(0..<12) { _ in
                        ChatPartnerRowView(user: .placeholder)
                    }
                } header: {
                    Text("Contacts on WhatsApp")
                        .textCase(nil)
                        .bold()
                }
            }
            .searchable(text: $searchText, prompt: "Search name or number")
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                trailingNavItem()
            }
        }
    }
}

extension ChatPartnerPickerScreen {
    @ToolbarContentBuilder
    private func trailingNavItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            cancelButton()
        }
    }
    
    private func cancelButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.footnote)
                .bold()
                .foregroundStyle(.gray)
                .padding(8)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
    }
}

extension ChatPartnerPickerScreen {
    
    private struct HeaderItemView: View {
        let item: ChatPartnerPickerOption
        var body: some View {
            Button {
                
            } label: {
                buttonBody()
            }
        }
        
        private func buttonBody() -> some View {
            HStack {
                Image(systemName: item.imageName)
                    .font(.footnote)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                
                Text(item.title)
            }
        }
    }
}

enum ChatPartnerPickerOption: String, CaseIterable, Identifiable {
    case newGroup = "New Group"
    case newContact = "New Contact"
    case newCommunity = "New Community"
    
    var id: String {
        return rawValue
    }
    
    var title: String {
        return rawValue
    }
    
    var imageName: String {
        switch self {
            
        case .newGroup:
            return "person.2.fill"
        case .newContact:
            return "person.fill.badge.plus"
        case .newCommunity:
            return "person.3.fill"
        }
    }
}

#Preview {
    ChatPartnerPickerScreen()
}
