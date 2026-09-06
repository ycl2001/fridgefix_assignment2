//
//  DomainIdentifiers.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Identifies a specific ingredient in the household pantry.
struct IngredientID: Hashable, Codable, Identifiable {
    let rawValue: String

    var id: String {
        rawValue
    }
}
