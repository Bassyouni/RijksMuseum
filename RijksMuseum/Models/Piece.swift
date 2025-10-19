//
//  Piece.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 17/10/2025.
//

import Foundation

struct Piece: Equatable, Identifiable, Hashable {
    let id: String
    let title: String?
    let date: String?
    let creator: String?
    let imageURL: URL?
}
