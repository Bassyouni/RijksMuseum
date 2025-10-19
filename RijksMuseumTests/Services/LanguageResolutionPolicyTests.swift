//
//  LanguageResolutionPolicyTests.swift
//  RijksMuseumTests
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import XCTest
@testable import RijksMuseum

@MainActor
final class LanguageResolutionPolicyTests: XCTestCase {
    func test_resolve_picksDutchAsThePreferdLanguage() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [.unknown: "unknowun", .dutch: "dutch", .english: "english"])
        
        XCTAssertEqual(received, "dutch")
    }
    
    func test_resolve_whenDutchIsNotAvailable_fallsbackOnEnglish() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [.unknown: "unknowun", .english: "english"])
        
        XCTAssertEqual(received, "english")
    }
    
    func test_resolve_whenNeitherThePreffedOrTheFallBackExists_picksUnknown() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [.unknown: "unknowun"])
        
        XCTAssertEqual(received, "unknowun")
    }
    
    func test_resolve_whenNoLanguagesAreProvided_returnsNil() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [Language: String]())
        
        XCTAssertEqual(received, nil)
    }
}

private extension LanguageResolutionPolicyTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> LanguageResolutionPolicy {
        return LanguageResolutionPolicy()
    }
}
