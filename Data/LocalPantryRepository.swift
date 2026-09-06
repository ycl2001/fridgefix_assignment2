//
//  LocalPantryRepository.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Provides the MVP with a local set of pantry ingredients.
///
/// The sample pantry allows the recommendation workflow to be tested without
/// a database or network connection.
struct LocalPantryRepository: PantryRepository {

    private let ingredients: [PantryIngredient]

    init(
        ingredients: [PantryIngredient] = LocalPantryRepository.sampleIngredients
    ) {
        self.ingredients = ingredients
    }

    func fetchPantryIngredients() throws -> [PantryIngredient] {
        guard !ingredients.isEmpty else {
            throw PantryRepositoryError.pantryInformationUnavailable
        }

        return ingredients
    }

    private static let sampleIngredients: [PantryIngredient] = [
        PantryIngredient(
            id: IngredientID(rawValue: "chicken"),
            name: "Chicken",
            substitutionCategory: .protein,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 3)
        ),
        PantryIngredient(
            id: IngredientID(rawValue: "rice"),
            name: "Rice",
            substitutionCategory: .grain,
            expiresAt: nil
        ),
        PantryIngredient(
            id: IngredientID(rawValue: "spinach"),
            name: "Spinach",
            substitutionCategory: .leafyGreen,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24)
        ),
        PantryIngredient(
            id: IngredientID(rawValue: "garlic"),
            name: "Garlic",
            substitutionCategory: .aromatic,
            expiresAt: nil
        ),
        PantryIngredient(
            id: IngredientID(rawValue: "tofu"),
            name: "Tofu",
            substitutionCategory: .protein,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 4)
        )
    ]
}
