//
//  RemoteMuseumPiecesLoaderTests.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import XCTest
@testable import RijksMuseum

@MainActor
final class RemoteMuseumPiecesLoaderTests: XCTestCase {
    private let env = Environment()
    
    // MARK: - loadCollectionURLs
    
    func test_loadCollectionURLs_requestsDataFromURL() async {
        let url = URL(string: "www.a-url.com")
        let sut = makeSUT(url: url!)
        
        _ = try? await sut.loadCollectionURLs(nextPageToken: nil)
        
        XCTAssertEqual(env.client.requestedURLs, [url])
    }
    
    func test_loadCollectionURLs_whenPassingNextPageToken_appendsItToURL() async {
        let urlString = "www.a-url.com"
        let pageToken = "any-token"
        let sut = makeSUT(url: URL(string: urlString)!)
        
        _ = try? await sut.loadCollectionURLs(nextPageToken: pageToken)
        
        let expectedURL = URL(string: "\(urlString)?pageToken=\(pageToken)")
        XCTAssertEqual(env.client.requestedURLs, [expectedURL])
    }
    
    func test_loadCollectionURLs_deliversErrorOnError() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .fail()
        
        do  {
            _ = try await sut.loadCollectionURLs(nextPageToken: nil)
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .networkError)
        }
    }
    
    func test_loadCollectionURLs_deliversErrorOnResponseWithInvalidJson() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .success(Data("".utf8))
        
        do  {
            _ = try await sut.loadCollectionURLs(nextPageToken: nil)
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .invalidData)
        }
    }
    
    func test_loadCollectionURLs_deliversURLsOnValidResponse() async throws {
        let sut = makeSUT()
        let urls = [uniqueURL(), uniqueURL()]
        let jsonData = makeCollectionResponse(urls: urls.map(\.absoluteString))
        env.client.stubbedGetResult = .success(jsonData)
        
        let (receivedURLs, _) = try await sut.loadCollectionURLs(nextPageToken: nil)
        
        XCTAssertEqual(receivedURLs, urls)
    }
    
    func test_loadCollectionURLs_deliversNextPageTokenOnValidResponse() async throws {
        let sut = makeSUT()
        let nextPageToken = "any token"
        let jsonData = makeCollectionResponse(urls: [], nextPageToken: nextPageToken)
        env.client.stubbedGetResult = .success(jsonData)
        
        let (_, receivedPageToken) = try await sut.loadCollectionURLs(nextPageToken: nil)
        
        XCTAssertEqual(receivedPageToken, nextPageToken)
    }
    
    // MARK: - loadMuseumPieceDetail
    
    func test_loadMuseumPieceDetail_requestsDataFromURL() async {
        let pieceDetailURL = uniqueURL()
        let sut = makeSUT(url: uniqueURL())
        
        _ = try? await sut.loadMuseumPieceDetail(url: pieceDetailURL)
        
        XCTAssertEqual(env.client.requestedURLs, [pieceDetailURL])
    }
    
    func test_loadMuseumPieceDetail_deliversErrorOnError() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .fail()
        
        do  {
            _ = try await sut.loadMuseumPieceDetail(url: uniqueURL())
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .networkError)
        }
    }
    
    func test_loadMuseumPieceDetail_deliversErrorOnResponseWithInvalidJson() async {
        let sut = makeSUT()
        env.client.stubbedGetResult = .success(Data("".utf8))
        
        do  {
            _ = try await sut.loadMuseumPieceDetail(url: uniqueURL())
            XCTFail("Expected load places to throw on error")
        } catch {
            XCTAssertEqual(error, .invalidData)
        }
    }
    
    func test_loadMuseumPieceDetail_deliversLocalizedTitleOnValidResponse() async throws {
        let sut = makeSUT()
        let (model, json) = makeObjectDetailsResponse(
            dutchTitle: "some dutch text",
            englishTitle: "some english text",
            otherTitle: "some"
        )
    
        env.client.stubbedGetResult = .success(json)
        
        let receivedModel = try await sut.loadMuseumPieceDetail(url: uniqueURL())
        
        XCTAssertEqual(receivedModel, model)
    }
    
    func test_loadMuseumPieceDetail_deliversLocalizedDateOnValidResponse() async throws {
        let sut = makeSUT()
        let (model, json) = makeObjectDetailsResponse(
            dutchDate: "any dutch date",
            englishDate: "any english date",
            otherDate: "any"
        )
    
        env.client.stubbedGetResult = .success(json)
        
        let receivedModel = try await sut.loadMuseumPieceDetail(url: uniqueURL())
        
        XCTAssertEqual(receivedModel, model)
    }
    
    func test_loadMuseumPieceDetail_deliversLocalizedCreatorOnValidResponse() async throws {
        let sut = makeSUT()
        let (model, json) = makeObjectDetailsResponse(
            dutchCreator: "any dutch",
            englishCreator: "any english",
            otherCreator: "any other"
        )
    
        env.client.stubbedGetResult = .success(json)
        
        let receivedModel = try await sut.loadMuseumPieceDetail(url: uniqueURL())
        
        XCTAssertEqual(receivedModel, model)
    }
    
    func test_loadMuseumPieceDetail_requestsImageURLsInCorrectSequence() async {
        let sut = makeSUT()
        let pieceDetailURL = uniqueURL()
        let visualItemURL = uniqueURL()
        let digitalObjectURL = uniqueURL()
        
        env.client.stubbedGetResults = [
            .success(makeObjectDetailsResponse(visualItemURL: visualItemURL).json),
            .success(makeVisualItemJSON(digitalObjectURL: digitalObjectURL)),
            .success(makeDigitalObjectJSON(iiifURL: uniqueURL()))
        ]

        _ = try? await sut.loadMuseumPieceDetail(url: pieceDetailURL)

        XCTAssertEqual(env.client.requestedURLs, [pieceDetailURL, visualItemURL, digitalObjectURL])
    }

    func test_loadMuseumPieceDetail_deliversIIIFImageURLOnValidResponse() async throws {
        let sut = makeSUT()
        let iiifImageURL = uniqueURL()
        let digitalObjectJSON = makeDigitalObjectJSON(iiifURL: iiifImageURL)

        env.client.stubbedGetResults = [
            .success(makeObjectDetailsResponse(visualItemURL: uniqueURL()).json),
            .success(makeVisualItemJSON(digitalObjectURL: uniqueURL())),
            .success(digitalObjectJSON)
        ]

        let receivedModel = try await sut.loadMuseumPieceDetail(url: uniqueURL())

        XCTAssertEqual(receivedModel.imageURL, iiifImageURL)
    }
}

private extension RemoteMuseumPiecesLoaderTests {
    struct Environment {
        let client = HTTPClientSpy()
    }
    
    func makeSUT(url: URL = URL(string: "www.a-url.com")!, file: StaticString = #file, line: UInt = #line) -> RemoteMuseumPiecesLoader {
        let sut = RemoteMuseumPiecesLoader(url: url, httpClient: self.env.client)
        checkForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makeCollectionResponse(
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

    func makeObjectDetailsResponse(
        id: String = UUID().uuidString,
        dutchTitle: String? = nil,
        englishTitle: String? = nil,
        otherTitle: String? = nil,
        dutchDate: String? = nil,
        englishDate: String? = nil,
        otherDate: String? = nil,
        dutchCreator: String? = nil,
        englishCreator: String? = nil,
        otherCreator: String? = nil,
        visualItemURL: URL? = nil
    ) -> (model: LocalizedPiece, json: Data) {
        let dutchLanguageID = "http://vocab.getty.edu/aat/300388256"
        let englishLanguageID = "http://vocab.getty.edu/aat/300388277"
        
        let titles = [
            makeItem(content: englishTitle, type: "Name", languageID: englishLanguageID),
            makeItem(content: otherTitle, type: "Name", languageID: nil),
            makeItem(content: dutchTitle, type: "Name", languageID: dutchLanguageID)
        ].compactMap { $0 }
        
        let dates = [
            makeItem(content: englishDate, type: "Name", languageID: englishLanguageID),
            makeItem(content: otherDate, type: "Name", languageID: nil),
            makeItem(content: dutchDate, type: "Name", languageID: dutchLanguageID)
        ].compactMap { $0 }
        
        let creators = [
            makeItem(content: englishCreator, type: "LinguisticObject", languageID: englishLanguageID),
            makeItem(content: otherCreator, type: "LinguisticObject", languageID: nil),
            makeItem(content: dutchCreator, type: "LinguisticObject", languageID: dutchLanguageID)
        ].compactMap { $0 }
        
        var json: [String: Any] = [
            "id": id,
            "identified_by": titles,
            "produced_by": [
                "timespan": [
                    "identified_by": dates
                ],
                "referred_to_by": creators
            ]
        ]
        
        if let url = visualItemURL {
            json["shows"] = [[
                    "id": url.absoluteString,
                    "type": "VisualItem"
                ]]
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        
        let model = LocalizedPiece(
            id: id,
            title: makeLocalizedModel(dutch: dutchTitle, english: englishTitle, other: otherTitle),
            date: makeLocalizedModel(dutch: dutchDate, english: englishDate, other: otherDate),
            creator: makeLocalizedModel(dutch: dutchCreator, english: englishCreator, other: otherCreator),
            imageURL: nil
        )
        
        return (model, jsonData)
    }
    
    func makeLocalizedModel(
        dutch: String?,
        english: String?,
        other: String?,
    ) -> Localized<String>? {
        var dict: [Language: String] = [:]
        if let dutch { dict[.dutch] = dutch }
        if let english { dict[.english] = english }
        if let other { dict[.unknown] = other }
        return dict.isEmpty ? nil : .init(dict)
    }
    
    func makeItem(content: String?, type: String, languageID: String?) -> [String: Any]? {
        guard let content = content else { return nil }

        return [
            "type": type,
            "content": content,
            "language": [["id": languageID ?? "any", "type": "Language"]]
        ]
    }

    func makeVisualItemJSON(digitalObjectURL: URL) -> Data {
        let json: [String: Any] = [
            "digitally_shown_by": [
                ["id": digitalObjectURL.absoluteString]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func makeDigitalObjectJSON(iiifURL: URL) -> Data {
        let json: [String: Any] = [
            "access_point": [
                ["id": iiifURL.absoluteString]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}

private final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs = [URL]()
    var stubbedGetResults: [Result<Data, Error>] = []
    var stubbedGetResult: Result<Data, Error> {
        set { stubbedGetResults.append(newValue) }
        get { stubbedGetResults.first! }
    }
    
    func get(url: URL) async throws -> Data {
        requestedURLs.append(url)
        
        guard !stubbedGetResults.isEmpty else { return Data() }
        
        return try stubbedGetResults.removeFirst().get()
    }
}
