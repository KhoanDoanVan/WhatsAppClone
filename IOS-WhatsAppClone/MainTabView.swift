//
//  MainTabView.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 1/7/24.
//

import SwiftUI

struct MainTabView: View {
    
    private let currentUser: UserItem
    
    init(_ currentUser: UserItem) {
        self.currentUser = currentUser
        makeTabBarOpaque()
        let thumbImage = UIImage(systemName: "circle.fill")
        UISlider.appearance().setThumbImage(thumbImage, for: .normal) //  set colorfor button slider
    }
    
    var body: some View {
        TabView {
            UpdatesTabScreen()
                .tabItem {
                    Image(systemName: Tab.updates.icon)
                    Text(Tab.updates.title)
                }
            CallTabScreen()
                .tabItem {
                    Image(systemName: Tab.calls.icon)
                    Text(Tab.calls.title)
                }
            CommunityTabScreen()
                .tabItem {
                    Image(systemName: Tab.communities.icon)
                    Text(Tab.communities.title)
                }
            ChannelTabScreen(currentUser)
                .tabItem {
                    Image(systemName: Tab.chats.icon)
                    Text(Tab.chats.title)
                }
            SettingsTabScreen(currentUser)
                .tabItem {
                    Image(systemName: Tab.settings.icon)
                    Text(Tab.settings.title)
                }
        }
    }
    
    private func makeTabBarOpaque() { // fix the tab bar transparent whenever scroll over height
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

extension MainTabView {
    
    private func placeholderItemView(_ title: String) -> some View {
        ScrollView {
            ForEach(0..<100) { _ in
                Text(title)
            }
        }
    }
    
    private enum Tab: String {
        case updates, calls, communities, chats, settings
        
        fileprivate var title: String {
            return rawValue.capitalized
        }
        
        fileprivate var icon: String {
            switch self {
            case .updates:
                return "circle.dashed.inset.filled"
                
            case .calls:
                return "phone"
                
            case .communities:
                return "person.3"
                
            case .chats:
                return "message"
                
            case .settings:
                return "gear"
            }
        }
    }
}

#Preview {
    MainTabView(UserItem.placeholder)
}
