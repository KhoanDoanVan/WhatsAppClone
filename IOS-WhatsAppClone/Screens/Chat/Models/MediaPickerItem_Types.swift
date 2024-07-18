//
//  MediaPickerItem_Types.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 18/7/24.
//

import SwiftUI


/// Transferable is a part of SwiftUI framework
struct VideoPickerTransferable: Transferable {
    let url: URL
    
    /// The propertise be inherited from Transferable protocol
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.url)
        } importing: { receivedTransferredFile in
            let originalFile = receivedTransferredFile.file
            let uniqueFileName = "\(UUID().uuidString).mov"
            let copiedFile = URL.documentsDirectory.appendingPathComponent(uniqueFileName)
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            return .init(url: copiedFile)
        }

    }
}


struct MediaAttachment: Identifiable {
    let id: String
    let type: MediaAttachmentType
    var thumbnail: UIImage {
        switch type {
        case .photo(let thumbnail):
            return thumbnail
        case .video(let thumbnail, _):
            return thumbnail
        case .audio:
            return UIImage()
        }
    }
}


enum MediaAttachmentType: Equatable {
    case photo(_ thumbnail: UIImage)
    case video(_ thumbnail: UIImage, _ url: URL)
    case audio
    
    static func == (lhs: MediaAttachmentType, rhs: MediaAttachmentType) -> Bool {
        switch(lhs, rhs) {
        case (.photo,.photo), (.video, .video), (.audio, .audio):
            return true
        default:
            return false
        }
    }
}
