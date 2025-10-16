//
//  RemoteMuseumPiecesFetcherTests.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import XCTest
@testable import RijksMuseum

final class RemoteMuseumPiecesFetcherTests: XCTestCase {
    private let env = Environment()
    
    func test_fetchCollectionIDs_requestsDataFromURL() async throws {
        let url = URL(string: "www.a-url.com")
        let sut = makeSUT(url: url!)
        
        try await sut.fetchCollectionIDs(nextPageToken: nil)
        
        XCTAssertEqual(env.client.requestedURLs, [url])
    }
}

extension RemoteMuseumPiecesFetcherTests {
    private struct Environment {
        let client = HTTPClientSpy()
    }
    
    private func makeSUT(url: URL = URL(string: "www.a-url.com")!, file: StaticString = #file, line: UInt = #line) -> RemoteMuseumPiecesFetcher {
        let sut = RemoteMuseumPiecesFetcher(url: url, httpClient: env.client)
        checkForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

private final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs = [URL]()
    var stubbedGetResult: Result<Data, Error> = .success(Data())
    
    func get(url: URL) async throws -> Data {
        requestedURLs.append(url)
        return try stubbedGetResult.get()
    }
}
