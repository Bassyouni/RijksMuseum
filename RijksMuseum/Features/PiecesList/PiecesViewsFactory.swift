//
//  PiecesViewsFactoryProtocol.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import UIKit

protocol PiecesViewsFactory {
    func makePiecesListView(coordinateToDetails: @escaping (Piece) -> Void) -> UIViewController
    func makePiecesDetailsView(piece: Piece) -> UIViewController
}