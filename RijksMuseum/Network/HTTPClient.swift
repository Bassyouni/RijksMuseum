//
//  HTTPClient.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import Foundation

public protocol HTTPClient {
    func get(url: URL) async throws -> Data
}
