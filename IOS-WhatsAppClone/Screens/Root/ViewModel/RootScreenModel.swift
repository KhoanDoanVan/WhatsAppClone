//
//  RootScreenModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 7/7/24.
//

import Foundation
import Combine

final class RootScreenModel: ObservableObject {
    @Published private(set) var authState = AuthState.pending
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = AuthManager.shared.authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] latestAuthState in
                self?.authState = latestAuthState
            }
    }
}
