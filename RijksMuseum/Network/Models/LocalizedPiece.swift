//
//  LocalizedPiece.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 18/10/2025.
//

import Foundation

enum Language: Equatable {
    case dutch
    case english
    case unknown
}

struct Localized<T: Equatable>: Equatable {
    let values: [Language: T]
    init(_ values: [Language: T]) {
        self.values = values
    }
}

struct LocalizedPiece: Equatable {
    let id: String
    let title: Localized<String>?
    let date: Localized<String>?
    let creator: Localized<String>?
}
