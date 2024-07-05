//
//  CallTabScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 2/7/24.
//

import SwiftUI

struct CallTabScreen: View {
    @State private var searchText = ""
    @State private var callHistory = CallHistory.all
    var body: some View {
        NavigationStack {
            List {
                Section {
                    CreateCallLinkSection()
                }
                
                Section {
                    ForEach(0..<12) { _ in
                        RecentCallItemView()
                    }
                } header: {
                    Text("Recent")
                        .textCase(nil)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.whatsAppBlack)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Call")
            .toolbar {
                leadingNavItem()
                trailingNavItem()
                pricipalNavItem()
            }
        }
    }
}

extension CallTabScreen {
    @ToolbarContentBuilder
    private func leadingNavItem() -> some
    ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Edit") {}
        }
    }
    
    @ToolbarContentBuilder
    private func trailingNavItem() -> some
    ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
            } label: {
                Image(systemName: "phone.arrow.up.right")
            }
        }
    }
    
    @ToolbarContentBuilder
    private func pricipalNavItem() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("", selection: $callHistory) {
                ForEach(CallHistory.allCases) { item in
                    Text(item.rawValue.capitalized)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }
    
    private enum CallHistory: String, CaseIterable, Identifiable {
        case all, missed
        
        var id: String {
            return rawValue
        }
    }
}

private struct CreateCallLinkSection: View {
    var body: some View {
        HStack {
            Image(systemName: "link")
                .padding(0)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text("Create Call Link")
                    .foregroundStyle(.blue)
                Text("Share a link for your WhatsApp call")
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
        }
    }
}

private struct RecentCallItemView: View {
    var body: some View {
        HStack {
            Circle()
                .frame(width: 45, height: 45)
            
            recenttCallsTextView()
            
            Spacer()
            
            Text("Yesterday")
                .foregroundStyle(.gray)
                .font(.system(size: 16))
            
            Image(systemName: "info.circle")
        }
    }
    
    private func recenttCallsTextView() -> some View {
        VStack(alignment: .leading) {
            Text("John Smith")
            
            HStack(spacing: 5) {
                Image(systemName: "phone.arrow.up.right.fill")
                Text("Outgoing")
            }
            .font(.system(size: 14))
            .foregroundStyle(.gray)
        }
    }
}

#Preview {
    CallTabScreen()
}
