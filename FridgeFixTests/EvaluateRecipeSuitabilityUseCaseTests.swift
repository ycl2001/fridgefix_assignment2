//
//  EvaluateRecipeSuitabilityUseCaseTests.swift.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Testing
@testable import FridgeFix

struct EvaluateRecipeSuitabilityUseCaseTests {

    private let useCase = EvaluateRecipeSuitabilityUseCase()

    @Test
    func recipeIsReadyToCookWhenAllEssentialIngredientsAreAvailable() {
        let recipe = makeRecipe(
            requirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Rice",
                    isEssential: true,
                    substitutionCategory: .grain
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Spinach",
                    isEssential: true,
                    substitutionCategory: .leafyGreen
                )
            ]
        )

        let pantry = [
            makePantryIngredient(
                name: "Rice",
                category: .grain
            ),
            makePantryIngredient(
                name: "Spinach",
                category: .leafyGreen
            )
        ]

        let result = useCase.execute(
            recipe: recipe,
            pantry: pantry,
            context: makeContext()
        )

        guard case .suitable(let suitability) = result else {
            Issue.record("Expected the recipe to be suitable.")
            return
        }

        #expect(suitability.readiness == .readyToCook)
        #expect(suitability.pantryMatchPercentage == 100)
    }

    @Test
    func dietaryRestrictionConflictExcludesRecipe() {
        let recipe = makeRecipe(
            dietaryLabels: [.vegetarian]
        )

        let result = useCase.execute(
            recipe: recipe,
            pantry: [],
            context: makeContext(
                dietaryRestrictions: [.vegan]
            )
        )

        #expect(
            result == .excluded(.dietaryRestrictionConflict)
        )
    }

    @Test
    func recipeExceedingTimeLimitIsExcluded() {
        let recipe = makeRecipe(
            cookingTime: 45
        )

        let result = useCase.execute(
            recipe: recipe,
            pantry: [],
            context: makeContext(
                maximumCookingTime: .thirtyMinutes
            )
        )

        #expect(
            result == .excluded(.cookingTimeExceedsLimit)
        )
    }

    @Test
    func recipeAboveMaximumDifficultyIsExcluded() {
        let recipe = makeRecipe(
            difficulty: .challenging
        )

        let result = useCase.execute(
            recipe: recipe,
            pantry: [],
            context: makeContext(
                maximumDifficulty: .moderate
            )
        )

        #expect(
            result == .excluded(.difficultyExceedsLimit)
        )
    }

    @Test
    func minorMissingIngredientWithSubstitutionProducesAlmostReady() {
        let recipe = makeRecipe(
            requirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Spring Onion",
                    isEssential: false,
                    substitutionCategory: .aromatic
                )
            ]
        )

        let pantry = [
            makePantryIngredient(
                name: "Garlic",
                category: .aromatic
            )
        ]

        let result = useCase.execute(
            recipe: recipe,
            pantry: pantry,
            context: makeContext()
        )

        guard case .suitable(let suitability) = result else {
            Issue.record("Expected the recipe to be suitable.")
            return
        }

        #expect(suitability.readiness == .almostReady)
        #expect(suitability.substitutions.count == 1)
    }

    @Test
    func moreThanTwoMissingIngredientsExcludesRecipe() {
        let recipe = makeRecipe(
            requirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Rice",
                    isEssential: false,
                    substitutionCategory: nil
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Carrot",
                    isEssential: false,
                    substitutionCategory: nil
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Mushroom",
                    isEssential: false,
                    substitutionCategory: nil
                )
            ]
        )

        let result = useCase.execute(
            recipe: recipe,
            pantry: [],
            context: makeContext()
        )

        #expect(
            result == .excluded(.requiresMoreThanTwoIngredients)
        )
    }

    private func makeRecipe(
        cookingTime: Int = 20,
        difficulty: CookingDifficulty = .easy,
        dietaryLabels: Set<DietaryRestriction> = [
            .vegetarian,
            .vegan,
            .dairyFree,
            .glutenFree,
            .nutFree
        ],
        requirements: [RecipeIngredientRequirement] = []
    ) -> Recipe {
        Recipe(
            id: RecipeID(rawValue: "test-recipe"),
            name: "Test Meal",
            cuisine: .asian,
            tastePreferences: [.savoury],
            dietaryLabels: dietaryLabels,
            totalCookingTimeInMinutes: cookingTime,
            difficulty: difficulty,
            ingredientRequirements: requirements,
            nutritionBalance: .balanced,
            instructions: ["Prepare the meal."]
        )
    }

    private func makePantryIngredient(
        name: String,
        category: IngredientSubstitutionCategory
    ) -> PantryIngredient {
        PantryIngredient(
            id: IngredientID(rawValue: name.lowercased()),
            name: name,
            substitutionCategory: category,
            expiresAt: nil
        )
    }

    private func makeContext(
        maximumCookingTime: CookingTimeLimit = .thirtyMinutes,
        maximumDifficulty: CookingDifficulty = .moderate,
        dietaryRestrictions: Set<DietaryRestriction> = [],
        prioritisesExpiringIngredients: Bool = true
    ) -> CookingContext {
        CookingContext(
            maximumCookingTime: maximumCookingTime,
            maximumDifficulty: maximumDifficulty,
            preferredCuisines: [.asian],
            preferredTastes: [.savoury],
            dietaryRestrictions: dietaryRestrictions,
            prioritisesExpiringIngredients: prioritisesExpiringIngredients
        )
    }
}
