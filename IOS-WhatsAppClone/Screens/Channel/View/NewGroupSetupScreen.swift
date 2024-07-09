//
//  NewGroupSetupScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 9/7/24.
//

import SwiftUI

struct NewGroupSetupScreen: View {
    @State private var channelName = ""
    @ObservedObject var viewModel: ChatPartnerPickerViewModel
    var body: some View {
        List {
            Section {
                channelSetupHeaderView()
            }
            
            Section {
                Text("Disappering Messages")
                Text("Group Permissions")
            }
            
            Section {
                SelectedChatPartnerView(users: viewModel.selectedChatPartners) { user in
                    viewModel.handleItemSelection(user)
                }
            } header: {
                Text("Particular: 12/12")
                    .bold()
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("New Group")
        .toolbar {
            trailNavItem()
        }
    }
    
    private func channelSetupHeaderView() -> some View {
        HStack {
            Circle()
                .frame(width: 60, height: 60)
            
            TextField("", text: $channelName, prompt: Text("Group Name (optional)"), axis: .vertical)
        }
    }
    
    @ToolbarContentBuilder
    private func trailNavItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Create") {
                
            }
            .bold()
            .disabled(viewModel.disableNextButton)
        }
    }
}

#Preview {
    NavigationStack {
        NewGroupSetupScreen(viewModel: ChatPartnerPickerViewModel())
    }
}
