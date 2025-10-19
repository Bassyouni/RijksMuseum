//
//  MuseumPiecesPaginator.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

enum PaginationError: Error {
    case noMorePieces
    case unknownError
}

protocol MuseumPiecesPaginator {
    func loadInitialPieces() async throws(PaginationError) -> [Piece]
    func loadMorePieces() async throws(PaginationError) -> [Piece]
}
