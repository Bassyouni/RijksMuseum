//
//  RemoteMuseumPiecesFetcher.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import Foundation

final class RemoteMuseumPiecesFetcher {
    
    private let url: URL
    private let httpClient: HTTPClient
    
    enum Error: Swift.Error {
        case networkError
        case invalidData
    }
    
    init(url: URL, httpClient: HTTPClient) {
        self.url = url
        self.httpClient = httpClient
    }
    
    @concurrent
    func fetchCollectionURLs(nextPageToken: String?) async throws(Error) -> (urls: [URL], nextPageToken: String?) {
        var url = self.url
        
        if let token = nextPageToken {
            url = url.appending(queryItems: [.init(name: "pageToken", value: token)])
        }
        
        guard let data = try? await httpClient.get(url: url) else {
            throw .networkError
        }
        
        return try await CollectionURLsMapper().map(data: data).get()
    }
    
    @concurrent
    func fetchMuseumPieceDetail(url: URL) async throws(Error) -> MuseumPiece {
        guard let _ = try? await httpClient.get(url: url) else {
            throw .networkError
        }
        
        throw .invalidData
    }
}
