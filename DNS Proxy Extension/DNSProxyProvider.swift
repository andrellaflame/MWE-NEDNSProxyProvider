//
//  DNSProxyProvider.swift
//  DNS Proxy Extension
//
//  Created by Andrii Sulimenko on 2025-04-24.
//

import NetworkExtension
import OSLog

private extension DispatchQueue {
    static let datagramConnection = DispatchQueue(label: "mwe.dns-proxy.datagram-connection")
}

class DNSProxyProvider: NEDNSProxyProvider {
    override func startProxy(options:[String: Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        Logger.traffic.info("NEDNSProxyProvider started")
        completionHandler(nil)
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        Logger.traffic.error("NEDNSProxyProvider stopped with reason: \(reason.rawValue, privacy: .public)")
        completionHandler()
    }
    
    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        Logger.statistics.info("[NEDNSProxyProvider] - Received \(flow.debugDescription, privacy: .public)")
        
        switch flow {
        case let udpFlow as NEAppProxyUDPFlow:
            Task { [weak self] in
                await self?.handleNewUDPFlow(udpFlow)
            }
            return true
        default:
            return false
        }
    }
    
    private func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow) async {
        do {
            try await flow.open()
        } catch {
            let flowOpenErrorMessage = "[NEDNSProxyProvider | UDP] - Did fail to open NEAppProxyUDPFlow \(flow): \(error.localizedDescription)"
            Logger.traffic.error("\(flowOpenErrorMessage, privacy: .public)")
            
            flow.close(error)
            return
        }
        
        do {
            let datagrams = try await flow.readDatagrams()
            
            let results = await datagrams.parallelMap(parallelism: 4) {
                do {
                    guard let hostEndpoint = $0.1 as? NetworkExtension.NWHostEndpoint,
                          let port = Network.NWEndpoint.Port(hostEndpoint.port) else {
                        throw NSError(
                            domain: "NEDNSProxyProviderUDPError", code: 9,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint type"]
                        )
                    }
                    
                    let host = Network.NWEndpoint.Host(hostEndpoint.hostname)
                    let connection = NWConnection(host: host, port: port, using: .udp)
                    
                    defer {
                        connection.cancel()
                    }
                    
                    try await connection.establish(on: .datagramConnection)
                    try await connection.send(content: $0.0)
                    let message = try await connection.receiveMessage()
                    
                    return (message.completeContent, $0.1)
                } catch {
                    Logger.traffic.error("[DatagramConnection] - Failed to handle connection with system resolver: \(error.localizedDescription, privacy: .public)")
                    return ($0.0.nxdomainData, $0.1)
                }
            }
            
            try await flow.writeDatagrams(results)
            
            flow.close()
        } catch {
            let flowWriteErrorMessage = "[NEDNSProxyProvider | UDP] - Did fail to handle NEAppProxyUDPFlow \(flow): \(error.localizedDescription)"
            Logger.traffic.error("\(flowWriteErrorMessage, privacy: .public)")
            
            flow.close(error)
            return
        }
    }
}
