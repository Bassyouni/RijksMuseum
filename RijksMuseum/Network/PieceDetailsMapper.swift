//
//  PieceDetailsMapper.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 18/10/2025.
//

import Foundation

final class PieceDetailsMapper {
    
    private struct Root: Codable, Identifiable {
        let id: String
        let identifiedBy: [LocalizedContent]?
        let producedBy: ProducedBy?

        struct ProducedBy: Codable {
            let timespan: Timespan?
            let referredToBy: [LocalizedContent]?

            struct Timespan: Codable {
                let identifiedBy: [LocalizedContent]?

                enum CodingKeys: String, CodingKey {
                    case identifiedBy = "identified_by"
                }
            }

            enum CodingKeys: String, CodingKey {
                case timespan
                case referredToBy = "referred_to_by"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case identifiedBy = "identified_by"
            case producedBy = "produced_by"
        }
    }

    private struct LocalizedContent: Codable {
        let type: String
        let content: String?
        let language: [LanguageReference]?

        struct LanguageReference: Codable {
            let id: String
        }

        var detectedLanguage: LanguageDTO {
            guard let code = language?.first?.id else { return .other }
            
            return LanguageDTO.from(code: code)
        }
    }

    private enum LanguageDTO: String, CaseIterable {
        case dutch = "http://vocab.getty.edu/aat/300388256"
        case english = "http://vocab.getty.edu/aat/300388277"
        case other = "unknown"
        
        static func from(code: String) -> LanguageDTO {
            return LanguageDTO(rawValue: code) ?? .other
        }
        
        var languge: Language {
            switch self {
            case .dutch: return .dutch
            case .english: return .english
            case .other: return .unknown
            }
        }
    }
    
    func map(data: Data) -> Result<(LocalizedPiece), RemoteMuseumPiecesFetcher.Error> {
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteMuseumPiecesFetcher.Error.invalidData)
        }

        let localizedTitle = extractLocalized(from: root.identifiedBy, ofType: "Name")
        let localizedDate = extractLocalized(from: root.producedBy?.timespan?.identifiedBy, ofType: "Name")
        let localizedCreator = extractLocalized(from: root.producedBy?.referredToBy, ofType: "LinguisticObject")

        return .success(LocalizedPiece(id: root.id, title: localizedTitle, date: localizedDate, creator: localizedCreator))
    }

    private func extractLocalized(from items: [LocalizedContent]?, ofType type: String) -> Localized<String>? {
        let mappedItems = items?
            .filter { $0.type == type }
            .compactMap { item -> (Language, String)? in
                guard let content = item.content, !content.isEmpty else { return nil }

                return (item.detectedLanguage.languge, content)
            }

        let dict = Dictionary(mappedItems ?? [], uniquingKeysWith: { first, _ in first })
        return dict.isEmpty ? nil : Localized(dict)
    }
}
