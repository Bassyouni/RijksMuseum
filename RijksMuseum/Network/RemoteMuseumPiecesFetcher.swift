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
    func fetchMuseumPieceDetail(url: URL) async throws(Error) -> LocalizedPiece {
        guard let data = try? await httpClient.get(url: url) else {
            throw .networkError
        }

        let mapper = PieceDetailsMapper()
        let (piece, visualItemURL) = try await mapper.map(data: data).get()
        let imageURL = await fetchImageURL(from: visualItemURL, mapper: mapper)

        return LocalizedPiece(
            id: piece.id,
            title: piece.title,
            date: piece.date,
            creator: piece.creator,
            imageURL: imageURL
        )
    }

    private func fetchImageURL(from visualItemURL: URL?, mapper: PieceDetailsMapper) async -> URL? {
        guard let visualItemURL = visualItemURL else { return nil }
        guard let digitalObjectURL = await fetchDigitalObjectURL(from: visualItemURL, mapper: mapper) else { return nil }
        guard let iiifURL = await fetchIIIFImageURL(from: digitalObjectURL, mapper: mapper) else { return nil }
        return iiifURL
    }

    private func fetchDigitalObjectURL(from visualItemURL: URL, mapper: PieceDetailsMapper) async -> URL? {
        guard let data = try? await httpClient.get(url: visualItemURL),
              let url = mapper.mapVisualItem(data: data) else {
            return nil
        }
        return url
    }

    private func fetchIIIFImageURL(from digitalObjectURL: URL, mapper: PieceDetailsMapper) async -> URL? {
        guard let data = try? await httpClient.get(url: digitalObjectURL),
              let url = mapper.mapDigitalObject(data: data) else {
            return nil
        }
        return url
    }
}
