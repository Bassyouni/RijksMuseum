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
    
    func fetchCollectionIDs(nextPageToken: String?) async throws(Error) -> [String] {
        var url = self.url
        
        if let token = nextPageToken {
            url = url.appending(queryItems: [.init(name: "pageToken", value: token)])
        }
        
        guard let data = try? await httpClient.get(url: url) else {
            throw .networkError
        }
        
        guard let collectionResponse = try? JSONDecoder().decode(CollectionResponse.self, from: data) else {
            throw .invalidData
        }
        
        return collectionResponse.orderedItems.map(\.id)
    }
}


private struct CollectionResponse: Codable {
    let orderedItems: [Item]
    
    struct Item: Codable {
        let id: String
    }
}
