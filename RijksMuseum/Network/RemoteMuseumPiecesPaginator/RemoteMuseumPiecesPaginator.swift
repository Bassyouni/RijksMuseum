//
//  RemoteMuseumPiecesPaginator.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

final class RemoteMuseumPiecesPaginator {
    private let loader: MuseumPiecesLoader
    private let batchCount = 10
    
    init(loader: MuseumPiecesLoader) {
        self.loader = loader
    }
    
    func loadInitialPieces() async throws -> [MuseumPiece] {
        let (urls, _) = try await loader.loadCollectionURLs(nextPageToken: nil)
        
        let firstBatchURLs = Array(urls.prefix(batchCount))
        
        return await loadPieces(for: firstBatchURLs)
    }
    
    private func loadPieces(for urls: [URL]) async -> [MuseumPiece] {
        return await withTaskGroup { [weak self] group in
            for url in urls {
                group.addTask { [weak self] in
                    return try? await self?.loader.loadMuseumPieceDetail(url: url)
                }
            }
            
            var results: [MuseumPiece] = []
            for await localizedPiece in group {
                if let localizedPiece = localizedPiece {
                    results.append(localizedPiece.mapToPiece())
                }
            }
            return results
        }
    }
}

private extension LocalizedPiece {
    func mapToPiece() -> MuseumPiece {
        MuseumPiece(
            id: self.id,
            title: nil,
            date: nil,
            creator: nil,
            image: .init(url: self.imageURL)
        )
    }
}
