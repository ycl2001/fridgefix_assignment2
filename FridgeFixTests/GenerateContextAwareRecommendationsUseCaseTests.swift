//
//  GenerateContextAwareRecommendationsUseCaseTests.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Testing
@testable import FridgeFix

struct GenerateContextAwareRecommendationsUseCaseTests {

    @Test
    func recommendationsContainOnlyRecipesThatMeetUserConstraints() throws {
        let useCase = GenerateContextAwareRecommendationsUseCase(
            recipeRepository: LocalRecipeRepository(),
            pantryRepository: LocalPantryRepository()
        )

        let recommendations = try useCase.execute(
            context: makeContext()
        )

        #expect(!recommendations.isEmpty)

        #expect(
            recommendations.allSatisfy {
                $0.suitability.recipe.totalCookingTimeInMinutes <= 30
            }
        )

        #expect(
            recommendations.allSatisfy {
                $0.suitability.recipe.difficulty <= .moderate
            }
        )
    }

    @Test
    func expiringIngredientCanPromoteAlmostReadyRecipe() throws {
        let useCase = GenerateContextAwareRecommendationsUseCase(
            recipeRepository: LocalRecipeRepository(),
            pantryRepository: LocalPantryRepository()
        )

        let recommendations = try useCase.execute(
            context: makeContext(
                prioritisesExpiringIngredients: true
            )
        )

        let firstRecommendation = try #require(
            recommendations.first
        )

        #expect(
            firstRecommendation.recipe.name ==
                "Chicken Spinach Rice Bowl"
        )

        #expect(
            firstRecommendation.suitability.usesUrgentIngredient
        )
    }

    @Test
    func noRecipesMeetTimeLimitProducesDomainSpecificFailure() {
        let useCase = GenerateContextAwareRecommendationsUseCase(
            recipeRepository: LocalRecipeRepository(),
            pantryRepository: LocalPantryRepository()
        )

        #expect(throws: RecommendationGenerationError.self) {
            _ = try useCase.execute(
                context: makeContext(
                    maximumCookingTime: .fifteenMinutes
                )
            )
        }
    }

    private func makeContext(
        maximumCookingTime: CookingTimeLimit = .thirtyMinutes,
        maximumDifficulty: CookingDifficulty = .moderate,
        prioritisesExpiringIngredients: Bool = true
    ) -> CookingContext {
        CookingContext(
            maximumCookingTime: maximumCookingTime,
            maximumDifficulty: maximumDifficulty,
            preferredCuisines: [.asian],
            preferredTastes: [.savoury],
            dietaryRestrictions: [],
            prioritisesExpiringIngredients: prioritisesExpiringIngredients
        )
    }
}
