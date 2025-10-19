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
    
    func test_loadInitialPieces_throwsOnLoaderFailure() async {
        let sut = makeSUT()
        env.loader.stubbedLoadCollectionURLsResult = .failure(anyError)
        
        do {
            _ = try await sut.loadInitialPieces()
            XCTFail("Expected to receive an error")
        } catch {
            XCTAssertEqual(error as NSError, anyError)
        }
    }
    
    func test_loadInitialPieces_loadsFirstTenPiecesWithCorrectURLs() async {
        let sut = makeSUT()
        let first10PiecesURLs = makePieces(count: batchCount).map { URL(string: $0.id)! }
        env.loader.stubbedLoadCollectionURLsResult = .success((first10PiecesURLs + [uniqueURL()], nil))
        env.loader.stubbedLoadMuseumPieceDetailResults = (makePieces(count: batchCount)).map { .success($0) }
        
        _ = try? await sut.loadInitialPieces()
        
        XCTAssertEqual(env.loader.loadPieceDetailURLs, first10PiecesURLs)
    }
    
    func test_loadInitialPieces_deliversPiecesOnLoaderSuccess() async throws {
        let sut = makeSUT()
        let first10Pieces = makePieces(count: batchCount)
        let extraPieces = makePieces(count: 1)
        env.loader.stubbedLoadMuseumPieceDetailResults = (first10Pieces + extraPieces).map { .success($0) }
        env.loader.stubbedLoadCollectionURLsResult = .success((makeURLs(count: batchCount + 1), nil))
        
        let receivedPieces = try await sut.loadInitialPieces()
        
        XCTAssertEqual(receivedPieces, first10Pieces.mapToPieces())
    }
    
}

private extension RemoteMuseumPiecesPaginatorTests {
    struct Environment {
        let loader = MuseumPiecesLoaderSpy()
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> RemoteMuseumPiecesPaginator {
        let sut = RemoteMuseumPiecesPaginator(loader: env.loader)
        checkForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makePieces(count: Int) -> [LocalizedPiece] {
        return (1...count).map {
            LocalizedPiece(id: "\($0)", title: nil, date: nil, creator: nil, imageURL: nil)
        }
    }
    
    func makeURLs(count: Int) -> [URL] {
        return (1...count).map { _ in
            uniqueURL()
        }
    }
}

private final class MuseumPiecesLoaderSpy: MuseumPiecesLoader {
    private(set) var loadCollectionURLs: [String?] = []
    private(set) var loadPieceDetailURLs: [URL] = []
    
    var stubbedLoadCollectionURLsResult: Result<(urls: [URL], nextPageToken: String?), Error> = .fail()
    var stubbedLoadMuseumPieceDetailResults = [Result<LocalizedPiece, Error>]()
    
    func loadCollectionURLs(nextPageToken: String?) async throws -> (urls: [URL], nextPageToken: String?) {
        loadCollectionURLs.append(nextPageToken)
        
        return try stubbedLoadCollectionURLsResult.get()
    }
    
    func loadMuseumPieceDetail(url: URL) async throws -> LocalizedPiece {
        loadPieceDetailURLs.append(url)
        
        guard !stubbedLoadMuseumPieceDetailResults.isEmpty else { throw anyError }
        
        return try stubbedLoadMuseumPieceDetailResults.removeFirst().get()
    }
}

private extension Array where Element == LocalizedPiece {
    func mapToPieces() -> [MuseumPiece] {
        self.map {
            MuseumPiece(
                id: $0.id,
                title: $0.title?.firstValue,
                date: $0.date?.firstValue,
                creator: $0.creator?.firstValue,
                image: ResizableImage(url: $0.imageURL)
            )
        }
    }
}
