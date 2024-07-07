//
//  IOS_WhatsAppCloneApp.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 1/7/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
    return true
  }
}


@main
struct IOS_WhatsAppCloneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            RootScreen()
        }
    }
}
