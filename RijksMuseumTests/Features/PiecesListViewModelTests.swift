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
    
    // MARK: - loadData
    func test_loadData_requestsInitialPiecesFromPaginator() async throws {
        let sut = makeSUT()
        env.paginator.stubbedResult = .success([])
        
        await sut.loadData()
        
        XCTAssertEqual(env.paginator.loadInitialPiecesCallCount, 1)
    }
    
    func test_loadData_whenPaginatorFails_viewStateIsError() async throws {
        let sut = makeSUT()
        
        async let loadData: () = sut.loadData()
        await env.paginator.waitForLoadInitalPiecesToStart()
        XCTAssertEqual(sut.viewState, .loading)
        
        env.paginator.completeWith(.unknownError)
        await loadData
        XCTAssertEqual(sut.viewState, .error("Something went wrong"))
    }
    
    func test_loadData_onPagiantorSucess_viewStateIsLoadedWithData() async throws {
        let sut = makeSUT()
        let pieces = [makePiece(), makePiece()]
        
        async let loadData: () = sut.loadData()
        await env.paginator.waitForLoadInitalPiecesToStart()
        XCTAssertEqual(sut.viewState, .loading)
        
        env.paginator.completeWith(pieces)
        await loadData
        XCTAssertEqual(sut.viewState, .loaded(pieces))
    }
    
    // MARK: - loadMore
    func test_loadMore_requestsMorePiecesFromPaginator() async {
        let sut = makeSUT()
        env.paginator.stubbedResult = .success([makePiece()])
        await sut.loadData()
        
        env.paginator.stubbedResult = .success([])
        await sut.loadMore()
        
        XCTAssertEqual(env.paginator.loadMorePiecesCallCount, 1)
    }
    
    func test_loadMore_setsIsLoadingMoreDuringOperation() async {
        let sut = makeSUT()
        env.paginator.stubbedResult = .success([makePiece()])
        await sut.loadData()
        
        env.paginator.stubbedResult = nil
        async let loadMore: () = sut.loadMore()
        await env.paginator.waitForLoadMorePiecesToStart()
        XCTAssertEqual(sut.isLoadingMore, true)
        
        env.paginator.completeWith([])
        await loadMore
        XCTAssertEqual(sut.isLoadingMore, false)
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
    
    func makePiece() -> Piece {
        Piece(
            id: UUID().uuidString,
            title: nil,
            date: nil,
            creator: nil,
            image: nil
        )
    }
}

final class MuseumPiecesPaginatorSpy: MuseumPiecesPaginator {
    private(set) var loadInitialPiecesCallCount: Int = 0
    private(set) var loadMorePiecesCallCount: Int = 0
    
    var stubbedResult: Result<[Piece], PaginationError>?
    private var continuation: CheckedContinuation<[Piece], Error>?
    
    func loadInitialPieces() async throws(PaginationError) -> [Piece] {
        loadInitialPiecesCallCount += 1
        
        if let stubbedResult = stubbedResult {
            return try stubbedResult.get()
        }
        
        return try await returnContinuation()
    }
    
    func loadMorePieces() async throws(PaginationError) -> [Piece] {
        loadMorePiecesCallCount += 1
        
        if let stubbedResult = stubbedResult {
            return try stubbedResult.get()
        }
        
        return try await returnContinuation()
    }
    
    private func returnContinuation() async throws(PaginationError) -> [Piece]   {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
        catch { throw error as! PaginationError }
    }
    
    func waitForLoadInitalPiecesToStart() async {
        while loadInitialPiecesCallCount == 0 {
            await Task.yield()
        }
    }
    
    func waitForLoadMorePiecesToStart() async {
        while loadMorePiecesCallCount == 0 {
            await Task.yield()
        }
    }
    
    func completeWith(_ value: [Piece]) {
        continuation?.resume(returning: value)
    }
    
    func completeWith(_ error: PaginationError) {
        continuation?.resume(throwing: error)
    }
}
