//
//  PiecesListViewModel.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

enum ViewState: Equatable {
    case loading
    case loaded([Piece])
    case error(String)
}

@Observable
@MainActor
final class PiecesListViewModel {
    private let paginator: MuseumPiecesPaginator
    
    init(paginator: MuseumPiecesPaginator) {
        self.paginator = paginator
    }
    
    func loadData() async {
        _ = try? await paginator.loadInitialPieces()
    }
}
