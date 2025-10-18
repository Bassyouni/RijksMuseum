//
//  PieceDetailsMapper.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 18/10/2025.
//

import Foundation

final class PieceDetailsMapper {

    func map(data: Data) -> Result<(piece: LocalizedPiece, visualItemURL: URL?), RemoteMuseumPiecesFetcher.Error> {
        guard let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
        }

        let localizedTitle = extractLocalized(from: root.identifiedBy, ofType: "Name")
        let localizedDate = extractLocalized(from: root.producedBy?.timespan?.identifiedBy, ofType: "Name")
        let localizedCreator = extractLocalized(from: root.producedBy?.referredToBy, ofType: "LinguisticObject")
        let visualItemURL = extractVisualItemURL(from: root)

        let piece = LocalizedPiece(
            id: root.id,
            title: localizedTitle,
            date: localizedDate,
            creator: localizedCreator,
            imageURL: nil
        )

        return .success((piece: piece, visualItemURL: visualItemURL))
    }

    func mapVisualItem(data: Data) -> URL? {
        guard let visualItem = try? JSONDecoder().decode(VisualItem.self, from: data),
              let digitalRef = visualItem.digitallyShownBy?.first,
              let url = URL(string: digitalRef.id) else {
            return nil
        }
        return url
    }

    func mapDigitalObject(data: Data) -> URL? {
        guard let digitalObject = try? JSONDecoder().decode(DigitalObject.self, from: data),
              let iiifURLString = digitalObject.accessPoint?.first?.id,
              let iiifURL = URL(string: iiifURLString) else {
            return nil
        }
        return iiifURL
    }
    
    private func extractVisualItemURL(from root: Root) -> URL? {
        guard let visualRef = root.shows?.first(where: { $0.type == "VisualItem" }),
              let url = URL(string: visualRef.id) else {
            return nil
        }
        return url
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

private extension PieceDetailsMapper {
    struct Reference: Codable {
        let id: String
        let type: String?
    }

    struct Root: Codable, Identifiable {
        let id: String
        let identifiedBy: [LocalizedContent]?
        let producedBy: ProducedBy?
        let shows: [Reference]?

        enum CodingKeys: String, CodingKey {
            case id
            case shows
            case identifiedBy = "identified_by"
            case producedBy = "produced_by"
        }
    }

    struct VisualItem: Codable {
        let digitallyShownBy: [Reference]?

        enum CodingKeys: String, CodingKey {
            case digitallyShownBy = "digitally_shown_by"
        }
    }

    struct DigitalObject: Codable {
        let accessPoint: [Reference]?

        enum CodingKeys: String, CodingKey {
            case accessPoint = "access_point"
        }
    }

    struct ProducedBy: Codable {
        let timespan: Timespan?
        let referredToBy: [LocalizedContent]?
        
        enum CodingKeys: String, CodingKey {
            case timespan
            case referredToBy = "referred_to_by"
        }
    }
    
    struct Timespan: Codable {
        let identifiedBy: [LocalizedContent]?
        
        enum CodingKeys: String, CodingKey {
            case identifiedBy = "identified_by"
        }
    }
    
    struct LocalizedContent: Codable {
        let type: String
        let content: String?
        let language: [Reference]?
        
        var detectedLanguage: LanguageDTO {
            guard let code = language?.first?.id else { return .other }
            
            return LanguageDTO.from(code: code)
        }
    }
    
    enum LanguageDTO: String, CaseIterable {
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
}
