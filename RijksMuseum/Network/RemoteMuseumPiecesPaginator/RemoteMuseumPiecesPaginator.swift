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
        let count = min(urls.count, batchCount)
        var models = [MuseumPiece]()
        
        for index in 0..<count {
            if let model = try? await loader.loadMuseumPieceDetail(url: urls[index]) {
                models.append(MuseumPiece(
                    id: model.id,
                    title: nil,
                    date: nil,
                    creator: nil,
                    image: .init(url: model.imageURL)
                ))
            }
        }
        
        return models
    }
}
