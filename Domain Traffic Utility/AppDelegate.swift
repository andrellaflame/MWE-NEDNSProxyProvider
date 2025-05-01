//
//  AppDelegate.swift
//  Domain Traffic Utility
//
//  Created by Andrii Sulimenko on 2025-04-24.
//

import UIKit
import NetworkExtension
import OSLog

class AppDelegate: UIResponder, UIApplicationDelegate {
    let manager = DNSProxyManager.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.manager.enableProxy()
        return true
    }
}
