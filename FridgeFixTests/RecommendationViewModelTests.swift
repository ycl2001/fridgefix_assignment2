//
//  RecommendationViewModelTests.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 14/9/2026.
//

import Testing
@testable import FridgeFix

@MainActor
struct RecommendationViewModelTests {

    @Test
    func filterFailureShowsPracticalRecoveryGuidance() {
        let viewModel = RecommendationsViewModel(
            recommendationUseCase: GenerateContextAwareRecommendationsUseCase(
                recipeRepository: LocalRecipeRepository(),
                pantryRepository: LocalPantryRepository()
            )
        )

        viewModel.generateRecommendations(
            for: CookingContext(
                maximumCookingTime: .fifteenMinutes,
                maximumDifficulty: .moderate,
                preferredCuisines: [.asian],
                preferredTastes: [.savoury],
                dietaryRestrictions: [],
                prioritisesExpiringIngredients: true
            )
        )

        #expect(viewModel.errorMessage == """
        Your cooking filters ruled out the available meals.
        Relax your time, difficulty, cuisine, taste, or dietary preferences.
        """)
        #expect(viewModel.recoveryActions == [
            "Relax cuisine or taste preferences",
            "Increase available cooking time or difficulty",
            "Review dietary restrictions"
        ])
    }

    @Test
    func missingPantryMatchShowsIngredientRecoveryGuidance() {
        let recipe = Recipe(
            id: RecipeID(rawValue: "spinach-rice"),
            name: "Spinach Rice",
            cuisine: .asian,
            tastePreferences: [.savoury],
            dietaryLabels: [.vegetarian, .vegan],
            totalCookingTimeInMinutes: 20,
            difficulty: .easy,
            ingredientRequirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Spinach",
                    isEssential: true,
                    substitutionCategory: .leafyGreen
                )
            ],
            nutritionBalance: .balanced,
            instructions: ["Cook and serve."]
        )
        let viewModel = RecommendationsViewModel(
            recommendationUseCase: GenerateContextAwareRecommendationsUseCase(
                recipeRepository: LocalRecipeRepository(recipes: [recipe]),
                pantryRepository: LocalPantryRepository(
                    ingredients: [
                        PantryIngredient(
                            id: IngredientID(rawValue: "rice"),
                            name: "Rice",
                            substitutionCategory: .grain,
                            expiresAt: nil
                        )
                    ]
                )
            )
        )

        viewModel.generateRecommendations(
            for: CookingContext(
                maximumCookingTime: .thirtyMinutes,
                maximumDifficulty: .moderate,
                preferredCuisines: [.asian],
                preferredTastes: [.savoury],
                dietaryRestrictions: [],
                prioritisesExpiringIngredients: true
            )
        )

        #expect(viewModel.errorMessage == """
        No realistic meals match your pantry right now.
        Add more pantry ingredients or allow meals that need one or two additions.
        """)
        #expect(viewModel.recoveryActions == [
            "Add more pantry ingredients",
            "Allow meals that need one or two additions"
        ])
    }
}
