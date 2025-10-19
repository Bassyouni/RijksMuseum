//
//  LanguageResolutionPolicy.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

struct LanguageResolutionPolicy {
    
    private let prefferdLanguages = [Language.dutch, .english, .unknown]
    
    func resolve(from languages: [Language: String]) -> String {
        return "dutch"
    }
}
