//
//  PiecesListCoordinator.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import UIKit
import SwiftUI

@MainActor
final class PiecesListCoordinator {
    
    private let navigationController: UINavigationController
    private let factory: PiecesViewsFactory
    
    init(navigationController: UINavigationController, factory: PiecesViewsFactory) {
        self.navigationController = navigationController
        self.factory = factory
    }
    
    func start() {
        let viewController = factory.makePiecesListView { [weak self] piece in
            self?.navigateToDetails(piece: piece)
        }
        navigationController.pushViewController(viewController, animated: false)
    }
    
    private func navigateToDetails(piece: Piece) {
        let viewController = factory.makePiecesDetailsView(piece: piece)
        navigationController.pushViewController(viewController, animated: true)
    }
}
