//
//  RootScreen.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 7/7/24.
//

import SwiftUI

struct RootScreen: View {
    @StateObject private var viewModel = RootScreenModel()
    var body: some View {
        switch viewModel.authState {
        case .pending:
            ProgressView()
                .controlSize(.large)
            
        case .loggedIn(let loggedInUser):
            MainTabView(loggedInUser)
            
        case .loggedOut:
            LoginScreen()
        }
    }
}

#Preview {
    RootScreen()
}
