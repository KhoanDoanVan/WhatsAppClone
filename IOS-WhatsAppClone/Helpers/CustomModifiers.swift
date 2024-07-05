//
//  CustomModifiers.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 4/7/24.
//

import Foundation
import SwiftUI

private struct BubbleTailModifier: ViewModifier {
    var direction: MessageDirection
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: direction == .received ? .bottomLeading : .bottomTrailing) {
                BubbleTailView(direction: direction)
            }
    }
}

extension View {
    func applyTail(_ direction: MessageDirection) -> some View {
        self.modifier(BubbleTailModifier(direction: direction))
    }
}
