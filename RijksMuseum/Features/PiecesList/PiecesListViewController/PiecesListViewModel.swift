//
//  PiecesListViewModel.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

@Observable
@MainActor
final class PiecesListViewModel {
    
    private(set) var viewState: ViewState = .idle
    
    private(set) var isLoadingMore = false
    private var hasMorePieces: Bool = true
    
    private let coordinateToDetails: (Piece) -> Void
    private let paginator: MuseumPiecesPaginator
    
    init(paginator: MuseumPiecesPaginator, coordinateToDetails: @escaping (Piece) -> Void) {
        self.paginator = paginator
        self.coordinateToDetails = coordinateToDetails
    }
    
    func loadData() async {
        viewState = .loading
        hasMorePieces = true
        
        do {
            let pieces = try await paginator.loadInitialPieces()
            viewState = .loaded(pieces)
        } catch {
            viewState = .error("Something went wrong")
        }
    }
    
    func loadMore() async {
        guard case .loaded(let currentPieces) = viewState, hasMorePieces else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let newPieces = try await paginator.loadMorePieces()
            viewState = .loaded(currentPieces + newPieces)
        } catch {
            guard case .noMorePieces = error else { return }
            hasMorePieces = false
        }
    }
    
    func onPieceSelected(at index: Int) {
        guard case .loaded(let pieces) = viewState, index < pieces.count  else { return }
        
        coordinateToDetails(pieces[index])
    }
}
