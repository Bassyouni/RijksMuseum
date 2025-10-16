//
//  RemoteMuseumPiecesFetcher.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import Foundation

public final class RemoteMuseumPiecesFetcher {
    
    private let url: URL
    private let httpClient: HTTPClient
    
    public enum Error: Swift.Error {
        case networkError
    }
    
    public init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
    
    func fetchCollectionIDs(nextPageToken: String?) async throws(Error) {
        var url = self.url
        
        if let token = nextPageToken {
            url = url.appending(queryItems: [.init(name: "pageToken", value: token)])
        }
        
        guard let _ = try? await httpClient.get(url: url) else {
            throw .networkError
        }
    }
}
