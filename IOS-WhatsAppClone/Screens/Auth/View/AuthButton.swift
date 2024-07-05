//
//  AuthButton.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 5/7/24.
//

import SwiftUI

struct AuthButton: View {
    let title: String
    let onTap: () -> Void
    @Environment(\.isEnabled) private var isEnable // disable action
    
    private var backgroundColor: Color {
        return isEnable ? Color.white : Color.white.opacity(0.3)
    }
    private var textColor: Color {
        return isEnable ? Color.green : Color.white
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Text(title)
                Image(systemName: "arrow.right")
            }
            .font(.headline)
            .foregroundStyle(textColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .green.opacity(0.2), radius: 10)
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    AuthButton(title: "Login") {
        
    }
}
