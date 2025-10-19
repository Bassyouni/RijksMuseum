//
//  IIIFImageResizerTests.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import XCTest
@testable import RijksMuseum

@MainActor
final class IIIFImageResizerTests: XCTestCase {
    func test_imageURL_replacesMaxKeywordWithSize() {
        let url = "https://iiif.micr.io/qcYVp/full/max/0/default.jpg"
        let sut = makeSUT(url: url)
        
        let newURL = sut.imageURL(width: 200, height: 300)
        
        let expectedURL = URL(string: "https://iiif.micr.io/qcYVp/full/200,300/0/default.jpg")
        XCTAssertEqual(newURL, expectedURL)
    }
}

private extension IIIFImageResizerTests {
    func makeSUT(url: String? = nil, file: StaticString = #file, line: UInt = #line) -> IIIFImageResizer {
        return IIIFImageResizer(url: URL(string: url ?? ""))
    }
}
