//
//  PiecesListViewModelTests.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import XCTest
@testable import RijksMuseum

@MainActor
final class PiecesListViewModelTests: XCTestCase {
    private let env = Environment()
    
    func test_loadData_whenCalled_thenFetchData() async throws {
        let sut = makeSUT()
        
        await sut.loadData()
        
        XCTAssertEqual(env.paginator.loadInitialPiecesCallCount, 1)
    }
    
    
}

private extension PiecesListViewModelTests {
    struct Environment {
        let paginator = MuseumPiecesPaginatorSpy()
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> PiecesListViewModel {
        let sut = PiecesListViewModel(paginator: env.paginator)
        checkForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
}

final class MuseumPiecesPaginatorSpy: MuseumPiecesPaginator {
    private(set) var loadInitialPiecesCallCount: Int = 0
    private(set) var loadMorePiecesCallCount: Int = 0
    
    func loadInitialPieces() async throws(PaginationError) -> [Piece] {
        loadInitialPiecesCallCount += 1
        return []
    }
    
    func loadMorePieces() async throws(PaginationError) -> [Piece] {
        loadMorePiecesCallCount += 1
        return []
    }
}
