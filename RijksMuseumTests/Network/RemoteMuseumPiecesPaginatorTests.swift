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
    
    func test_loadInitialPieces_loadsFirstTenPiecesWithCorrectURLs() async {
        let sut = makeSUT()
        let first10PiecesURLs = makePieces(count: 10).map { URL(string: $0.id)! }
        env.loader.stubbedLoadCollectionURLsResult = .success((first10PiecesURLs + [uniqueURL()], nil))
        env.loader.stubbedLoadMuseumPieceDetailResults = (makePieces(count: 10)).map { .success($0) }
        
        _ = try? await sut.loadInitialPieces()
        
        XCTAssertEqual(env.loader.loadPieceDetailURLs, first10PiecesURLs)
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
        return (1...10).map {
            LocalizedPiece(id: "\($0)", title: nil, date: nil, creator: nil, imageURL: nil)
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
