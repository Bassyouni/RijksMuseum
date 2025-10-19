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
        await givenInitalDataLoaded(sut)
        
        env.paginator.stubbedResult = .success([])
        await sut.loadMore()
        
        XCTAssertEqual(env.paginator.loadMorePiecesCallCount, 1)
    }
    
    func test_loadMore_setsIsLoadingMoreDuringOperation() async {
        let sut = makeSUT()
        await givenInitalDataLoaded(sut)
        
        env.paginator.stubbedResult = nil
        async let loadMore: () = sut.loadMore()
        await env.paginator.waitForLoadMorePiecesToStart()
        XCTAssertEqual(sut.isLoadingMore, true)
        
        env.paginator.completeWith([])
        await loadMore
        XCTAssertEqual(sut.isLoadingMore, false)
    }
    
    func test_loadMore_whenNotInLoadedState_doesNothing() async {
        let sut = makeSUT()
        env.paginator.stubbedResult = .success([])
        
        await sut.loadMore()
        
        XCTAssertEqual(env.paginator.loadMorePiecesCallCount, 0)
    }
    
    func test_loadMore_appendsPiecesToExistingLoaded() async {
        let sut = makeSUT()
        let initialPieces = [makePiece(), makePiece()]
        let newPieces = [makePiece(), makePiece()]
        await givenInitalDataLoaded(with: initialPieces, sut)
        
        env.paginator.stubbedResult = .success(newPieces)
        await sut.loadMore()
        
        XCTAssertEqual(sut.viewState, .loaded(initialPieces + newPieces))
    }
    
    func test_loadMore_onLoadMoreError_keepsCurrentStateAndHidesLoading() async {
        let sut = makeSUT()
        let pieces = [makePiece()]
        await givenInitalDataLoaded(with: pieces, sut)
        
        await givenLoadMoreDataLoaded(with: .failure(.unknownError), sut)
        XCTAssertEqual(sut.isLoadingMore, false)
        XCTAssertEqual(sut.viewState, .loaded(pieces))
        
        await givenLoadMoreDataLoaded(with: .failure(.noMorePieces), sut)
        XCTAssertEqual(sut.isLoadingMore, false)
        XCTAssertEqual(sut.viewState, .loaded(pieces))
    }
    
    func test_loadMore_whenHasMorePiecesIsFalse_doesNothing() async {
        let sut = makeSUT()
        await givenInitalDataLoaded(sut)
        await givenLoadMoreDataLoaded(with: .failure(.noMorePieces), sut)
        
        await sut.loadMore()
        
        XCTAssertEqual(env.paginator.loadMorePiecesCallCount, 1)
    }
    
    func test_loadData_resetsHasMorePiecesToTrue() async {
        let sut = makeSUT()
        await givenInitalDataLoaded(sut)
        await givenLoadMoreDataLoaded(with: .failure(.noMorePieces), sut)
        await givenInitalDataLoaded(sut)
        
        env.paginator.stubbedResult = .success([makePiece()])
        await sut.loadMore()
        
        XCTAssertEqual(env.paginator.loadMorePiecesCallCount, 2)
    }
    
    // MARK: - onPieceSelected
    func test_onPieceSelected_whenNotInLoadedState_doesNothing() async {
        let sut = makeSUT()
        
        sut.onPieceSelected(at: 0)
        
        XCTAssertEqual(env.coordinatorSpy.coordinatedPieces, [])
    }
    
    func test_onPieceSelected_whenIndexOutOfBounds_doesNothing() async {
        let sut = makeSUT()
        let pieces = [makePiece()]
        await givenInitalDataLoaded(with: pieces, sut)
        
        sut.onPieceSelected(at: 2)
        
        XCTAssertEqual(env.coordinatorSpy.coordinatedPieces, [])
    }
    
    func test_onPieceSelected_callsCoordinateToDetailsWithSelectedPiece() async {
        let sut = makeSUT()
        let pice1 = makePiece()
        let pice2 = makePiece()
        await givenInitalDataLoaded(with: [pice1, pice2], sut)
        
        sut.onPieceSelected(at: 1)
        XCTAssertEqual(env.coordinatorSpy.coordinatedPieces, [pice2])
        
        sut.onPieceSelected(at: 0)
        XCTAssertEqual(env.coordinatorSpy.coordinatedPieces, [pice2, pice1])
    }
 }

private extension PiecesListViewModelTests {
    struct Environment {
        let paginator = MuseumPiecesPaginatorSpy()
        let coordinatorSpy = CoordinatorSpy()
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> PiecesListViewModel {
        let sut = PiecesListViewModel(
            paginator: env.paginator,
            coordinateToDetails: env.coordinatorSpy.coordinate(piece:)
        )
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
    
    func givenInitalDataLoaded(with data: [Piece]? = nil,_ sut: PiecesListViewModel) async {
        env.paginator.stubbedResult = .success(data ?? [makePiece()])
        await sut.loadData()
    }
    
    func givenLoadMoreDataLoaded(with result: Result<[Piece], PaginationError>,_ sut: PiecesListViewModel) async {
        env.paginator.stubbedResult = result
        await sut.loadMore()
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

final class CoordinatorSpy {
    private(set) var coordinateToDetailsCallCount: Int = 0
    private(set) var coordinatedPieces = [Piece]()
    
    func coordinate(piece: Piece) {
        coordinatedPieces.append(piece)
    }
}
