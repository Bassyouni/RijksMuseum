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
    private let dutch = UUID().uuidString
    private let english = UUID().uuidString
    private let unknown = UUID().uuidString
    
    func test_resolve_picksDutchAsThePreferredLanguage() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [.unknown: unknown, .dutch: dutch, .english: english])
        
        XCTAssertEqual(received, dutch)
    }
    
    func test_resolve_whenDutchIsNotAvailable_fallsbackOnEnglish() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [.unknown: unknown, .english: english])
        
        XCTAssertEqual(received, english)
    }
    
    func test_resolve_whenNeitherThePreferredOrTheFallBackExists_picksUnknown() {
        let sut = makeSUT()
        
        let received = sut.resolve(from: [.unknown: unknown])
        
        XCTAssertEqual(received, unknown)
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
