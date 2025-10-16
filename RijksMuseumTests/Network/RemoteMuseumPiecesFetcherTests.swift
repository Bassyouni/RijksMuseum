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
    
    // MARK: - fetchCollectionURLs
    
    func test_fetchCollectionURLs_requestsDataFromURL() async {
        let url = URL(string: "www.a-url.com")
        let sut = makeSUT(url: url!)
        
        _ = try? await sut.fetchCollectionURLs(nextPageToken: nil)
        
        XCTAssertEqual(env.client.requestedURLs, [url])
    }
    
    func test_fetchCollectionURLs_whePassingNextPageToken_appendsItToURL() async {
        let urlString = "www.a-url.com"
        let pageToken = "any-token"
        let sut = makeSUT(url: URL(string: urlString)!)
        
        _ = try? await sut.fetchCollectionURLs(nextPageToken: pageToken)
        
        let expectedURL = URL(string: "\(urlString)?pageToken=\(pageToken)")
        XCTAssertEqual(env.client.requestedURLs, [expectedURL])
    }
    
    func test_fetchCollectionURLs_deliversErrorOnError() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .failure(NSError(domain: "test", code: 0))
        
        do  {
            _ = try await sut.fetchCollectionURLs(nextPageToken: nil)
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .networkError)
        }
    }
    
    func test_fetchCollectionURLs_deliversErrorOnResponseWithInvalidJson() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .success(Data("".utf8))
        
        do  {
            _ = try await sut.fetchCollectionURLs(nextPageToken: nil)
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .invalidData)
        }
    }
    
    func test_fetchCollectionURLs_deliversURLsOnHttpResponseWithValidJsonObject() async throws {
        let sut = makeSUT()
        let urls = [uniqueURL(), uniqueURL()]
        let jsonData = makeCollectionResponse(urls: urls.map(\.absoluteString))
        env.client.stubbedGetResult = .success(jsonData)
        
        let (receivedURLs, _) = try await sut.fetchCollectionURLs(nextPageToken: nil)
        
        XCTAssertEqual(receivedURLs, urls)
    }
    
    func test_fetchCollectionURLs_deliversNextPageTokenOnHttpResponseWithValidJsonObject() async throws {
        let sut = makeSUT()
        let nextPageToken = "any token"
        let jsonData = makeCollectionResponse(urls: [], nextPageToken: nextPageToken)
        env.client.stubbedGetResult = .success(jsonData)
        
        let (_, receivedPageToken) = try await sut.fetchCollectionURLs(nextPageToken: nil)
        
        XCTAssertEqual(receivedPageToken, nextPageToken)
    }
    
    // MARK: - fetchMuseumPieceDetail
    
    func test_fetchMuseumPieceDetail_requestsDataFromURL() async {
        let pieceDetailURL = uniqueURL()
        let sut = makeSUT(url: uniqueURL())
        
        _ = try? await sut.fetchMuseumPieceDetail(url: pieceDetailURL)
        
        XCTAssertEqual(env.client.requestedURLs, [pieceDetailURL])
    }
    
    func test_fetchMuseumPieceDetail_deliversErrorOnError() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .failure(NSError(domain: "test", code: 0))
        
        do  {
            _ = try await sut.fetchMuseumPieceDetail(url: uniqueURL())
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .networkError)
        }
    }
    
    func test_fetchMuseumPieceDetail_deliversErrorOnResponseWithInvalidJson() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .success(Data("".utf8))
        
        do  {
            _ = try await sut.fetchMuseumPieceDetail(url: uniqueURL())
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .invalidData)
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
    
    private func makeCollectionResponse(
        urls: [String],
        nextPageToken: String = "any-token"
    ) -> Data {
        let orderedItems = urls.map { ["id": $0] }
        
        let json: [String: Any] = [
            "orderedItems": orderedItems,
            "next": [
                "id":"https://data.rijksmuseum.nl/search/collection?pageToken=\(nextPageToken)"
            ]
        ]
        
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    func uniqueURL() -> URL {
        URL(string:  "www.\(UUID().uuidString).nl")!
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
