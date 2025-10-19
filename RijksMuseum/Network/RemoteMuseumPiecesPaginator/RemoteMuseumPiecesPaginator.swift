//
//  RemoteMuseumPiecesPaginator.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

enum PaginationError: Error {
    case noMorePieces
    case unknownError
}

final class RemoteMuseumPiecesPaginator {
    
    private let batchCount = 10
    private var nextPageToken: String?
    private var currentBatchURLs = [URL]()
    private let loader: MuseumPiecesLoader
    private let languagePolicy: LanguageResolutionPolicy
    
    init(loader: MuseumPiecesLoader, languagePolicy: LanguageResolutionPolicy) {
        self.loader = loader
        self.languagePolicy = languagePolicy
    }
    
    func loadInitialPieces() async throws(PaginationError) -> [Piece] {
        nextPageToken = nil
        currentBatchURLs = []
        
        try await loadCollectionURLs()
        return await processNextBatch()
    }
    
    func loadMorePieces() async throws(PaginationError) -> [Piece] {
        if currentBatchURLs.isEmpty && nextPageToken == nil {
            throw .noMorePieces
        }
        
        if currentBatchURLs.isEmpty {
            try await loadCollectionURLs()
        }
        
        return await processNextBatch()
    }
    
    private func loadCollectionURLs() async throws(PaginationError) {
        do {
            let response = try await loader.loadCollectionURLs(nextPageToken: nextPageToken)
            self.currentBatchURLs = response.urls
            self.nextPageToken = response.nextPageToken
        }
        catch {
            throw .unknownError
        }
    }
    
    private func processNextBatch() async -> [Piece] {
        let firstBatchURLs = Array(currentBatchURLs.prefix(batchCount))
        
        defer {
            currentBatchURLs = Array(currentBatchURLs.dropFirst(batchCount))
        }
        
        return await loadPieces(for: firstBatchURLs)
    }
    
    private func loadPieces(for urls: [URL]) async -> [Piece] {
        return await withTaskGroup { [weak self] group in
            for url in urls {
                group.addTask { [weak self] in
                    return try? await self?.loader.loadPieceDetail(url: url)
                }
            }
            
            var results: [Piece] = []
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
    func mapToPiece(using policy: LanguageResolutionPolicy?) -> Piece {
        Piece(
            id: id,
            title: policy?.resolve(from: title?.values ?? [:]),
            date: policy?.resolve(from: date?.values ?? [:]),
            creator: policy?.resolve(from: creator?.values ?? [:]),
            image: .init(url: imageURL)
        )
    }
}
