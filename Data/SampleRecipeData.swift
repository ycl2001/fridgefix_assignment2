//
//  SampleRecipeData.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Provides the small curated recipe catalogue used by the FridgeFix MVP.
///
/// These recipes are intentionally local and controlled so the recommendation
/// rules can be demonstrated and tested without a backend or internet service.
enum SampleRecipeData {

    static let recipes: [Recipe] = [
        Recipe(
            id: RecipeID(rawValue: "chicken-spinach-rice-bowl"),
            name: "Chicken Spinach Rice Bowl",
            cuisine: .asian,
            tastePreferences: [.savoury],
            dietaryLabels: [.dairyFree, .glutenFree, .nutFree],
            totalCookingTimeInMinutes: 20,
            difficulty: .easy,
            ingredientRequirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Chicken",
                    isEssential: true,
                    substitutionCategory: .protein
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Rice",
                    isEssential: true,
                    substitutionCategory: .grain
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Spinach",
                    isEssential: true,
                    substitutionCategory: .leafyGreen
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Garlic",
                    isEssential: true,
                    substitutionCategory: .aromatic
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Spring Onion",
                    isEssential: false,
                    substitutionCategory: .aromatic
                )
            ],
            nutritionBalance: .balanced,
            instructions: [
                "Cook the rice.",
                "Cook the chicken with garlic.",
                "Add the spinach and serve over rice."
            ]
        ),

        Recipe(
            id: RecipeID(rawValue: "vegetable-pasta"),
            name: "Simple Vegetable Pasta",
            cuisine: .italian,
            tastePreferences: [.fresh, .savoury],
            dietaryLabels: [.vegetarian],
            totalCookingTimeInMinutes: 30,
            difficulty: .easy,
            ingredientRequirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Pasta",
                    isEssential: true,
                    substitutionCategory: .grain
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Tomato",
                    isEssential: true,
                    substitutionCategory: nil
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Garlic",
                    isEssential: false,
                    substitutionCategory: .aromatic
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Spinach",
                    isEssential: false,
                    substitutionCategory: .leafyGreen
                )
            ],
            nutritionBalance: .partlyBalanced,
            instructions: [
                "Boil the pasta.",
                "Cook the tomato and garlic.",
                "Combine the pasta with the sauce and vegetables."
            ]
        ),

        Recipe(
            id: RecipeID(rawValue: "tofu-fried-rice"),
            name: "Tofu Fried Rice",
            cuisine: .asian,
            tastePreferences: [.savoury, .hearty],
            dietaryLabels: [
                .vegetarian,
                .vegan,
                .dairyFree,
                .nutFree
            ],
            totalCookingTimeInMinutes: 25,
            difficulty: .moderate,
            ingredientRequirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Tofu",
                    isEssential: true,
                    substitutionCategory: .protein
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Rice",
                    isEssential: true,
                    substitutionCategory: .grain
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Carrot",
                    isEssential: false,
                    substitutionCategory: nil
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Garlic",
                    isEssential: true,
                    substitutionCategory: .aromatic
                )
            ],
            nutritionBalance: .balanced,
            instructions: [
                "Cook the tofu until lightly browned.",
                "Stir-fry the garlic and vegetables.",
                "Add the rice and tofu, then combine."
            ]
        )
    ]
}
