//
//  RemoteMuseumPiecesLoader.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import Foundation

final class RemoteMuseumPiecesLoader: MuseumPiecesLoader {
    
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
    func loadCollectionURLs(nextPageToken: String?) async throws(Error) -> (urls: [URL], nextPageToken: String?) {
        var url = self.url
        
        if let token = nextPageToken {
            url = url.appending(queryItems: [.init(name: "pageToken", value: token)])
        }
        
        guard let data = try? await httpClient.get(url: url) else {
            throw .networkError
        }
        
        return try await CollectionURLsMapper.map(data: data).get()
    }
    
    @concurrent
    func loadPieceDetail(url: URL) async throws(Error) -> LocalizedPiece {
        guard let data = try? await httpClient.get(url: url) else {
            throw .networkError
        }

        let (piece, visualItemURL) = try await PieceDetailsMapper.map(data: data).get()
        let imageURL = await fetchImageURL(from: visualItemURL)

        return LocalizedPiece(
            id: piece.id,
            title: piece.title,
            date: piece.date,
            creator: piece.creator,
            imageURL: imageURL
        )
    }

    @concurrent
    private func fetchImageURL(from visualItemURL: URL?) async -> URL? {
        guard let visualItemURL = visualItemURL else { return nil }
        guard let digitalObjectURL = await fetchDigitalObjectURL(from: visualItemURL) else { return nil }
        guard let iiifURL = await fetchIIIFImageURL(from: digitalObjectURL) else { return nil }
        return iiifURL
    }

    @concurrent
    private func fetchDigitalObjectURL(from visualItemURL: URL) async -> URL? {
        guard let data = try? await httpClient.get(url: visualItemURL),
              let url = await PieceDetailsMapper.mapVisualItem(data: data) else {
            return nil
        }
        return url
    }

    @concurrent
    private func fetchIIIFImageURL(from digitalObjectURL: URL) async -> URL? {
        guard let data = try? await httpClient.get(url: digitalObjectURL),
              let url = await PieceDetailsMapper.mapDigitalObject(data: data) else {
            return nil
        }
        return url
    }
}
