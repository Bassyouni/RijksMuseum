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
        let url = URL(string: "https://iiif.micr.io/qcYVp/full/max/0/default.jpg")!
        let sut = makeSUT()
        
        let newURL = sut.newImageURL(from: url, width: 200, height: 300)
        
        let expectedURL = URL(string: "https://iiif.micr.io/qcYVp/full/200,300/0/default.jpg")
        XCTAssertEqual(newURL, expectedURL)
    }
}

private extension IIIFImageResizerTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> IIIFImageResizer {
        return IIIFImageResizer()
    }
}
