//
//  URLSessionHTTPClient.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    
    public enum Error: Swift.Error {
        case networkError
        case invalidData
    }
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}
