//
//  LocalRepositoryTests.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation
import Testing
@testable import FridgeFix

struct LocalRepositoryTests {

    @Test
    func localRecipeRepositoryProvidesCuratedRecipes() throws {
        let repository = LocalRecipeRepository()

        let recipes = try repository.fetchRecipes()

        #expect(!recipes.isEmpty)
        #expect(
            recipes.contains {
                $0.name == "Chicken Spinach Rice Bowl"
            }
        )
    }

    @Test
    func localPantryRepositoryProvidesIngredients() throws {
        let repository = LocalPantryRepository()

        let ingredients = try repository.fetchPantryIngredients()

        #expect(!ingredients.isEmpty)
        #expect(
            ingredients.contains {
                $0.name == "Spinach"
            }
        )
    }

    @Test
    func localPantryContainsAnIngredientExpiringSoon() throws {
        let repository = LocalPantryRepository()

        let ingredients = try repository.fetchPantryIngredients()

        #expect(
            ingredients.contains {
                $0.name == "Spinach" &&
                $0.isExpiringSoon
            }
        )
    }

    @Test
    func addingIngredientStoresItInLocalPantry() throws {
        let repository = LocalPantryRepository(ingredients: [])
        let ingredient = makeIngredient(name: "Eggs")

        try repository.addPantryIngredient(ingredient)

        let ingredients = try repository.fetchPantryIngredients()

        #expect(ingredients == [ingredient])
    }

    @Test
    func addingDuplicateIngredientProducesDomainError() throws {
        let repository = LocalPantryRepository(
            ingredients: [
                makeIngredient(name: "Eggs")
            ]
        )

        #expect(
            throws: PantryRepositoryError.ingredientAlreadyExists("eggs")
        ) {
            try repository.addPantryIngredient(
                makeIngredient(name: "eggs")
            )
        }
    }

    @Test
    func removingExistingIngredientUpdatesLocalPantry() throws {
        let ingredient = makeIngredient(name: "Eggs")
        let repository = LocalPantryRepository(ingredients: [ingredient])

        try repository.removePantryIngredient(id: ingredient.id)

        let ingredients = try repository.fetchPantryIngredients()

        #expect(ingredients.isEmpty)
    }

    @Test
    func updatingExpiryDateChangesExistingIngredient() throws {
        let ingredient = makeIngredient(name: "Eggs")
        let repository = LocalPantryRepository(ingredients: [ingredient])
        let expiryDate = Date(timeIntervalSince1970: 1_800_000_000)

        try repository.updateExpiryDate(
            for: ingredient.id,
            expiresAt: expiryDate
        )

        let updatedIngredient = try #require(
            repository.fetchPantryIngredients().first
        )

        #expect(updatedIngredient.expiresAt == expiryDate)
    }

    @Test
    func localPantryIdentifiesIngredientsExpiringWithinTwoDays() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let expiringIngredient = makeIngredient(
            name: "Spinach",
            expiresAt: Calendar.current.date(
                byAdding: .day,
                value: 2,
                to: date
            )
        )
        let laterIngredient = makeIngredient(
            name: "Tofu",
            expiresAt: Calendar.current.date(
                byAdding: .day,
                value: 3,
                to: date
            )
        )
        let repository = LocalPantryRepository(
            ingredients: [
                expiringIngredient,
                laterIngredient
            ]
        )

        let expiringSoon = try repository.fetchIngredientsExpiringSoon(
            on: date
        )

        #expect(expiringSoon == [expiringIngredient])
    }

    private func makeIngredient(
        name: String,
        category: IngredientSubstitutionCategory = .protein,
        expiresAt: Date? = nil
    ) -> PantryIngredient {
        PantryIngredient(
            id: IngredientID(rawValue: name.lowercased()),
            name: name,
            substitutionCategory: category,
            expiresAt: expiresAt
        )
    }
}
