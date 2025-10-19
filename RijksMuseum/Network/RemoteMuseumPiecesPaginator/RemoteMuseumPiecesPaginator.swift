//
//  RemoteMuseumPiecesPaginator.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

final class RemoteMuseumPiecesPaginator {
    private let loader: MuseumPiecesLoader
    
    init(loader: MuseumPiecesLoader) {
        self.loader = loader
    }
    
    func loadInitialPieces() async throws -> [MuseumPiece] {
        let (urls, _) = try await loader.loadCollectionURLs(nextPageToken: nil)
        
        let count = min(urls.count, 10)
        for index in 0..<count {
            _ = try await loader.loadMuseumPieceDetail(url: urls[index])
        }
        
        return []
    }
}
