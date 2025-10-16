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
    
    func test_fetchCollectionIDs_whePassingNextPageToken_appendsItToURL() async throws {
        let urlString = "www.a-url.com"
        let pageToken = "any-token"
        let sut = makeSUT(url: URL(string: urlString)!)
        
        try await sut.fetchCollectionIDs(nextPageToken: pageToken)
        
        let expectedURL = URL(string: "\(urlString)?pageToken=\(pageToken)")
        XCTAssertEqual(env.client.requestedURLs, [expectedURL])
    }
    
    func test_fetchCollectionIDs_deliversErrorOnError() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .failure(NSError(domain: "test", code: 0))
        
        do  {
            _ = try await sut.fetchCollectionIDs(nextPageToken: nil)
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .networkError)
        }
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
