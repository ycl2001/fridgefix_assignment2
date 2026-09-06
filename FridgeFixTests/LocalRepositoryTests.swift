//
//  LocalRepositoryTests.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

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
}
