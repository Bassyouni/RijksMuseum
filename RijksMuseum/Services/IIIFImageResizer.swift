//
//  IIIFImageResizer.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

struct IIIFImageResizer: Equatable, Hashable {
    private let url: URL?

    init(url: URL?) {
        self.url = url
    }
    
    func imageURL(width: Int, height: Int) -> URL? {
        guard let url else { return nil }
        
        return URL(string: url
            .absoluteString
            .replacingOccurrences(of: "/max/", with: "/\(width),\(height)/")
        )
    }
}
