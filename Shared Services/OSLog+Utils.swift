//
//  OSLog+Utils.swift
//  Domain Traffic Utility
//
//  Created by Andrii Sulimenko on 2025-04-24.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "DomainTrafficUtility"
    
    static let traffic = Logger(subsystem: subsystem, category: "traffic")
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
