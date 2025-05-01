//
//  NWConnection+Utils.swift
//  DNS Proxy Extension
//
//  Created by Andrii Sulimenko on 2025-04-28.
//

import Foundation
import NetworkExtension

fileprivate final actor ResumptionManager<T> {
    private var didResume = false

    func resume(_ promise: CheckedContinuation<T, Error>, with result: Result<T, Error>) {
        guard !didResume else {
            return
        }
        
        didResume = true
    
        switch result {
        case .success(let value):
            promise.resume(returning: value)
        case .failure(let error):
            promise.resume(throwing: error)
        }
    }
}

extension NWConnection {
    // MARK: - Connection establishment
    /// Method for connection establishment for Datagrams
    func establish(on queue: DispatchQueue) async throws {
        try await withCheckedThrowingContinuation { [weak self] (promise: CheckedContinuation<Void, Error>) in
            let resumptionManager = ResumptionManager<Void>()
            self?.stateUpdateHandler = { state in
                Task {
                    switch state {
                    case .setup:
                        break
                    case .waiting(_):
                        break
                    case .preparing:
                        break
                    case .ready:
                        await resumptionManager.resume(promise, with: .success(()))
                    case let .failed(error):
                        await resumptionManager.resume(promise, with: .failure(error))
                    case .cancelled:
                        break
                    @unknown default:
                        await resumptionManager.resume(promise, with: .failure(NSError(
                            domain: "NWConnectionError", code: 7,
                            userInfo: [NSLocalizedDescriptionKey: "Unknown connection state: \(state)"]
                        )))
                    }
                }
            }
            
            self?.start(queue: queue)
        }
    }
    
    public func disconnect() {
        self.stateUpdateHandler = nil
        self.cancel()
    }
    
    // MARK: - Package sending
    /// Method for sending packets for Datagrams connection
    func send<Content: DataProtocol>(
        content: Content?,
        contentContext: NWConnection.ContentContext = .defaultMessage,
        isComplete: Bool = true
    ) async throws {
        try await withCheckedThrowingContinuation { [weak self] (promise: CheckedContinuation<Void, Error>) in
            let resumptionManager = ResumptionManager<Void>()
            
            self?.send(
                content: content,
                contentContext: contentContext,
                isComplete: isComplete,
                completion: .contentProcessed { error in
                    Task {
                        if let error = error {
                            await resumptionManager.resume(promise, with: .failure(error))
                        } else {
                            await resumptionManager.resume(promise, with: .success(()))
                        }
                    }
                })
        }
    }
    
    // MARK: - Message receiving
    /// Method for receiving message from Datagram connection
    func receiveMessage() async throws -> Message {
        try await withCheckedThrowingContinuation { [weak self] (promise: CheckedContinuation<Message, Error>) in
            let resumptionManager = ResumptionManager<Message>()
            
            self?.receiveMessage { completeContent, contentContext, isComplete, error in
                Task {
                    if let error {
                        await resumptionManager.resume(promise, with: .failure(error))
                    } else {
                        do {
                            let message = try Message(
                                completeContent: completeContent,
                                contentContext: contentContext,
                                isComplete: isComplete
                            )
                            await resumptionManager.resume(promise, with: .success(message))
                        } catch {
                            await resumptionManager.resume(promise, with: .failure(error))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - DNS Message
    /// A message representing the content of a DNS packet
    struct Message {
        /// The complete content of the message
        let completeContent: Data
        /// The context of the content, if available
        let contentContext: ContentContext?
        /// A Boolean value indicating whether the message is complete
        let isComplete: Bool
        /// Initializes a DNS message with the provided content, content context, and completion status
        /// - Parameters:
        ///   - completeContent: The complete content of the message
        ///   - contentContext: The context of the content, if available
        ///   - isComplete: A Boolean value indicating whether the message is complete
        /// - Throws: An error if the complete content is empty
        init(completeContent: Data?, contentContext: ContentContext?, isComplete: Bool) throws {
            guard let completeContent = completeContent, !completeContent.isEmpty else {
                throw NSError(
                    domain: "NWConnectionMessageError", code: 8,
                    userInfo: [NSLocalizedDescriptionKey: "Message init failed due to incomplete DNS message content"]
                )
            }
            self.completeContent = completeContent
            self.contentContext = contentContext
            self.isComplete = isComplete
        }
    }
}
