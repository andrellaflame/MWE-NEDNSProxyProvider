//
//  Data+Utils.swift
//  DNS Proxy Extension
//
//  Created by Andrii Sulimenko on 2025-04-28.
//

import Foundation

extension Data {
    var nxdomainData: Data {
        let deafultPacket = Data(
            [0x00, 0x00,
             0x81, 0x83,
             0x00, 0x01,
             0x00, 0x00,
             0x00, 0x00,
             0x00, 0x00]
        )
        
        guard self.count >= 12 else { return deafultPacket }
        
        var response = Data()
        
        response.append(self.prefix(2))
        response.append(contentsOf: [0x81, 0x83])
        response.append(contentsOf: [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        
        if let optStartIndex = self[12...].firstIndex(of: 0x00) {
            response.append(self[12...optStartIndex + 4]) // Question section
        } else {
            response.append(self[12...]) // No OPT record
        }
        
        return response
    }
}
