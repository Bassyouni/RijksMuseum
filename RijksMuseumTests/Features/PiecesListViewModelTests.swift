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
    
    func test_loadData_requestsInitialPiecesFromPaginator() async throws {
        let sut = makeSUT()
        
        await sut.loadData()
        
        XCTAssertEqual(env.paginator.loadInitialPiecesCallCount, 1)
    }
    
    func test_loadData_whenPaginatorFails_showsError() async throws {
        let sut = makeSUT()
        env.paginator.needToControlState = true
        
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
        env.paginator.needToControlState = true
        
        async let loadData: () = sut.loadData()
        await env.paginator.waitForLoadInitalPiecesToStart()
        XCTAssertEqual(sut.viewState, .loading)
        
        env.paginator.completeWith(pieces)
        await loadData
        XCTAssertEqual(sut.viewState, .loaded(pieces))
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
    
    private func makePiece() -> Piece {
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
    
    var needToControlState: Bool = false
    private var continuation: CheckedContinuation<[Piece], Error>?
    private var stubbedLoadInitliaPieces: Result<[Piece], PaginationError> = .success([])
    
    func loadInitialPieces() async throws(PaginationError) -> [Piece] {
        loadInitialPiecesCallCount += 1
        
        guard needToControlState else {
            return try stubbedLoadInitliaPieces.get()
        }
        
        return try await returnContinuation()
    }
    
    func loadMorePieces() async throws(PaginationError) -> [Piece] {
        loadMorePiecesCallCount += 1
        
        guard needToControlState else {
            return try stubbedLoadInitliaPieces.get()
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
    
    func completeWith(_ value: [Piece]) {
        continuation?.resume(returning: value)
    }
    
    func completeWith(_ error: PaginationError) {
        continuation?.resume(throwing: error)
    }
}
