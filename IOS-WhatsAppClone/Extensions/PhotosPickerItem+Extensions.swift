//
//  PhotosPickerItem+Extensions.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 18/7/24.
//

import Foundation
import PhotosUI
import SwiftUI

extension PhotosPickerItem {
    var isVideo: Bool {
        /// array of values representing various video file types.
        let videoUTTypes: [UTType] = [
            .avi,
            .video,
            .mpeg2Video,
            .mpeg4Movie,
            .movie,
            .quickTimeMovie,
            .audiovisualContent,
            .mpeg,
            .appleProtectedMPEG4Video
        ]
        
        /// This is a property of PhotosPickerItem that contains an array of UTType values supported by the item.
        return videoUTTypes.contains(where: supportedContentTypes.contains)
    }
}
