//
//  XCTestCaseExtensions.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import XCTest
@testable import RijksMuseum

extension XCTestCase {
    func checkForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Potential memory leak for instance", file: file, line: line)
        }
    }
    
    func uniqueURL() -> URL {
        URL(string: "www.\(UUID().uuidString).nl")!
    }
    
    func makePiece() -> Piece {
        Piece(
            id: UUID().uuidString,
            title: nil,
            date: nil,
            creator: nil,
            imageURL: nil
        )
    }
}

var anyError: NSError {
    NSError(domain: "test", code: 0)
}
