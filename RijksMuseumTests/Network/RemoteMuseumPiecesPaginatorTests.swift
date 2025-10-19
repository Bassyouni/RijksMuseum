//
//  RemoteMuseumPiecesPaginatorTests.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import XCTest
@testable import RijksMuseum

@MainActor
final class RemoteMuseumPiecesPaginatorTests: XCTestCase {
    
    private let env = Environment()
    private let batchCount = 10
    
    func test_loadInitialPieces_throwsUnKnowenOnLoaderFailure() async {
        let sut = makeSUT()
        env.loader.stubbedLoadCollectionURLsResult = .failure(anyError)
        
        do {
            _ = try await sut.loadInitialPieces()
            XCTFail("Expected to receive an error")
        } catch {
            XCTAssertEqual(error, .unknownError)
        }
    }
    
    func test_loadInitialPieces_loadsFirstTenPiecesWithCorrectURLs() async {
        let sut = makeSUT()
        let first10PiecesURLs = makePieces(count: batchCount).map { URL(string: $0.id)! }
        env.loader.stubbedLoadCollectionURLsResult = .success((first10PiecesURLs + [uniqueURL()], nil))
        env.loader.stubbedLoadPieceDetailResults = makePieces(count: batchCount).map { .success($0) }
        
        _ = try? await sut.loadInitialPieces()
        
        XCTAssertEqual(Set(env.loader.loadPieceDetailURLs), Set(first10PiecesURLs))
    }
    
    func test_loadInitialPieces_deliversPiecesOnLoaderSuccess() async throws {
        let sut = makeSUT()
        let first10Pieces = makePieces(count: batchCount)
        let extraPieces = makePieces(count: 1)
        env.loader.stubbedLoadPieceDetailResults = (first10Pieces + extraPieces).map { .success($0) }
        env.loader.stubbedLoadCollectionURLsResult = .success((makeURLs(count: batchCount + 1), nil))
        
        let receivedPieces = try await sut.loadInitialPieces()
        
        XCTAssertEqual(Set(receivedPieces), mapToPieces(first10Pieces))
    }
    
    func test_loadInitialPieces_onLoadingPieceDetailsFailure_skipsModel() async throws {
        let sut = makeSUT()
        let succesPiece = makePieces(count: 1).first!
        env.loader.stubbedLoadPieceDetailResults = [.fail(), .success(succesPiece)]
        env.loader.stubbedLoadCollectionURLsResult = .success((makeURLs(count: 2), nil))
        
        let receivedPieces = try await sut.loadInitialPieces()
        
        XCTAssertEqual(Set(receivedPieces), mapToPieces([succesPiece]))
    }
    
    func test_loadMorePieces_loadsNextTenPiecesWithCorrectURLs() async throws {
        let sut = makeSUT()
        let piecesURLs = makePieces(count: batchCount * 2).map { URL(string: $0.id)! }
        env.loader.stubbedLoadCollectionURLsResult = .success((piecesURLs, nil))
        env.loader.stubbedLoadPieceDetailResults = makePieces(count: batchCount*2).map { .success($0) }
        _ = try? await sut.loadInitialPieces()
        
        XCTAssertEqual(Set(env.loader.loadPieceDetailURLs), Set(piecesURLs.prefix(batchCount)))

        _ = try? await sut.loadMorePieces()
        
        XCTAssertEqual(Set(env.loader.loadPieceDetailURLs), Set(piecesURLs))

    }
    
    func test_loadMorePieces_whenThereIsNoURLsLeft_fetchesNextCollectionWithCorrectPageToken() async throws {
        let sut = makeSUT()
        let nextPageToken = "any"
        env.loader.stubbedLoadCollectionURLsResult = .success(([uniqueURL()], nextPageToken))
        env.loader.stubbedLoadPieceDetailResults = makePieces(count: 1).map { .success($0) }
        _ = try? await sut.loadInitialPieces()

        _ = try? await sut.loadMorePieces()
        
        XCTAssertEqual(env.loader.loadCollectionPageTokens, [nil, nextPageToken])
    }
    
    func test_loadMorePieces_throwsNoMorePiecesWhenNextPageTokenIsNil() async {
        let sut = makeSUT()
        env.loader.stubbedLoadCollectionURLsResult = .success((makeURLs(count: batchCount), nil))
        env.loader.stubbedLoadPieceDetailResults = makePieces(count: batchCount).map { .success($0) }
        _ = try? await sut.loadInitialPieces()
        
        do {
            _ = try await sut.loadMorePieces()
            XCTFail("Expected to receive noMorePieces error")
        } catch  {
            XCTAssertEqual(error, .noMorePieces)
        }
    }
}

private extension RemoteMuseumPiecesPaginatorTests {
    @MainActor
    struct Environment {
        let loader = MuseumPiecesLoaderSpy()
        let policy = LanguageResolutionPolicy()
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> RemoteMuseumPiecesPaginator {
        let sut = RemoteMuseumPiecesPaginator(loader: env.loader, languagePolicy: env.policy)
        checkForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    func givenLoadCollectionURLsIsStubbbed() {
        env.loader.stubbedLoadCollectionURLsResult = .success((makeURLs(count: batchCount + 1), nil))
    }
    
    func makePieces(count: Int) -> [LocalizedPiece] {
        return (1...count).map {
            LocalizedPiece(
                id: "\($0)",
                title: .init([.english: "title \($0)"]),
                date: .init([.dutch: "date \($0)"]),
                creator: .init([.dutch: " dutch creator \($0)", .english: "english creator \($0)"]),
                imageURL: nil
            )
        }
    }
    
    func mapToPieces(_ models: [LocalizedPiece]) -> Set<Piece> {
        Set(models.map {
            Piece(
                id: $0.id,
                title: env.policy.resolve(from: $0.title?.values ?? [:]),
                date: env.policy.resolve(from: $0.date?.values ?? [:]),
                creator: env.policy.resolve(from: $0.creator?.values ?? [:]),
                image: ResizableImage(url: $0.imageURL)
            )
        })
    }
    
    func makeURLs(count: Int) -> [URL] {
        return (1...count).map { _ in
            uniqueURL()
        }
    }
}

private final class MuseumPiecesLoaderSpy: MuseumPiecesLoader {
    private(set) var loadCollectionPageTokens: [String?] = []
    private(set) var loadPieceDetailURLs: [URL] = []
    
    var stubbedLoadCollectionURLsResult: Result<(urls: [URL], nextPageToken: String?), Error> = .fail()
    var stubbedLoadPieceDetailResults = [Result<LocalizedPiece, Error>]()
    
    func loadCollectionURLs(nextPageToken: String?) async throws -> (urls: [URL], nextPageToken: String?) {
        loadCollectionPageTokens.append(nextPageToken)
        
        return try stubbedLoadCollectionURLsResult.get()
    }
    
    func loadPieceDetail(url: URL) async throws -> LocalizedPiece {
        loadPieceDetailURLs.append(url)
        
        guard !stubbedLoadPieceDetailResults.isEmpty else { throw anyError }
        
        return try stubbedLoadPieceDetailResults.removeFirst().get()
    }
}
