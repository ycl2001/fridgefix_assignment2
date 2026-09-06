//
//  GenerateContextAwareRecommendationsUseCaseTests.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation
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

    @Test
    func skippedRecipesAreExcludedLaterInSameSession() throws {
        let skippedRecipe = makeRecipe(id: "rice-bowl", name: "Rice Bowl")
        let retainedRecipe = makeRecipe(id: "garlic-rice", name: "Garlic Rice")
        let useCase = makeUseCase(
            recipes: [
                skippedRecipe,
                retainedRecipe
            ],
            pantry: [
                makePantryIngredient(name: "Rice"),
                makePantryIngredient(name: "Garlic")
            ]
        )
        var session = RecommendationSession()

        try ApplySessionRecipeFeedbackUseCase().execute(
            feedback: SessionRecipeFeedback(
                recipeID: skippedRecipe.id,
                action: .skipped
            ),
            in: &session
        )

        let recommendations = try useCase.execute(
            context: makeContext(),
            session: session
        )

        #expect(
            recommendations.map(\.recipe.id) == [retainedRecipe.id]
        )
    }

    @Test
    func shoppingFeedbackChangesRecommendationOrder() throws {
        let shoppingRecipe = makeRecipe(
            id: "spinach-rice",
            name: "Spinach Rice",
            requirements: [
                RecipeIngredientRequirement(
                    ingredientName: "Spinach",
                    isEssential: true,
                    substitutionCategory: .leafyGreen
                ),
                RecipeIngredientRequirement(
                    ingredientName: "Tomato",
                    isEssential: false,
                    substitutionCategory: nil
                )
            ]
        )
        let readyRecipe = makeRecipe(id: "plain-rice", name: "Plain Rice")
        let useCase = makeUseCase(
            recipes: [
                shoppingRecipe,
                readyRecipe
            ],
            pantry: [
                makePantryIngredient(
                    name: "Spinach",
                    category: .leafyGreen,
                    expiresAt: Calendar.current.date(
                        byAdding: .day,
                        value: 1,
                        to: Date()
                    )
                ),
                makePantryIngredient(name: "Rice")
            ]
        )
        let context = makeContext(prioritisesExpiringIngredients: true)
        let initialRecommendations = try useCase.execute(
            context: context
        )
        var session = RecommendationSession()

        try ApplySessionRecipeFeedbackUseCase().execute(
            feedback: SessionRecipeFeedback(
                recipeID: shoppingRecipe.id,
                action: .reported(.tooMuchShopping)
            ),
            in: &session
        )

        let adjustedRecommendations = try useCase.execute(
            context: context,
            session: session
        )

        #expect(initialRecommendations.first?.recipe.id == shoppingRecipe.id)
        #expect(adjustedRecommendations.first?.recipe.id == readyRecipe.id)
    }

    @Test
    func tasteFeedbackChangesRecommendationOrder() throws {
        let rejectedRecipe = makeRecipe(
            id: "fresh-pasta",
            name: "Fresh Pasta",
            cuisine: .italian,
            tastePreferences: [.fresh]
        )
        let retainedRecipe = makeRecipe(
            id: "savoury-rice",
            name: "Savoury Rice",
            cuisine: .asian,
            tastePreferences: [.savoury]
        )
        let useCase = makeUseCase(
            recipes: [
                rejectedRecipe,
                retainedRecipe
            ],
            pantry: [
                makePantryIngredient(name: "Rice"),
                makePantryIngredient(name: "Garlic")
            ]
        )
        let context = CookingContext(
            maximumCookingTime: .thirtyMinutes,
            maximumDifficulty: .moderate,
            preferredCuisines: [.italian],
            preferredTastes: [.fresh],
            dietaryRestrictions: [],
            prioritisesExpiringIngredients: false
        )
        let initialRecommendations = try useCase.execute(context: context)
        var session = RecommendationSession()

        try ApplySessionRecipeFeedbackUseCase().execute(
            feedback: SessionRecipeFeedback(
                recipeID: rejectedRecipe.id,
                action: .reported(.notMyTaste)
            ),
            in: &session
        )

        let adjustedRecommendations = try useCase.execute(
            context: context,
            session: session
        )

        #expect(initialRecommendations.first?.recipe.id == rejectedRecipe.id)
        #expect(adjustedRecommendations.first?.recipe.id == retainedRecipe.id)
    }

    @Test
    func feedbackDoesNotOverrideHardConstraints() throws {
        let validRecipe = makeRecipe(id: "valid-rice", name: "Valid Rice")
        let dietaryConflictRecipe = makeRecipe(
            id: "dairy-rice",
            name: "Dairy Rice",
            dietaryLabels: [.vegetarian]
        )
        let slowRecipe = makeRecipe(
            id: "slow-rice",
            name: "Slow Rice",
            cookingTime: 45
        )
        let difficultRecipe = makeRecipe(
            id: "hard-rice",
            name: "Hard Rice",
            difficulty: .challenging
        )
        let useCase = makeUseCase(
            recipes: [
                dietaryConflictRecipe,
                slowRecipe,
                difficultRecipe,
                validRecipe
            ],
            pantry: [
                makePantryIngredient(name: "Rice"),
                makePantryIngredient(name: "Garlic")
            ]
        )
        var session = RecommendationSession()

        for recipe in [
            dietaryConflictRecipe,
            slowRecipe,
            difficultRecipe
        ] {
            try ApplySessionRecipeFeedbackUseCase().execute(
                feedback: SessionRecipeFeedback(
                    recipeID: recipe.id,
                    action: .saved
                ),
                in: &session
            )
        }

        let recommendations = try useCase.execute(
            context: makeContext(
                maximumCookingTime: .thirtyMinutes,
                maximumDifficulty: .moderate,
                dietaryRestrictions: [.vegan]
            ),
            session: session
        )

        #expect(
            recommendations.map(\.recipe.id) == [validRecipe.id]
        )
    }

    @Test
    func feedbackDoesNotPersistAfterSessionEnds() throws {
        let skippedRecipe = makeRecipe(id: "rice-bowl", name: "Rice Bowl")
        let retainedRecipe = makeRecipe(id: "garlic-rice", name: "Garlic Rice")
        let useCase = makeUseCase(
            recipes: [
                skippedRecipe,
                retainedRecipe
            ],
            pantry: [
                makePantryIngredient(name: "Rice"),
                makePantryIngredient(name: "Garlic")
            ]
        )
        var session = RecommendationSession()

        try ApplySessionRecipeFeedbackUseCase().execute(
            feedback: SessionRecipeFeedback(
                recipeID: skippedRecipe.id,
                action: .skipped
            ),
            in: &session
        )

        let activeRecommendations = try useCase.execute(
            context: makeContext(),
            session: session
        )

        session.end()

        let endedRecommendations = try useCase.execute(
            context: makeContext(),
            session: session
        )

        #expect(activeRecommendations.map(\.recipe.id) == [retainedRecipe.id])
        #expect(
            endedRecommendations.map(\.recipe.id) == [
                skippedRecipe.id,
                retainedRecipe.id
            ]
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

    private func makeUseCase(
        recipes: [Recipe],
        pantry: [PantryIngredient]
    ) -> GenerateContextAwareRecommendationsUseCase {
        GenerateContextAwareRecommendationsUseCase(
            recipeRepository: LocalRecipeRepository(recipes: recipes),
            pantryRepository: LocalPantryRepository(ingredients: pantry)
        )
    }

    private func makeRecipe(
        id: String,
        name: String,
        cuisine: Cuisine = .asian,
        tastePreferences: Set<TastePreference> = [.savoury],
        dietaryLabels: Set<DietaryRestriction> = [
            .vegetarian,
            .vegan,
            .dairyFree,
            .glutenFree,
            .nutFree
        ],
        cookingTime: Int = 20,
        difficulty: CookingDifficulty = .easy,
        requirements: [RecipeIngredientRequirement] = [
            RecipeIngredientRequirement(
                ingredientName: "Rice",
                isEssential: true,
                substitutionCategory: .grain
            )
        ]
    ) -> Recipe {
        Recipe(
            id: RecipeID(rawValue: id),
            name: name,
            cuisine: cuisine,
            tastePreferences: tastePreferences,
            dietaryLabels: dietaryLabels,
            totalCookingTimeInMinutes: cookingTime,
            difficulty: difficulty,
            ingredientRequirements: requirements,
            nutritionBalance: .balanced,
            instructions: ["Cook and serve."]
        )
    }

    private func makePantryIngredient(
        name: String,
        category: IngredientSubstitutionCategory = .grain,
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
