//
//  PantryRepository.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Provides FridgeFix with the ingredients currently available in the pantry.
protocol PantryRepository {
    func fetchPantryIngredients() throws -> [PantryIngredient]
}

/// Describes a domain failure when FridgeFix cannot obtain pantry information.
enum PantryRepositoryError: Error {
    case pantryInformationUnavailable
}
