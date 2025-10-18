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

            struct Timespan: Codable {
                let identifiedBy: [LocalizedContent]?

                enum CodingKeys: String, CodingKey {
                    case identifiedBy = "identified_by"
                }
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

            var languageCode: LanguageDTO {
                LanguageDTO.from(code: id)
            }
        }

        var detectedLanguage: LanguageDTO {
            language?.first?.languageCode ?? .other
        }
    }

    private enum LanguageDTO: String, CaseIterable {
        case dutch = "http://vocab.getty.edu/aat/300388256"
        case english = "http://vocab.getty.edu/aat/300388277"
        case other = "unknown"
        
        static func from(code: String) -> LanguageDTO {
            return LanguageDTO(rawValue: code) ?? .other
        }
    }
    
    
    func map(data: Data) -> Result<(LocalizedPiece), RemoteMuseumPiecesFetcher.Error> {
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteMuseumPiecesFetcher.Error.invalidData)
        }

        let titles = root.identifiedBy?
            .filter { $0.type == "Name" }
            .compactMap { item -> (Language, String)? in
                guard let content = item.content, !content.isEmpty else { return nil }

                let language: Language
                switch item.detectedLanguage {
                case .dutch:
                    language = .dutch
                case .english:
                    language = .english
                case .other:
                    language = .unknown
                }

                return (language, content)
            }

        let titleDict = Dictionary(titles ?? [], uniquingKeysWith: { first, _ in first })
        let localizedTitle = titleDict.isEmpty ? nil : Localized(titleDict)

        let dates = root.producedBy?.timespan?.identifiedBy?
            .filter { $0.type == "Name" }
            .compactMap { item -> (Language, String)? in
                guard let content = item.content, !content.isEmpty else { return nil }

                let language: Language
                switch item.detectedLanguage {
                case .dutch:
                    language = .dutch
                case .english:
                    language = .english
                case .other:
                    language = .unknown
                }

                return (language, content)
            }

        let dateDict = Dictionary(dates ?? [], uniquingKeysWith: { first, _ in first })
        let localizedDate = dateDict.isEmpty ? nil : Localized(dateDict)

        return .success(LocalizedPiece(id: root.id, title: localizedTitle, date: localizedDate))
    }
}
