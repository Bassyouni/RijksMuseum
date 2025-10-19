//
//  SceneDelegate.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let url = URL(string: "https://data.rijksmuseum.nl/search/collection")!
        let client = URLSessionHTTPClient()
        let loader = RemoteMuseumPiecesLoader(url: url, httpClient: client)
        let paginator = RemoteMuseumPiecesPaginator(loader: loader, languagePolicy: LanguageResolutionPolicy())
        let viewModel = PiecesListViewModel(paginator: paginator, coordinateToDetails: { _ in })
        let piecesListViewController = PiecesListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: piecesListViewController)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}











































