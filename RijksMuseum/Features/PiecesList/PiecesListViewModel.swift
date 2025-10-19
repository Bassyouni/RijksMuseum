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
    private(set) var isLoadingMore = false
    private var hasMorePieces: Bool = true
    
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
    
    func loadMore() async {
        guard case .loaded(let currentPieces) = viewState, hasMorePieces else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let newPieces = try await paginator.loadMorePieces()
            viewState = .loaded(currentPieces + newPieces)
        } catch PaginationError.noMorePieces {
            hasMorePieces = false
        } catch {
            
        }
        
    }
}
