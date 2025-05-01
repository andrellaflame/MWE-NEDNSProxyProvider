//
//  DNSProxyManager.swift
//  Domain Traffic Utility
//
//  Created by Andrii Sulimenko on 2025-04-28.
//

import Foundation
import NetworkExtension
import OSLog

final class DNSProxyManager {
    
    private let manager = NEDNSProxyManager.shared()
    static let shared = DNSProxyManager()
    
    public func enableProxy() {
        self.update { (manager: NEDNSProxyManager) in
            
            var providerProtocol: NEDNSProxyProviderProtocol
            
            if let existingProviderProtocol = manager.providerProtocol {
                providerProtocol = existingProviderProtocol
            } else {
                providerProtocol = NEDNSProxyProviderProtocol()
            }
            
            providerProtocol.providerBundleIdentifier = "dns-proxy.mwe.Domain-Traffic-Utility.DNS-Proxy-Extension"
            manager.providerProtocol = providerProtocol
            
            manager.localizedDescription = "DNS Proxy | MWE"
            manager.isEnabled = true
            
            Logger.statistics.info("[DNSProxyManager] - Prepared DNS settings for saving. Enabled: \(manager.isEnabled, privacy: .public)")
        }
    }
    
    public func disableProxy() {
        self.update { manager in
            manager.isEnabled = false
            Logger.statistics.info("[DNSProxyManager] - Prepared DNS settings for saving. Enabled: \(manager.isEnabled, privacy: .public)")
        }
    }

    private func update(_ body: @escaping (NEDNSProxyManager) -> Void) {
        self.manager.loadFromPreferences { [weak self] error in
            guard let self else {
                return
            }
            
            if let error {
                Logger.statistics.error("[DNSProxyManager] – Failed to load DNS preferences (might be first time): \(error.localizedDescription, privacy: .public)")
                return
            }

            body(self.manager)

            self.manager.saveToPreferences { error in
                if let error {
                    Logger.statistics.error("[DNSProxyManager] – Failed to save DNS preferences: \(error.localizedDescription, privacy: .public)")
                    return
                }
                
                Logger.statistics.info("[DNSProxyManager] – Saved DNS preferences successfully. Enabled: \(self.manager.isEnabled, privacy: .public)")
            }
        }
    }
}
