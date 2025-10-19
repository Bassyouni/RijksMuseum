//
//  PiecesListViewModel.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

enum ViewState: Equatable {
    case idle
    case loading
    case loaded([Piece])
    case error(String)
}

@Observable
@MainActor
final class PiecesListViewModel {
    
    private let paginator: MuseumPiecesPaginator
    private(set) var viewState: ViewState = .idle
    
    init(paginator: MuseumPiecesPaginator) {
        self.paginator = paginator
    }
    
    func loadData() async {
        viewState = .loading
        do {
            let pieces = try await paginator.loadInitialPieces()
            viewState = .loaded(pieces)
        } catch {
            viewState = .error("Something went wrong")
        }
    }
}
