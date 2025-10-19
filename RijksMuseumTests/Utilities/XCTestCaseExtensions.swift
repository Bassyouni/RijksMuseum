//
//  XCTestCaseExtensions.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import XCTest

extension XCTestCase {
    func checkForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Potential memory leak for instance", file: file, line: line)
        }
    }
    
    func uniqueURL() -> URL {
        URL(string: "www.\(UUID().uuidString).nl")!
    }
}

var anyError: Error {
    NSError(domain: "test", code: 0)
}
