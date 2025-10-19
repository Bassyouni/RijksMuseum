//
//  LanguageResolutionPolicy.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

struct LanguageResolutionPolicy {
    
    private let prefferdLanguages = [Language.dutch, .english, .unknown]
    
    func resolve<T>(from languages: [Language: T]) -> T {
        for preferredLang in prefferdLanguages {
            if let value = languages[preferredLang] {
                return value
            }
        }
        return languages.values.first!
    }
}
