//
//  RecommendationViewModel.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation
import Combine

/// Provides ranked meal recommendations and recommendation state to SwiftUI.
@MainActor
final class RecommendationsViewModel: ObservableObject {

    @Published private(set) var recommendations: [RecipeRecommendation] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    @Published private(set) var currentContext: CookingContext?
    @Published var session = RecommendationSession()

    private let recommendationUseCase:
        GenerateContextAwareRecommendationsUseCase

    init(
        recommendationUseCase:
            GenerateContextAwareRecommendationsUseCase =
            GenerateContextAwareRecommendationsUseCase(
                recipeRepository: LocalRecipeRepository(),
                pantryRepository: LocalPantryRepository.shared
            )
    ) {
        self.recommendationUseCase = recommendationUseCase
    }

    /// Generates recommendations for the user's current cooking context.
    func generateRecommendations(
        for context: CookingContext
    ) {
        isLoading = true
        errorMessage = nil
        currentContext = context

        do {
            recommendations = try recommendationUseCase.execute(
                context: context,
                session: session
            )
        } catch RecommendationGenerationError.pantryNeedsIngredients {
            recommendations = []
            errorMessage = """
            Your pantry is empty.
            Add ingredients before looking for meals.
            """
        } catch RecommendationGenerationError.pantryInformationUnavailable {
            recommendations = []
            errorMessage = """
            FridgeFix could not load your pantry.
            Please try again.
            """
        } catch RecommendationGenerationError.recipeCatalogueUnavailable {
            recommendations = []
            errorMessage = """
            FridgeFix could not load its recipe catalogue.
            Please try again.
            """
        } catch RecommendationGenerationError.noRecipesMeetCookingContext {
            recommendations = []
            errorMessage = """
            No meals match your current cooking situation.
            Try changing your cuisine, taste, time, or difficulty preferences.
            """
        } catch {
            recommendations = []
            errorMessage = """
            FridgeFix could not generate recommendations.
            Please try again.
            """
        }

        isLoading = false
    }

    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }

    /// Regenerates the current meal options using the last cooking context.
    func regenerateCurrentRecommendations() {
        guard let currentContext else {
            return
        }

        generateRecommendations(for: currentContext)
    }
}
