//
//  CollectionURLsMapper.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 17/10/2025.
//

import Foundation

final class CollectionURLsMapper {
    private struct Root: Codable {
        let orderedItems: [Item]
        let next: Next?
        
        func nextPageToken() -> String? {
            guard let url = next?.id,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let token = components.queryItems?.first(where: { $0.name == "pageToken" })?.value else {
                return nil
            }
            return token
        }
    }
    
    private struct Item: Codable {
        let id: URL
    }
    
    private struct Next: Codable {
        let id: URL
    }
    
    func map(data: Data) -> Result<(urls: [URL], nextPageToken: String?), RemoteMuseumPiecesFetcher.Error> {
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteMuseumPiecesFetcher.Error.invalidData)
        }
        
        return .success((root.orderedItems.map(\.id), root.nextPageToken()))
    }
}



