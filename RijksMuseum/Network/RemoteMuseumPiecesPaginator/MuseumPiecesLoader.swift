//
//  MuseumPiecesLoader.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

protocol MuseumPiecesLoader {
    func loadCollectionURLs(nextPageToken: String?) async throws -> (urls: [URL], nextPageToken: String?)
    func loadMuseumPieceDetail(url: URL) async throws -> LocalizedPiece
}
