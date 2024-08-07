//
//  MessageMenuView.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 7/8/24.
//

import SwiftUI

struct MessageMenuView: View {
    
    let message: MessageItem
    @State private var animateBackgroundView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(MessageMenuAction.allCases) { action in
                buttonBody(action)
                    .frame(height: 45)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(action == .delete ? .red : .whatsAppBlack)
                
                if action != .delete {
                    Divider()
                }
            }
        }
        .frame(width: message.imageWidth)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(animateBackgroundView ? 1 : 0, anchor: message.menuAnchor)
        .opacity(animateBackgroundView ? 1 : 0)
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) {
                animateBackgroundView = true
            }
        }
    }
    
    private func buttonBody(_ action: MessageMenuAction) -> some View {
        Button {
            
        } label: {
            HStack {
                Text(action.rawValue.capitalized)
                Spacer()
                Image(systemName: action.systemImage)
            }
            .padding()
        }
    }
}

#Preview {
    MessageMenuView(message: .sentPlaceholder)
}
