//
//  SampleIngredientCatalogue.swift
//  FridgeFix
//
//  Created by Codex on 8/9/2026.
//

import Foundation

/// A local pantry ingredient option the user can add to their own pantry.
struct PantryIngredientOption: Identifiable, Equatable, Hashable {
    let name: String
    let category: IngredientSubstitutionCategory
    let isCommonlyAdded: Bool

    var id: String {
        name
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "-",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

/// Provides the local ingredient catalogue used by the pantry add flow.
enum SampleIngredientCatalogue {

    static let ingredients: [PantryIngredientOption] = [
        PantryIngredientOption(
            name: "Spinach",
            category: .leafyGreen,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Tomato",
            category: .leafyGreen,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Lettuce",
            category: .leafyGreen,
            isCommonlyAdded: false
        ),
        PantryIngredientOption(
            name: "Carrot",
            category: .leafyGreen,
            isCommonlyAdded: false
        ),
        PantryIngredientOption(
            name: "Chicken",
            category: .protein,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Tofu",
            category: .protein,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Eggs",
            category: .protein,
            isCommonlyAdded: false
        ),
        PantryIngredientOption(
            name: "Beans",
            category: .protein,
            isCommonlyAdded: false
        ),
        PantryIngredientOption(
            name: "Rice",
            category: .grain,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Pasta",
            category: .grain,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Noodles",
            category: .grain,
            isCommonlyAdded: false
        ),
        PantryIngredientOption(
            name: "Garlic",
            category: .aromatic,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Onion",
            category: .aromatic,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Spring Onion",
            category: .aromatic,
            isCommonlyAdded: false
        ),
        PantryIngredientOption(
            name: "Olive Oil",
            category: .cookingOil,
            isCommonlyAdded: true
        ),
        PantryIngredientOption(
            name: "Vegetable Oil",
            category: .cookingOil,
            isCommonlyAdded: false
        )
    ]
}
