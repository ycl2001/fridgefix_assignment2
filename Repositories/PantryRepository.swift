//
//  PantryRepository.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Provides FridgeFix with the ingredients currently available in the pantry.
protocol PantryRepository {
    /// Returns every ingredient currently recorded in the pantry.
    func fetchPantryIngredients() throws -> [PantryIngredient]

    /// Returns ingredients expiring today or within the next two days.
    func fetchIngredientsExpiringSoon(on date: Date) throws -> [PantryIngredient]

    /// Adds a new ingredient to the pantry.
    ///
    /// - Throws: `PantryRepositoryError.ingredientAlreadyExists` when an
    /// ingredient with the same identity or name is already available.
    func addPantryIngredient(_ ingredient: PantryIngredient) throws

    /// Removes an existing ingredient from the pantry.
    ///
    /// - Throws: `PantryRepositoryError.ingredientNotFound` when the ingredient
    /// cannot be found.
    func removePantryIngredient(id: IngredientID) throws

    /// Updates or clears an ingredient's expiry date.
    ///
    /// Pass `nil` to remove an existing expiry date.
    /// - Throws: `PantryRepositoryError.ingredientNotFound` when the ingredient
    /// cannot be found.
    func updateExpiryDate(
        for id: IngredientID,
        expiresAt: Date?
    ) throws
}

/// Describes a domain failure when FridgeFix cannot obtain pantry information.
enum PantryRepositoryError: Error, Equatable, LocalizedError {
    case pantryInformationUnavailable
    case ingredientAlreadyExists(String)
    case ingredientNotFound(IngredientID)

    var errorDescription: String? {
        switch self {
        case .pantryInformationUnavailable:
            return "Pantry information is unavailable."
        case .ingredientAlreadyExists(let ingredientName):
            return "\(ingredientName) is already in your pantry."
        case .ingredientNotFound:
            return "That ingredient could not be found."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .pantryInformationUnavailable:
            return "Try again, or add an ingredient to rebuild your pantry."
        case .ingredientAlreadyExists:
            return "Update the existing ingredient instead of adding a duplicate."
        case .ingredientNotFound:
            return "Refresh your pantry and try again."
        }
    }
}
