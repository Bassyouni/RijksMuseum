//
//  MuseumPiece.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 17/10/2025.
//

import Foundation

struct MuseumPiece: Equatable, Identifiable, Hashable {
    let id: String
    let title: String?
    let date: String?
    let creator: String?
    let image: ResizableImage?
}

struct ResizableImage: Equatable, Hashable {
    private let url: URL?

    init(url: URL?) {
        self.url = url
    }
    
    func imageURL(width: Double, height: Double) -> URL? {
        // TODO: add logic
        return url
    }
}
