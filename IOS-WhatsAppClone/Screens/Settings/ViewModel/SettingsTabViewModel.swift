//
//  SettingsTabViewModel.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 3/8/24.
//

import PhotosUI
import SwiftUI
import Combine
import Firebase
import AlertKit

@MainActor
final class SettingsTabViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var profilePhoto: MediaAttachment?
    @Published var showProgressHUD: Bool = false
    @Published var showSuccessHUD: Bool = false
    
    private var subscription: AnyCancellable?
    
    private(set) var progressHUDView = AlertAppleMusic17View(title: "Uploading Profile Photo", subtitle: nil, icon: .spinnerSmall)
    private(set) var successHUDView = AlertAppleMusic17View(title: "Profile Image Updated!", subtitle: nil, icon: .done)
    
    var disableSaveButton: Bool {
        return profilePhoto == nil
    }
    
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
    
    // Upload image to storage
    func uploadProfilePhoto() {
        guard let profilePhoto = profilePhoto?.thumbnail else { return }
        
        showProgressHUD = true
        
        FirebaseHelper.uploadImage(profilePhoto, for: .profilePhoto) { [weak self] result in
            switch result {
                
            case .success(let imageUrl):
                self?.onUploadSuccess(imageUrl)
            case .failure(let error):
                print("Failed to upload image to profile photo with error: \(error.localizedDescription)")
            }
        } progressHandler: { progress in
            print("uploadProfilePhoto: \(progress)")
        }
    }
    
    // Save image url in realtime database
    private func onUploadSuccess(_ imageUrl: URL) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        FirebaseConstants.UserRef.child(currentUid).child(.profileImageUrl).setValue(imageUrl.absoluteString)
        
        /// Dismiss animation uploading image
        showProgressHUD = false 
        progressHUDView.dismiss()
        
        /// Disable Save Button with delay after 0.3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showSuccessHUD = true /// show success alert
            self.profilePhoto = nil
            self.selectedPhotoItem = nil
        }
        print("onUploadSuccess with url: \(imageUrl.absoluteString)")
    }
}
