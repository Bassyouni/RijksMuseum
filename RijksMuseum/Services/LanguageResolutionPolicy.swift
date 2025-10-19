//
//  LanguageResolutionPolicy.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

struct LanguageResolutionPolicy {
    
    private let preferredLanguages = [Language.dutch, .english, .unknown]
    
    func resolve<T>(from languages: [Language: T]) -> T? {
        for preferredLanguage in preferredLanguages {
            if let value = languages[preferredLanguage] {
                return value
            }
        }
        return languages.values.first
    }
}
