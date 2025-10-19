//
//  ResultExtenstions.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import Foundation

extension Result where Failure == Error {
    static func fail() -> Self {
        .failure(anyError)
    }
}
