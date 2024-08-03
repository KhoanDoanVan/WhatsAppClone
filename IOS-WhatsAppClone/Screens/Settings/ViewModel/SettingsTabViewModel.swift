//
//  SettingsTabViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 3/8/24.
//

import PhotosUI
import SwiftUI
import Combine

final class SettingsTabViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var profilePhoto: MediaAttachment?
    private var subscription: AnyCancellable?
    
    init() {
        onPhotoPickerSelection()
    }
    
    private func onPhotoPickerSelection() {
        subscription = $selectedPhotoItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photoItem in
                guard let photoItem else { return }
                self?.parsePhotoPickerItem(photoItem)
            }
    }
    
    private func parsePhotoPickerItem(_ photoItem: PhotosPickerItem) {
        Task {
            guard let data = try? await photoItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data)
            else { return }
            
            self.profilePhoto = MediaAttachment(id: UUID().uuidString, type: .photo(uiImage))
        }
    }
}
