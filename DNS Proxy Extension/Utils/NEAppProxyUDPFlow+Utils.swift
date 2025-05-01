//
//  NEAppProxyUDPFlow+Utils.swift
//  DNS Proxy Extension
//
//  Created by Andrii Sulimenko on 2025-04-25.
//

import Foundation
import NetworkExtension

extension NEAppProxyUDPFlow {
    public func readDatagrams() async throws -> [(Data, NWEndpoint)] {
        try await withCheckedThrowingContinuation { [weak self] (promise: CheckedContinuation<[(Data, NWEndpoint)], Error>) in
            guard let self else {
                promise.resume(throwing: NSError(
                    domain: "NEAppProxyUDPFlowError", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "NEAppProxyUDPFlow.readDatagrams failed with nil reference to self"]
                ))
                return
            }
            
            self.readDatagrams { datagrams, endpoints, error in
                if let error {
                    promise.resume(throwing: error)
                } else if let datagrams, let endpoints {
                    let result = Array(zip(datagrams, endpoints))
                    promise.resume(returning: result)
                } else {
                    promise.resume(throwing: NSError(
                        domain: "NEAppProxyUDPFlowError", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "NEAppProxyUDPFlow.readDatagrams received no data and no error"]
                    ))
                }
            }
        }
    }
    
    public func writeDatagrams(_ datagrams: [(Data, NWEndpoint)]) async throws {
        try await withCheckedThrowingContinuation { [weak self] (promise: CheckedContinuation<Void, Error>) in
            guard let self else {
                promise.resume(throwing: NSError(
                    domain: "NEAppProxyUDPFlowError", code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "NEAppProxyUDPFlow.writeDatagrams failed with nil reference to self"]
                ))
                return
            }
            
            let (packets, endpoints) = datagrams.reduce(into: ([Data](), [NWEndpoint]())) {
                $0.0.append($1.0)
                $0.1.append($1.1)
            }
            
            self.writeDatagrams(packets, sentBy: endpoints) { error in
                if let error {
                    promise.resume(throwing: error)
                } else {
                    promise.resume(returning: ())
                }
            }
        }
    }
}

extension NEAppProxyFlow {
    public func open(withLocalEndpont localEndpoint: NWHostEndpoint? = nil) async throws {
        try await withCheckedThrowingContinuation { [weak self] (promise: CheckedContinuation<Void, Error>) in
            guard let self else {
                promise.resume(throwing: NSError(
                    domain: "NEAppProxyFlowError", code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "NEAppProxyFlow.open failed with nil reference to self"]
                ))
                return
            }
            
            self.open(withLocalEndpoint: localEndpoint) { error in
                if let error {
                    promise.resume(throwing: error)
                } else {
                    promise.resume(returning: ())
                }
            }
        }
    }
    
    public func close(_ error: Error? = nil) {
        self.closeReadWithError(error)
        self.closeWriteWithError(error)
    }
}
