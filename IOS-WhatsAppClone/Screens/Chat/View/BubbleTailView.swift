//
//  BubbleTailView.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 4/7/24.
//

import SwiftUI

struct BubbleTailView: View {
    var direction: MessageDirection
    
    private var backgroundColor: Color {
        return direction == .received ? .bubbleWhite : .bubbleGreen
    }
    
    var body: some View {
        Image(direction == .sent ? .outgoingTail : .incomingTail)
            .renderingMode(.template)
            .resizable()
            .frame(width: 10, height: 10)
            .offset(y: 3)
            .foregroundStyle(backgroundColor)
    }
}

#Preview {
    ScrollView {
        BubbleTailView(direction: .sent)
        BubbleTailView(direction: .received)
    }
    .frame(maxWidth: .infinity)
    .background(Color.black.opacity(0.8))
}
