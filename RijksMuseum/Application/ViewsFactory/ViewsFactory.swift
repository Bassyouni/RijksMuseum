//
//  PiecesViewsFactory.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import UIKit
import SwiftUI

@MainActor
final class ViewsFactory: PiecesViewsFactory {
    
    private let imageResizer = IIIFImageResizer()
    
    func makePiecesListView(coordinateToDetails: @escaping (Piece) -> Void) -> UIViewController {
        let url = URL(string: "https://data.rijksmuseum.nl/search/collection")!
        let client = URLSessionHTTPClient()
        let loader = RemoteMuseumPiecesLoader(url: url, httpClient: client)
        let paginator = RemoteMuseumPiecesPaginator(loader: loader, languagePolicy: LanguageResolutionPolicy())
        
        let viewModel = PiecesListViewModel(
            paginator: paginator,
            coordinateToDetails: coordinateToDetails
        )
        
        return PiecesListViewController(viewModel: viewModel, imageResizer: imageResizer)
    }
    
    func makePiecesDetailsView(piece: Piece) -> UIViewController {
        let view = PiecesDetailsView(piece: piece, imageResizer: imageResizer)
        return UIHostingController(rootView: view)
    }
}
