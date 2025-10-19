//
//  ViewState.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

enum ViewState: Equatable {
    case idle
    case loading
    case loaded([Piece])
    case error(String)
}
