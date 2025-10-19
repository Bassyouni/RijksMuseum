//
//  SceneDelegate.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        window.rootViewController = UINavigationController(rootViewController: PiecesListViewController())
        window.makeKeyAndVisible()
    }
}











































