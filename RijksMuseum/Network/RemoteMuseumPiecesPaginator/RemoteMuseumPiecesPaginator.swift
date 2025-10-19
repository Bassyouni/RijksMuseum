//
//  RemoteMuseumPiecesPaginator.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

final class RemoteMuseumPiecesPaginator {
    
    private let batchCount = 10
    private let loader: MuseumPiecesLoader
    private let languagePolicy: LanguageResolutionPolicy
    
    init(loader: MuseumPiecesLoader, languagePolicy: LanguageResolutionPolicy) {
        self.loader = loader
        self.languagePolicy = languagePolicy
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
                    results.append(localizedPiece.mapToPiece(using: self?.languagePolicy))
                }
            }
            return results
        }
    }
}

private extension LocalizedPiece {
    func mapToPiece(using policy: LanguageResolutionPolicy?) -> MuseumPiece {
        MuseumPiece(
            id: id,
            title: policy?.resolve(from: title?.values ?? [:]),
            date: policy?.resolve(from: date?.values ?? [:]),
            creator: policy?.resolve(from: creator?.values ?? [:]),
            image: .init(url: imageURL)
        )
    }
}
