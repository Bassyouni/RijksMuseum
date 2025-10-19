//
//  ResizableImageURL.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

struct ResizableImageURL: Equatable, Hashable {
    private let url: URL?

    init(url: URL?) {
        self.url = url
    }
    
    func imageURL(width: Double, height: Double) -> URL? {
        return url
    }
}
