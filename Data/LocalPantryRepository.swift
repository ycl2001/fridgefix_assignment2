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
final class LocalPantryRepository: PantryRepository {

    /// Shared in-memory pantry used by the app's screens during the MVP session.
    static let shared = LocalPantryRepository()

    private var ingredients: [PantryIngredient]
    private let pantryIsAvailable: Bool

    init(
        ingredients: [PantryIngredient] = LocalPantryRepository.sampleIngredients,
        pantryIsAvailable: Bool = true
    ) {
        self.ingredients = ingredients
        self.pantryIsAvailable = pantryIsAvailable
    }

    func fetchPantryIngredients() throws -> [PantryIngredient] {
        guard pantryIsAvailable else {
            throw PantryRepositoryError.pantryInformationUnavailable
        }

        return ingredients
    }

    func fetchIngredientsExpiringSoon(
        on date: Date = Date()
    ) throws -> [PantryIngredient] {
        try fetchPantryIngredients()
            .filter {
                $0.isExpiringSoon(on: date)
            }
    }

    func addPantryIngredient(_ ingredient: PantryIngredient) throws {
        guard pantryIsAvailable else {
            throw PantryRepositoryError.pantryInformationUnavailable
        }

        let alreadyExists = ingredients.contains {
            $0.id == ingredient.id ||
            $0.name.caseInsensitiveCompare(ingredient.name) == .orderedSame
        }

        guard !alreadyExists else {
            throw PantryRepositoryError.ingredientAlreadyExists(
                ingredient.name
            )
        }

        ingredients.append(ingredient)
    }

    func removePantryIngredient(id: IngredientID) throws {
        guard pantryIsAvailable else {
            throw PantryRepositoryError.pantryInformationUnavailable
        }

        guard let index = ingredients.firstIndex(where: { $0.id == id }) else {
            throw PantryRepositoryError.ingredientNotFound(id)
        }

        ingredients.remove(at: index)
    }

    func updateExpiryDate(
        for id: IngredientID,
        expiresAt: Date?
    ) throws {
        guard pantryIsAvailable else {
            throw PantryRepositoryError.pantryInformationUnavailable
        }

        guard let index = ingredients.firstIndex(where: { $0.id == id }) else {
            throw PantryRepositoryError.ingredientNotFound(id)
        }

        ingredients[index].expiresAt = expiresAt
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
