//
//  Parallelism.swift
//  DNS Proxy Extension
//
//  Created by Andrii Sulimenko on 2025-04-25.
//

import Foundation

extension Collection {
    func parallelMap<T: Sendable>(
        parallelism: Int = 2,
        _ transform: @escaping (Element) async throws -> T
    ) async rethrows -> [T] {
        guard !isEmpty else { return [] }
        let count = count
        return try await withThrowingTaskGroup(of: (Int, T?).self, returning: [T].self) { group in
            var buffer: [T?] = [T?](repeatElement(nil, count: count))

            var i = self.startIndex
            var submitted = 0

            func submitNext() async throws {
                if i == self.endIndex { return }
                
                group.addTask { [submitted, i] in
                    do {
                        let value = try await transform(self[i])
                        return (submitted, value)
                    } catch {
                        return (submitted, nil)
                    }
                }
                submitted += 1
                formIndex(after: &i)
            }

            for _ in 0 ..< parallelism {
                try await submitNext()
            }

            while let (index, taskResult) = try await group.next() {
                buffer[index] = taskResult

                try Task.checkCancellation()
                try await submitNext()
            }
            
            let result = buffer.compactMap { $0 }
            
            if result.count != count {
                throw NSError(
                    domain: "ParallelismError", code: 5,
                    userInfo: [NSLocalizedDescriptionKey: "ParallelMap transformation failed due to invalid result count"]
                )
            }
            
            buffer = []
            return result
        }
    }
}
